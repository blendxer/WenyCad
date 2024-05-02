extends Control

onready var line = $Line2D # edge of select box
onready var pos2d = $Position2D
onready var boxLine = $box
onready var centerPointerIcon = $centerPointer
onready var rotationRing = $centerPointer/rotationRing

var MaxPos:Vector2 = Vector2(-INF,-INF)
var MinPos:Vector2 = Vector2(INF,INF)

var BoxLine_normalColor = Color('97000000')
var BoxLine_transColor = Color(.2,.2,.2,.5)

var MaxPosShifted:Vector2
var MinPosShifted:Vector2
var Edges:Array

# if true there is something selected
var SelectState=false
var MoveCenterState:=false

# cornar
var Cornar_radius:int= 3
var Cornar_res:int = 10
var Cornar_InstArr:Array

var realMaxPos:Vector2
var realMinPos:Vector2

var StartLockVec:Vector2
var EndLockVec:Vector2
var FirstHit=Vector2()
var MoveReferencePnt:Vector2 # also changed form drawingscreen
var LockVec = Vector2()
var MoveShift = Vector2()
var MoveShiftScaled = Vector2()

var InitialLengthFloat:float
var InitialLengthVec:Vector2 # related to free scale 
var MouseCursorShift:Vector2

var InitalAngleVec
var RotatationAngle:float

var tol = 10
var RingRadius = 30

var LastUpdate:=false
var LastScaleValue:Vector2
var LastTransformTime:int 

var TransformState:= false
var AltMode:bool=false

var Pos2dBackupPos:Vector2
var TransformMode

var AngleCounter_storage:float=0
var AngleCounter_refVec:Vector2


func _ready():
	Edges.resize(4)
	# make cornares
	var vecArr:PoolVector2Array=[]
	for j in Cornar_res:
		var angle = 2 * PI * float(j)/(Cornar_res-1)
		var vec = Cornar_radius * Vector2(cos(angle),sin(angle))
		vecArr.append(vec)
	for i in 4:
		var inst = Polygon2D.new()
		add_child(inst)
		Cornar_InstArr.append(inst)
		inst.polygon = vecArr
		inst.hide()
		inst.color = Color(.9,.9,.9,.7)
	
	for i in 32:
		var angle = float(i)/31 * TAU
		var vec= polar2cartesian(RingRadius,angle)
		rotationRing.add_point(vec)


func _input(event):
	if LastUpdate:
		WV.drawingScreen.changePaintState('select')
		LastUpdate = false
		
	if SelectState:
		# live 
		if TransformState:
			liveTrans()
			
		if MoveCenterState:
			pos2d.position = WV.mousePointer / WV.LastScaleBackup
			centerPointerIcon.rect_position = WV.mousePointer
		
		
		if event is InputEventKey:shortCutStates() # for update key states
		

func shortCutStates():
	if !TransformMode:
		if Input.is_action_pressed("shift"):
			return
			
		if Input.is_action_just_pressed('g'):
			Pos2dBackupPos = pos2d.position
			moveTransform()
			
		elif Input.is_action_just_pressed("s"):
			Pos2dBackupPos = pos2d.position
			scaleTransform()
		elif Input.is_action_just_pressed("r"):
			Pos2dBackupPos = pos2d.position
			rotateTransform()
	
		if Input.is_action_just_pressed("x"):
			if !Input.is_action_pressed("ctrl"):
				if WV.drawingScreen.insideField():
					WV.drawingScreen.deleteSelection()
			
	
	AltMode = Input.is_action_pressed("alt")
	liveTrans() # update

func rightFieldbt():
	if !SelectState:return
	WV.drawingScreen.changePaintState('select')
	if TransformState:
		cancelTrans()
		
	elif MoveCenterState:
		pos2d.position = Pos2dBackupPos
		centerPointerIcon.rect_position = Pos2dBackupPos * WV.LastScaleBackup
		MoveCenterState = false

func leftFieldBt():
	if !SelectState:return
	
	if WV.drawingScreen.paintState == 'select':
		# not press shift for multi selection
		# not press alt for deselect
		if !Input.is_action_pressed("shift") and !Input.is_action_pressed("alt"):
			check()
	
func releaseMouseBt():
	if !SelectState:return
	if MoveCenterState:
		WV.drawingScreen.changePaintState('select')
		MoveCenterState = false
	elif TransformState:applyTrans()

func check():
	Pos2dBackupPos = pos2d.position
	if (WV.mousePointer-pos2d.position*WV.LastScaleBackup).length()<tol:
		WV.drawingScreen.changePaintState('transform')
		MoveCenterState = true
	
	# rotation
	elif abs((WV.mousePointer-centerPointerIcon.rect_position).length()-RingRadius)<tol:
		rotateTransform()
	
	else:
		if WV.mousePointer.x > Edges[0].x-tol and WV.mousePointer.x < Edges[2].x+tol:
			StartLockVec.y = int(abs(WV.mousePointer.y-Edges[0].y) < tol) # up
			EndLockVec.y   = int(abs(WV.mousePointer.y-Edges[2].y) < tol) # down
		if WV.mousePointer.y > Edges[0].y-tol and WV.mousePointer.y < Edges[2].y+tol:
			StartLockVec.x = int(abs(WV.mousePointer.x-Edges[0].x) < tol) # left
			EndLockVec.x   = int(abs(WV.mousePointer.x-Edges[2].x) < tol) # right
		
		# move
		if not(EndLockVec.x or EndLockVec.y or StartLockVec.y or StartLockVec.x):
			if Rect2(Edges[0],Edges[2]-Edges[0]).has_point(WV.mousePointer):
				
				# move pos2d to cetner
				if Time.get_ticks_msec()-LastTransformTime<300:
					pos2d.position = ((MinPos+MaxPos)/2)/WV.LastScaleBackup
					centerPointerIcon.rect_position = pos2d.position*WV.LastScaleBackup
					Pos2dBackupPos = pos2d.position
				LastTransformTime = Time.get_ticks_msec()
				moveTransform()
		# scale
		else:
			# move center to opposite side of select box
			if Time.get_ticks_msec()-LastTransformTime<300:
				if   StartLockVec.y: pos2d.position.y = MaxPos.y / WV.LastScaleBackup
				elif EndLockVec.y:   pos2d.position.y = MinPos.y / WV.LastScaleBackup
				if   StartLockVec.x: pos2d.position.x = MaxPos.x / WV.LastScaleBackup
				elif EndLockVec.x:   pos2d.position.x = MinPos.x / WV.LastScaleBackup
				centerPointerIcon.rect_position = pos2d.position * WV.LastScaleBackup
			LastTransformTime = Time.get_ticks_msec()
			
			scaleTransform()
	liveTrans()

func initialTransform():
	boxLine.default_color = BoxLine_transColor
	TransformState = true
	WV.drawingScreen.changePaintState('transform')


func moveTransform():
	MouseCursorShift = WV.mousePointer/WV.LastScaleBackup - pos2d.position
	TransformMode = 'move'
	initialTransform()
	FirstHit = WV.mousePointer / WV.LastScaleBackup
	MoveReferencePnt = FirstHit
	

func scaleTransform():
	InitialLengthVec = WV.mousePointer/WV.LastScaleBackup - pos2d.position
	InitialLengthFloat = InitialLengthVec.length()
	TransformMode = 'scale'
	initialTransform()
	if InitialLengthFloat==0 or !InitialLengthVec.x or !InitialLengthVec.y:
		cancelTrans()
		WV.makeAd('23')

func rotateTransform():
	TransformMode = 'rotate'
	InitalAngleVec = WV.mousePointer-centerPointerIcon.rect_position
	AngleCounterReset(WV.mousePointer-centerPointerIcon.rect_position)
	initialTransform()



func liveTrans():
	if Input.is_action_just_pressed("ui_accept"):
		applyTrans()
		WV.drawingScreen.reset()
	if TransformMode == 'move':
		if KeyboardHandler.state:
			var angle=0
			if WV.drawingScreen.LineALignMode == 'y':
				angle=-PI/2
			MoveShift = KeyboardHandler.number/10 * Vector2(cos(angle),sin(angle))
		else:
			MoveShift = WV.mousePointer/WV.LastScaleBackup - MoveReferencePnt + MouseCursorShift * int(AltMode)
		WV.infoBoard.updateValue('Shift',MoveShift*Vector2(1,-1))
		liveShift(MoveShift)
	
	elif TransformMode == 'rotate':
		AngleCounterUpdate(WV.mousePointer-centerPointerIcon.rect_position)
		if KeyboardHandler.state:
			RotatationAngle = -deg2rad(KeyboardHandler.number/10)
		else:
			RotatationAngle = AngleCounter_storage
#			RotatationAngle = -(WV.mousePointer-centerPointerIcon.rect_position).angle_to(InitalAngleVec)
		WV.infoBoard.updateValue('Angle',rad2deg(-RotatationAngle))
		liveRotate(pos2d.position,RotatationAngle)
		
		
	elif TransformMode == 'scale':
		var newVec = Vector2.ONE 
		var x = StartLockVec.x or EndLockVec.x
		var y = StartLockVec.y or EndLockVec.y
		
		var spVec = Vector2(1,1)
		
		var type = WV.drawingScreen.LineALignMode
		if type == 'x':
			y = 0
			x = 1
		elif type == 'y':
			x = 0
			y = 1
			
		if KeyboardHandler.state:
			var v = KeyboardHandler.number/10
			if v==0: v= .0000001  # for undo
			if   x and !y: newVec.x = v
			elif y and !x: newVec.y = v
			else:          newVec  *= v
			
		else:
			var realMousePos = WV.mousePointer/WV.LastScaleBackup
			var midPnt = (realMinPos+realMaxPos)/2
			if   x and !y: 
				newVec.x = (realMousePos.x-pos2d.position.x)/InitialLengthVec.x
				var value = [realMinPos.x,realMaxPos.x][int(realMousePos.x>midPnt.x)]
				if value != pos2d.position.x:
					spVec.x = (realMousePos-pos2d.position).x/(value-pos2d.position.x)
				
			elif y and !x: 
				newVec.y = (realMousePos.y-pos2d.position.y)/InitialLengthVec.y
				var value = [realMinPos.y,realMaxPos.y][int(realMousePos.y>midPnt.y)]
				if value != pos2d.position.y:
					spVec.y = (realMousePos-pos2d.position).y/(value-pos2d.position.y)
			else:
				if AltMode:
					newVec = (realMousePos-pos2d.position)/InitialLengthVec
					
					var value = [realMinPos.y,realMaxPos.y][int(realMousePos.y>midPnt.y)]
					if value != pos2d.position.y:
						spVec.y = (realMousePos-pos2d.position).y/(value-pos2d.position.y)
					value = [realMinPos.x,realMaxPos.x][int(realMousePos.x>midPnt.x)]
					if value != pos2d.position.x:
						spVec.x = (realMousePos-pos2d.position).x/(value-pos2d.position.x)
				else:
					newVec = (realMousePos-pos2d.position).length()/InitialLengthFloat
					newVec *= Vector2.ONE  # convert float to vector2
					
		if Input.is_action_pressed("ctrl"):
			if spVec.x != 1 or spVec.y !=1:
				newVec = spVec
		LastScaleValue = newVec 
		WV.infoBoard.updateValue('Scale',newVec)
		liveScale(pos2d.position,newVec)

func liveScale(pos,value):
	for obj in CheckIntersection.selectedObjects:
		obj.liveScale(pos,value)
	var vec = pos * WV.LastScaleBackup
	scaleSelectBox(vec,value)

func liveRotate(_pos,_angle):
	for obj in CheckIntersection.selectedObjects:
		obj.liveRotate(_pos,_angle)

func liveShift(_shift):
	for obj in CheckIntersection.selectedObjects:
		obj.shiftObj(_shift)
	centerPointerIcon.rect_position = (pos2d.position+_shift)*WV.LastScaleBackup 
	shiftSelectBox(_shift*WV.LastScaleBackup)

func cancelTrans():
	if TransformMode == 'move':
		for obj in CheckIntersection.selectedObjects:
			obj.finshMove(Vector2())
		MoveShiftScaled = Vector2()
		updateLine()
	
	elif TransformMode == 'scale':
		for obj in CheckIntersection.selectedObjects:
			obj.applyScale(Vector2.ZERO,Vector2.ONE)
		CheckIntersection.updateSelectBox()
		
	elif TransformMode == 'rotate':
		if RotatationAngle != 0:
			for obj in CheckIntersection.selectedObjects:
				obj.applyRotate(pos2d.position,0)
	endTrans()
	pos2d.position = Pos2dBackupPos
	centerPointerIcon.rect_position = pos2d.position*WV.LastScaleBackup 

func applyTrans():
	if TransformMode == 'move':
		if not(MoveShift == Vector2()): # not shifted by 0 
			Undo.addNewChunk('move',[[CheckIntersection.selectedObjects.duplicate(),
			MoveShift]])
			moveObjList(CheckIntersection.selectedObjects,MoveShift)
		
		pos2d.position = Pos2dBackupPos + MoveShift
		centerPointerIcon.rect_position = pos2d.position*WV.LastScaleBackup 
		MoveShiftScaled = Vector2()
		MouseCursorShift = Vector2()
		
	elif TransformMode == 'scale':
		if LastScaleValue.x !=1 or LastScaleValue.y !=1: # not scaled by 1 factor
			Undo.addNewChunk('scale',[CheckIntersection.selectedObjects.duplicate(),
			pos2d.position,LastScaleValue])
			scaleObjList(CheckIntersection.selectedObjects,pos2d.position,LastScaleValue)
			
		StartLockVec = Vector2()
		EndLockVec = Vector2()
		
	elif TransformMode == 'rotate':
		if RotatationAngle != 0:
			rotateObjList(CheckIntersection.selectedObjects,pos2d.position,RotatationAngle)
			Undo.addNewChunk('rotate',[CheckIntersection.selectedObjects.duplicate(),
			pos2d.position,RotatationAngle])
		
	endTrans()
	CheckIntersection.updateSelectBox()

func endTrans():
	KeyboardHandler.reset()
	WV.infoBoard.reset()
	boxLine.default_color = BoxLine_normalColor
	TransformMode = ''
	LastUpdate = true
	TransformState = false
	
# +f undo script
func moveObjList(_objList,_shift):
	for obj in _objList:
		obj.finshMove(_shift)
	updateBoxAfterUndo()
	
# +f undo script
func scaleObjList(_objList,_center,_value):
	for obj in _objList:
		obj.applyScale(_center,_value)
	updateBoxAfterUndo()

func rotateObjList(_objList,_center,_angle):
	for obj in _objList:
		obj.applyRotate(_center,_angle)
	updateBoxAfterUndo()
	

func updateBoxAfterUndo():
	if SelectState:
		CheckIntersection.updateSelectBox()

# -f drawingScreen
func alignLock(_vec):
	LockVec = _vec

# -f checkintersection
func selectedObj(_list):
	for pnt in _list:
		checkBondires(pnt*WV.LastScaleBackup)
	realMinPos = MinPos/WV.LastScaleBackup
	realMaxPos = MaxPos/WV.LastScaleBackup
	addShift()
	updateLine()
	for i in 4:
		Cornar_InstArr[i].show()
	set_process_input(1)
	centerPointerIcon.show()
	SelectState=true
	
# -f checkintersection , organizer
func updateSelectedOrignPnt():
	pos2d.position = (realMinPos+realMaxPos)/2
	centerPointerIcon.rect_position = pos2d.position*WV.LastScaleBackup

func zoomUpdate(_newFactor):
	if SelectState:
		MaxPos = realMaxPos * _newFactor
		MinPos = realMinPos * _newFactor
		addShift()
		updateLine()
		update()
		centerPointerIcon.rect_position = pos2d.position*_newFactor

func reset():
	MaxPos = Vector2(-INF,-INF)
	MinPos = Vector2(INF,INF)

func removeBox():
	SelectState=false
	for i in line.get_point_count():
		line.points[i] = Vector2.ZERO
	boxLine.points[0] = Vector2()
	boxLine.points[1] = Vector2()
	for i in 4:
		Cornar_InstArr[i].hide()
	set_process_input(0)
	centerPointerIcon.hide()

func updateLine():
	Edges[1] = Vector2(MaxPosShifted.x ,MinPosShifted.y)
	Edges[3] = Vector2(MinPosShifted.x ,MaxPosShifted.y)
	Edges[0] = MinPosShifted
	Edges[2] = MaxPosShifted
	
	for i in 4:
		line.points[i] = Edges[i]
		Cornar_InstArr[i].position = Edges[i]
	line.points[4] = Edges[0]
	
	var diffVec = (Edges[2] - Edges[0])/2
	boxLine.points[0] = Edges[0] + Vector2(0,diffVec.y)
	boxLine.points[1] = Edges[2] - Vector2(0,diffVec.y)
	boxLine.width = 2 * abs(diffVec.y)

func shiftSelectBox(_shift):
	for i in 4:
		line.points[i] = Edges[i] + _shift
		Cornar_InstArr[i].position = Edges[i]+_shift
	line.points[4] = Edges[0]+ _shift
	var diffVec = (Edges[2] - Edges[0])/2
	boxLine.points[0] = Edges[0] + Vector2(0,diffVec.y)+_shift
	boxLine.points[1] = Edges[2] - Vector2(0,diffVec.y)+_shift

func scaleSelectBox(_vec,_value):
	var shiftValue = .4*WV.LastScaleBackup*Vector2.ONE
	MinPosShifted = (MinPos-_vec)*_value+_vec - shiftValue
	MaxPosShifted = (MaxPos-_vec)*_value+_vec + shiftValue
	
	Edges[1] = Vector2(MaxPosShifted.x ,MinPosShifted.y)
	Edges[3] = Vector2(MinPosShifted.x ,MaxPosShifted.y)
	Edges[0] = MinPosShifted
	Edges[2] = MaxPosShifted
	
	for i in 4:
		line.points[i] = Edges[i]
		Cornar_InstArr[i].position = Edges[i]
	line.points[4] = Edges[0]
	
	var diffVec = (Edges[2] - Edges[0])/2
	boxLine.points[0] = Edges[0] + Vector2(0,diffVec.y)
	boxLine.points[1] = Edges[2] - Vector2(0,diffVec.y)
	boxLine.width = 2 * abs(diffVec.y)
	
	
func checkBondires(vec):
	if vec.x > MaxPos.x: MaxPos.x = vec.x
	if vec.x < MinPos.x: MinPos.x = vec.x
	if vec.y > MaxPos.y: MaxPos.y = vec.y
	if vec.y < MinPos.y: MinPos.y = vec.y

func addShift():
	MinPosShifted = MinPos - Vector2(50,50)
	MaxPosShifted = MaxPos + Vector2(50,50)

func AngleCounterReset(vec):
	AngleCounter_refVec = vec
	AngleCounter_storage = 0
	AngleCounterUpdate(vec)

func AngleCounterUpdate(vec:Vector2):
	AngleCounter_storage -= vec.angle_to(AngleCounter_refVec)
	AngleCounter_refVec = vec
	if abs(AngleCounter_storage) > 6.28:
		AngleCounter_storage = remainder(AngleCounter_storage , 6.28)

func remainder(num:float ,denum):
	return num-int(num/denum)*denum
	





