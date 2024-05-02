extends Line2D

signal finsh_object
var objectType = 'circle'
var DrawingType = 'caliper'
var objectColor = Color.white
var snapedPoint:Array
var LayerId

var mode = 'drawing'

var circlePos:Vector2
var circleRadius
var circleRes:=32

# show variable
onready var Show_line = $"cut shot/line2D"
onready var linesHolder = $linesHolder


var stateIndex=0

# cut circle

var AngleCounter_storage:float=0
var AngleCounter_refVec:Vector2


# circle live cut 
var operationIndex = 0


var LineSeqmentVisible:Array # contain only visible seqment
var LineSeqmentVisiblBackup:Array # for undo
var ActiveSeqment:Array
var ChoosedLine:Array
var ProjectionPnt:Vector2
var ErasePntTouchEdge:bool
var EraseTouchEdgeList = [false,false]
var CircleBoundary:Array #circle before cut and erase
var ActionsList:Array
var ActionsLisBackup:Array
var LastAppliedColor:Color

var erase_OpIndex=0
var erase_hitAngleList:Array 

onready var lineChooseMark = $"line choose mark"
onready var selectLine = $selectLine

var AngleVecArr:Array

var realCirclePos
var realCircleRadius
var realRect:Rect2

var Weldaan # instance 

func copy():
	var dict = {}
	dict['objectType'] = 'circle'
	dict['DrawingType'] = 'caliper'
	dict['LayerId'] = LayerId
	dict['realRect'] = realRect
	dict['pointsRealPos'] = pointsRealPos
	dict['type'] = DrawingType
	
	dict['snapPnts'] = snapedPoint
	dict['circlePos'] = realCirclePos
	dict['circleRadius'] = realCircleRadius
	dict['lineSeqment'] = LineSeqmentVisible
	dict['ActionsList'] = ActionsList
	dict['circleBoundary'] = CircleBoundary
	return dict
	
func paste(dict):
	if dict['type'] == 'caliper':
		DrawingType = 'caliper'
		objectType = 'circle'
	if dict['type'] == 'bezier':
		objectType = 'bezier'
		DrawingType = 'bezier'
	
	LayerId = dict['LayerId']
	realRect = dict['realRect']
	snapedPoint = dict['snapPnts'].duplicate()
	realCirclePos = dict['circlePos']
	realCircleRadius = dict['circleRadius']
	LineSeqmentVisible = dict['lineSeqment'].duplicate(true)
	CircleBoundary = dict['circleBoundary'].duplicate()
	
	ActionsList = dict['ActionsList'].duplicate(true)
	for i in ActionsList.size():
		ActionsList[i][0] = WV.drawingScreen.IndexSequenceDict[ActionsList[i][0]]
	
	updateAngleVecList()
	WV.allObject.append(self)
	mode = 'finsh'
	resetAllLines()
	reDraw(WV.LastScaleBackup)
	updateRealRect()
	updateCircle()
	var c = LayerManager.LayerPanel.layerIdDict[LayerId].LayerColor
	changeColor(c)
	objectColor = c


# warning-ignore:unused_argument
func input(event):
	if mode == 'setAngles': # initial cutting
		AngleCounterUpdate(WV.mousePointer - circlePos)
		LineSeqmentVisible[0][1] = AngleCounter_storage
		updateAngleVecList()
		updateCircle()
		var dump = -rad2deg(LineSeqmentVisible[0][0]+LineSeqmentVisible[0][1])
		WV.drawingScreen.lastPanel.end.text = str(dump)
		if Input.is_action_just_pressed("alt"):
			Show_line.visible = false
			var dict={}
			dict['radius'] = str(realCircleRadius)
			dict['start']= str(WV.drawingScreen.lastPanel.start.text)
			dict['end']= str(WV.drawingScreen.lastPanel.end.text)
			updateValues(dict)
			
	
	elif mode == 'cut_circle':
		# update cirlce outer point
		# cut by press cut button on the panel of this obj
		# second cut type
		var pos = (WV.mousePointer-circlePos).normalized() * circleRadius + circlePos
		Show_line.points[-1] = pos
		if operationIndex == 0:
			Show_line.points[1] = circlePos
			Show_line.points[0] = pos
			
		# update circle shape
		elif operationIndex == 1:
			AngleCounterUpdate(WV.mousePointer - circlePos)
			LineSeqmentVisible[0][1] = AngleCounter_storage
			updateAngleVecList()
			updateCircle()
			
	elif mode == 'chooseSeqment':
		var seqment = chooseSeqment() 
		if seqment:
			updateLineChooseMark(seqment)
			
		else:
			updateLineChooseMark()
			
	elif mode == 'erase':
		# update pointer position
		updateSelectLine()
		updateProjectionPnt()
		updateCursorPos()
		AngleCounterUpdate(ProjectionPnt)
		
# this func fired from single circle panel
func startCuttingCircle():
	if LineSeqmentVisible.size() !=1:
		WV.makeAd('6')
		return
		
	if typeof(realCircleRadius) == TYPE_VECTOR2:
		WV.makeAd('15')
		return
	
	saveObjVariable()
	
	WV.drawingScreen.changePaintState('object_edit')
	# change the mode to make 'fieldButton' in the current state
	mode = 'cut_circle'
	# restart 'operationIndex'
	operationIndex = 0
	Show_line.visible = true
		

func AngleCounterUpdate(vec:Vector2):
	AngleCounter_storage -= vec.angle_to(AngleCounter_refVec)
	AngleCounter_refVec = vec
	
	# reset the angle diff if it be greater than
	# one full turn in any direction
	if abs(AngleCounter_storage) > 6.28:
		AngleCounter_storage = remainder(AngleCounter_storage , 6.28)

func AngleCounterReset(vec):
	AngleCounter_refVec = vec
	AngleCounter_storage = 0
	AngleCounterUpdate(vec)

func initiateObject():
	var method = WV.drawingScreen.SubtypePanel.method
	var path = 'res://scenes/drawing side/weldaan/circleObject/' + method + '.tscn' 
	Weldaan = load(path).instance()
	Weldaan.Father = self
	add_child(Weldaan)
	updateAngleVecList()
	
func updateValues(dict):
	if mode != 'finsh':
		KeyboardHandler.reset()
		mode = 'manual'
		circleRadius = float(dict['radius']) * WV.scaleFac * 10
		realCircleRadius = circleRadius / WV.LastScaleBackup
		if dict['start'] =='' and dict['end'] == '':
			dict['start']='0'
			dict['end']='360'
			
		var startAngle = deg2rad(360-float(dict['start']))
		var endAngle =   deg2rad(360-float(dict['end']))
		var angleDiff = endAngle - startAngle
		
		LineSeqmentVisible = [[startAngle,angleDiff]]
		updateAngleVecList()
		updateCircle()


func updateAngleVecList():
	AngleVecArr.clear()
	for i in LineSeqmentVisible.size():
		var list = []
		for j in circleRes:
			var angle = (float(j)/(circleRes-1))*LineSeqmentVisible[i][1]+LineSeqmentVisible[i][0]
			list.append(Vector2(cos(angle),sin(angle)))
		AngleVecArr.append(list)
		
func updateCircle():
	for i in LineSeqmentVisible.size():
		for j in circleRes:
			linesArr[i].points[j] = circleRadius * AngleVecArr[i][j] + circlePos

func fieldButton():
	if mode == 'drawing':
		Weldaan.fieldButton()
	
	elif mode == 'manual':
		finshProcess()
	
	elif mode == 'setAngles':
		LineSeqmentVisible[0][1]= AngleCounter_storage
		updateAngleVecList()
		mode = 'finsh'
		Show_line.visible = false
		finshProcess()
	
	elif mode == 'cut_circle':
		operationIndex +=1
		if operationIndex == 1:
			LineSeqmentVisiblBackup = LineSeqmentVisible.duplicate(true)
			LineSeqmentVisible[0][0] = (WV.mousePointer - circlePos).angle()
			updateAngleVecList()
			var vec = (WV.mousePointer-circlePos).normalized() * circleRadius + circlePos
			Show_line.points[0] = vec
			Show_line.points[1] = circlePos
			Show_line.points[2] = vec
			# initiate angle counter
			AngleCounterReset(WV.mousePointer -  circlePos)
			
		elif operationIndex == 2:
			Undo.addNewChunk('editObj',[self,LineSeqmentVisiblBackup.duplicate(true),1])
			LineSeqmentVisible[0][1]= AngleCounter_storage
			updateAngleVecList()
			updateCircle()
			Show_line.visible = false
			mode = 'finsh'
			WV.drawingScreen.changePaintState('select')
			CircleBoundary = LineSeqmentVisible[0].duplicate(true)
			
			updateSnapPnts()
			updateRealRect()
			updateCircle()
			CheckIntersection.updateSelectBox()
			
	elif mode == 'chooseSeqment':
		var seqment = chooseSeqment() 
		if seqment:
			ChoosedLine = seqment
			lineChooseMark.visible = false
			Show_line.visible = true
			mode = 'erase'
			updateCursorPos()
			hideLineChooseMark()
			updateProjectionPnt()
			
	elif mode == 'erase':
		if erase_OpIndex == 0:
			erase_hitAngleList.append(ProjectionPnt.angle())
			EraseTouchEdgeList[0] = ErasePntTouchEdge
			AngleCounterReset(ProjectionPnt)
			selectLine.visible = true
			
		elif erase_OpIndex == 1:
			erase_hitAngleList.append(AngleCounter_storage)
			EraseTouchEdgeList[1] = ErasePntTouchEdge
			selectLine.visible = false
			resetSelectLine()
			erasingOP()
			updateRealRect()
			CheckIntersection.updateSelectBox()
			
		erase_OpIndex +=1

func cancelEdit():
	undoUpdate(viarableBackup)
	mode = 'finsh'
	Show_line.visible = false
	selectLine.visible = false
	lineChooseMark.visible = false
	resetSelectLine()

var viarableBackup:Array
func saveObjVariable():
	viarableBackup = [self,LineSeqmentVisible.duplicate(true),1]

func undoUpdate(_list):
	LineSeqmentVisible = _list[1].duplicate(true)
	if ActionsList.size() > 1:
		if _list[2] == 1:
			ActionsLisBackup.append(ActionsList.pop_back()) 
		else:
			ActionsList.append(ActionsLisBackup.pop_back())
	resetAllLines()
	updateRealRect()
	updateAngleVecList()
	updateCircle()
	CheckIntersection.updateSelectBox()

###########################
###########################
# erase funcs
func eraseMode():
	if typeof(realCircleRadius) == TYPE_VECTOR2:
		WV.makeAd('14')
		return
	
	saveObjVariable()
	WV.drawingScreen.changePaintState('object_edit')
	# restart operation
	erase_OpIndex = 0
	erase_hitAngleList.clear()
	# choose seqment if there more than one seqment
	if LineSeqmentVisible.size() > 1:
		mode = 'chooseSeqment'
		lineChooseMark.visible = true
		return
		
	elif len(LineSeqmentVisible) == 1:
		ChoosedLine = LineSeqmentVisible[0]

	Show_line.visible = true
	mode = 'erase'

# this func return seqment of line with mouse pointer
# projected on 
func chooseSeqment():
	var mouseVec = (WV.mousePointer - circlePos).normalized()
	for i in LineSeqmentVisible:
		var angle = i[0] + i[1]/2
		var vec = Vector2(cos(angle),sin(angle))
		angle = abs(vec.angle_to(mouseVec))
		if angle < abs(i[1]/2): 
			return i

func hideLineChooseMark():
	var count = lineChooseMark.get_point_count() 
	for i in count:
		lineChooseMark.points[i] = Vector2.ZERO

func updateLineChooseMark(seqment=[]):
	if seqment.size():
		lineChooseMark.visible = true
		var count = lineChooseMark.get_point_count() 
		for i in count:
			var fac = float(i)/(count-1)
			var angle = seqment[0] + fac*seqment[1]
			var vec = circleRadius*Vector2(cos(angle),sin(angle)) + circlePos
			lineChooseMark.points[i] = vec
	else:
		lineChooseMark.visible = false
	

func resetSelectLine() -> void:
	var count  = selectLine.get_point_count()
	for i in count:
		selectLine.points[i] = Vector2.ZERO

func updateSelectLine() -> void:
	if erase_OpIndex == 1:
		var count  = selectLine.get_point_count()
		for i in count:
			var angle =  AngleCounter_storage * (float(i)/(count-1) ) + erase_hitAngleList[0]
			var vec = circleRadius*Vector2(cos(angle),sin(angle)) + circlePos
			selectLine.points[i] = vec
		

func updateCursorPos():
	var vec = ProjectionPnt + circlePos
	if erase_OpIndex == 0:
		Show_line.points[0] = vec
		Show_line.points[1] = circlePos
		Show_line.points[2] = vec
		
	elif erase_OpIndex == 1:
		Show_line.points[2] = vec
	
	
func updateProjectionPnt():
	var mouseVec = (WV.mousePointer - circlePos).normalized()
	var a1 = ChoosedLine[0]
	var startVec = Vector2(cos(a1),sin(a1))
	
	var toStart = getAngle(mouseVec.angle() ,startVec.angle() ,-sign(ChoosedLine[1]))
	ErasePntTouchEdge = true
	if toStart>0 and -toStart>ChoosedLine[1]:
		ProjectionPnt = mouseVec * circleRadius 
		return 
	if toStart>0 and toStart<ChoosedLine[1]:
		ProjectionPnt = mouseVec * circleRadius 
		return 
	
	ErasePntTouchEdge = false
	var a2 = ChoosedLine[1] + ChoosedLine[0]
	var endVec = Vector2(cos(a2),sin(a2))
	var d1 = mouseVec.dot(startVec)
	var d2 = mouseVec.dot(endVec)
	if d1 > d2:
		ProjectionPnt = startVec * circleRadius 
	else:
		ProjectionPnt = endVec * circleRadius 


func erasingOP():
	Undo.addNewChunk('editObj',[self,LineSeqmentVisible.duplicate(true),1])
	Show_line.visible = false
	
#	modulateAngle()
	
	# full circle editing
	if ChoosedLine[0] == 0 && ChoosedLine[1] == TAU:
		EraseTouchEdgeList[0] = false # selected angle touch the  start of circle
		LineSeqmentVisible[0][0] = erase_hitAngleList[0]
		
	# not touch the start nor the end of circle
	if EraseTouchEdgeList[0] and EraseTouchEdgeList[0]: # divide into three seqment
		var allAngles:Array
		allAngles.resize(4)
		allAngles[0] = ChoosedLine[0]
		allAngles[3] = ChoosedLine[0]+ChoosedLine[1]
		
		var direction = sign(ChoosedLine[1])
		
		var arr = []
		arr.resize(2)
		arr[0] = getAngle(ChoosedLine[0],erase_hitAngleList[0],-direction)
		arr[1] = getAngle(ChoosedLine[0],erase_hitAngleList[0]+erase_hitAngleList[1],-direction)
		
		allAngles[1] = -direction * max(abs(arr[0]),abs(arr[1])) + ChoosedLine[0]  
		allAngles[2] = -direction * min(abs(arr[0]),abs(arr[1])) + ChoosedLine[0] 
		
		var dump = []
		for i in allAngles.size():
			dump.append(allAngles[allAngles.size()-i-1])
		
		allAngles = dump
		
		for i in allAngles.size():
			var angle = remainder(allAngles[i]+TAU,TAU)
			allAngles[i] = angle
		
		var seqment1 = [allAngles[0],-direction * getAngle(allAngles[0],allAngles[1],-direction)]
		var seqment2 = [allAngles[1],-direction * getAngle(allAngles[1],allAngles[2],-direction)]
		var seqment3 = [allAngles[2],-direction * getAngle(allAngles[2],allAngles[3],-direction)]
		
		LineSeqmentVisible.append(seqment1)
		LineSeqmentVisible.append(seqment3)
		
		ActiveSeqment = seqment2
		
	else: 
		var allAngles = []
		allAngles.resize(3)

		allAngles[0] = ChoosedLine[0]
		allAngles[1] = erase_hitAngleList[0] + erase_hitAngleList[1]
		allAngles[2] = ChoosedLine[0] + ChoosedLine[1]
		
		var direction = sign(ChoosedLine[1])
		
		var seqment1 = [allAngles[0],direction * getAngle(allAngles[0],allAngles[1],direction)]
		var seqment2 = [allAngles[1],direction * getAngle(allAngles[1],allAngles[2],direction)]
		
		var cond1 = sign(erase_hitAngleList[1]) > 0
		
		if -direction < 0:
			cond1 = not(cond1)
		
		if cond1:
			LineSeqmentVisible.append(seqment1)
			ActiveSeqment = seqment2
		else:
			LineSeqmentVisible.append(seqment2)
			ActiveSeqment = seqment1
		
	# remove old
	var dumpList = LineSeqmentVisible
	for i in dumpList:
		if i[0] == ChoosedLine[0] and i[1] == ChoosedLine[1]:
			LineSeqmentVisible.erase(i)
			break
			
	ActionsList.append([ActionManager.getIndex(),
	ActiveSeqment.duplicate(true),
	LineSeqmentVisible.duplicate(true)])
	
	update()
	updateAngleVecList()
	finshErasing()


func getAngle(_angle ,_target ,_sign):
	var angle = remainder(_angle+TAU,TAU)
	var target = remainder(_target+TAU,TAU)
	var diff = angle - target
	if _sign >0:
		if angle < target:
			return -diff
		else:
			return -diff+TAU
	else:
		if angle < target:
			return diff+TAU
		else:
			return diff


func remainder(num:float ,denum):
	return num-int(num/denum)*denum

func modulateAngle(_angle):
	return remainder(_angle+TAU,TAU)

func finshErasing():
	mode = 'finsh'
	WV.drawingScreen.changePaintState('select')
	resetAllLines()
	reDraw(WV.LastScaleBackup)
	updateSnapPnts()
	updateRealRect()
	updateCircle()

func endSettingCircle():
	if Input.is_action_pressed("alt"):
		mode = 'setAngles'
		LineSeqmentVisible[0][0] = (WV.mousePointer - circlePos).angle()
		var vec = (WV.mousePointer-circlePos).normalized() * circleRadius + circlePos
		Show_line.points[0] = vec
		Show_line.points[1] = circlePos
		Show_line.points[2] = vec
		AngleCounterReset(WV.mousePointer -  circlePos)
		var dump = remainder(-rad2deg(LineSeqmentVisible[0][0])+360,360)
		WV.drawingScreen.lastPanel.start.text = str(dump)
		return 


	finshProcess()
	
func finshProcess():
	mode = 'finsh'
	CircleBoundary = LineSeqmentVisible[0]
	ActionsList.append([ActionManager.getIndex()])
	WV.allObject.append(self)
	emit_signal("finsh_object")
	
	resetAllLines()
	reDraw(WV.LastScaleBackup)
	updateSnapPnts()
	updateRealRect()
	updateCircle()

func updateSnapPnts():
	snapedPoint.clear()
	snapedPoint.append(realCirclePos)
	
	if LineSeqmentVisible[0][1] != TAU:
		for list in LineSeqmentVisible:
			for angle in [list[0],list[0]+list[1]]:
				snapedPoint.append(getRealPnt(angle))
			
var Vects = [Vector2.UP,Vector2.DOWN,Vector2.RIGHT,Vector2.LEFT]
func updateRealRect():
	var dumpList = []
	if objectType == 'circle':
		for list in LineSeqmentVisible:
			var start = list[0]
			var diff = list[1]
			for vec in Vects:
				var angle = start + diff/2
				angle = abs(vec.angle_to(getVecAngle(angle))) 
				if angle < abs(diff/2): # in range
					dumpList.append(realCircleRadius*vec+realCirclePos)
				else:                   # out of range
					var startVec = getVecAngle(start)
					var endVec = getVecAngle(start + diff)
					var diff1 = abs(startVec.angle_to(vec))
					var diff2 = abs(endVec.angle_to(vec))
					var a = [start , start+diff][int(diff2<diff1)]
					dumpList.append(getRealPnt(a))
	else:
		updateBezierRect()
		for l in pointsRealPos:
			for p in l:
				dumpList.append(p)
		
	realRect = WV.getBoundary(dumpList)
	
func getVecAngle(_angle:float) -> Vector2:
	return Vector2(cos(_angle),sin(_angle))

func getRealPnt(_angle) -> Vector2:
	return realCircleRadius * getVecAngle(_angle) + realCirclePos

func changeColor(_newColor):
	LastAppliedColor = _newColor
	for obj in linesArr:
		obj.default_color = _newColor

# fired from "Checkintersection.gd" globle script
func deselected():
	pass
	

# fired from "Checkintersection.gd" globle script
func selected():
	pass

var linesArr:Array=[]
func resetAllLines():
	# delete old lines
	for obj in linesHolder.get_children():
		obj.queue_free()
	
	linesArr.clear()
	for i in LineSeqmentVisible.size():
		linesArr.append(makeNewLine())


func makeNewLine():
	var line = Line2D.new()
	linesHolder.add_child(line)
	for i in circleRes:
		line.add_point(Vector2())
	line.width = 3
	line.default_color = objectColor
	return line

func updateScaleVar(_newFactor):
	circlePos = realCirclePos * _newFactor
	circleRadius = realCircleRadius * _newFactor
	updateCircle()

func reDraw(_newFactor):
	circlePos = realCirclePos * _newFactor
	circleRadius = realCircleRadius * _newFactor
	updateCircle()


func finshMove(_shift):
	realCirclePos += _shift
	circlePos = realCirclePos * WV.LastScaleBackup
	linesHolder.rect_position = Vector2()
	updateRealRect()
	updateCircle()
	updateSnapPnts()
	 

func shiftObj(_shift):
	linesHolder.rect_position = _shift * WV.LastScaleBackup

func applyScale(_vec,_value):
	flipAngles(_value)
	liveScale(_vec,_value)
	realCirclePos = (realCirclePos-_vec) *_value +_vec
	realCircleRadius = (_value*realCircleRadius).abs() # scalar
	var t = abs(realCircleRadius.x)-abs(realCircleRadius.y)
	if abs(t) <.0001:# still circle
		objectType = 'circle'
		DrawingType = 'caliper'
		realCircleRadius = realCircleRadius.x # convert to float
		updateRealRect()
	else: # convert to bezier
		objectType = 'bezier'
		DrawingType = 'bezier'
		updateBezierRect()

	reDraw(WV.LastScaleBackup)
	updateSnapPnts()

func applyRotate(_vec,_angle):
	liveRotate(_vec,_angle)
	for line in linesArr:
		line.rotation = 0
		line.position = Vector2()
	realCirclePos = (realCirclePos-_vec).rotated(_angle)+_vec
	circlePos = realCirclePos * WV.LastScaleBackup
	for i in LineSeqmentVisible.size():
		LineSeqmentVisible[i][0] += _angle
	
	updateAngleVecList()
	updateCircle()
	if objectType == 'circle':
		updateRealRect()
	elif objectType == 'bezier':
#		for line in linesArr:
#			for i in line.points.size():
#				line.points[i] = (line.points[i]-_vec).rotated(_angle) + _vec

		updateBezierRect()
	reDraw(WV.LastScaleBackup)
	updateSnapPnts()


func flipAngles(_vec):
	if _vec.y < 0:
		flipAnglges_y()
		resetAllLines()
		updateAngleVecList()
		changeColor(LastAppliedColor)
	if _vec.x < 0:
		flipAnglges_x()
		resetAllLines()
		updateAngleVecList()
		changeColor(LastAppliedColor)

func flipAnglges_y():
	for i in LineSeqmentVisible.size():
		for j in 2:LineSeqmentVisible[i][j] *=-1
	for i in LineSeqmentVisiblBackup.size():
		for j in 2:LineSeqmentVisiblBackup[i][j] *=-1

func flipAnglges_x():
	for i in LineSeqmentVisible.size():
		var k = LineSeqmentVisible[i][0]
		LineSeqmentVisible[i][0]= -k+PI
		LineSeqmentVisible[i][1]*=-1
	for i in LineSeqmentVisiblBackup.size():
		var k = LineSeqmentVisiblBackup[i][0]
		LineSeqmentVisiblBackup[i][0]=-k+PI
		LineSeqmentVisiblBackup[i][1]*=-1


func liveScale(_vec,_value):
	circlePos = ((realCirclePos-_vec)*_value +_vec)*WV.LastScaleBackup
	circleRadius = (_value*realCircleRadius)*WV.LastScaleBackup
	updateCircle()

func liveRotate(_vec,_angle):
	for line in linesArr:
		line.rotation = _angle
		line.position = ((-_vec).rotated(_angle)+_vec )*WV.LastScaleBackup

func updateBeizerSnapPnts():
	snapedPoint.clear()
	snapedPoint.append(realCirclePos)
	for line in linesArr:
		snapedPoint.append(line.points[0]/WV.LastScaleBackup)
		snapedPoint.append(line.points[-1]/WV.LastScaleBackup)

var pointsRealPos:Array
func updateBezierRect():
	pointsRealPos.clear()
	var fullList = []
	var minList = []
	for list in LineSeqmentVisible:
		var res = abs(int(list[1]*circleRes))
		for i in res:
			var angle = list[0] + float(i)/(res-1) * list[1]
			var pnt = getRealPnt(angle)
			minList.append(pnt)
			fullList.append(pnt)
		pointsRealPos.append(minList)
	realRect =WV.getBoundary(fullList)
	updateBeizerSnapPnts()
	











