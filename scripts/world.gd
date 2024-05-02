extends Spatial

const boardRulerEdgeDis = 0.035
const CircleResolution = 50

var FontSource
var LinesHolder

onready var CameraObject = $camera/cameraObject
onready var CameraTarget = $'camera/cameraTarget'
onready var holder2d = $Viewport/Holder_2d
onready var viewport = $Viewport
onready var newPaper = $newPaper
onready var cam = $camera/cameraObject/Spatial/Camera
onready var physicalLinesHolder = $physicalLineHolder
onready var caliper = $caliper
onready var boardCenterNode = $"board/board center"
onready var ruler45 = $ruler45
onready var boardRuler = $"board ruler"
onready var pen = $pen
onready var eraser = $eraser
onready var ruler6030 = $"ruler 6030"
onready var protractor = $protractor
onready var rulerStartCounting = $'board ruler/rulerStartCounting'
onready var WorldUI = $ui
onready var speedLabel = $speedLabel


# ruler 6030 variable
onready var Ruler6030Shift_30 = $"ruler 6030/30"
onready var Ruler6030Shift_60 = $"ruler 6030/60"

# uler 45 variable
onready var Ruler45_head1 = $ruler45/head1
onready var Ruler45_head2 = $ruler45/head2

# protaactor 
onready var ProtractorDrawShift = $protractor/drawShift
onready var ProtactorVerticalShift = $protractor/verticalShift
onready var ProtactorHorizantalShift = $protractor/horizantalShift

# ruler variable
var Ruler_downPos:Vector3
var Ruler_45BackupPos:Vector3
var Ruler_45Directoin:Vector3 = Vector3()
# boundies of the 2d disk
var boardCenter:Vector2

var LastAction
var ActionMainList:Array
var LinesIdInstance:Dictionary # contain all lines instance of that id
var IndexesDict:Dictionary
var SpeedFac: = 1.0

var DistanceTimeFac: = 5.0
var AngleTimeFac:= 1.0
var TimeRandomness = .1

var CastEngine = false

func _process(delta):
	actionTimeline(delta*SpeedFac)

func _ready():
	# set the orign point
	boardCenter.x = boardCenterNode.translation.x
	boardCenter.y = boardCenterNode.translation.z
	
	# save backup down pos
	Ruler_downPos = $"board ruler/down".translation
	Ruler_45BackupPos = ruler45.translation
	
	# update 'boardCenter' variable on action manager
	ActionManager.boardCenter = boardCenter
	
	# transform and scale down all the 2d points
	ActionManager.transformPnts()
	# setup caliper up direction
	caliper.rotation_degrees = Vector3(0,0,0)	
	
	SpeedFac = SettingLog.fetch('animation/speed')
	var engine = SettingLog.fetch('animation/engineType')
	if engine == 'full':
		var world = load('res://scenes/3d/secondEnv.tscn').instance()
		add_child(world)
	
	if CastEngine:
		WV.boardCenter = boardCenter
		viewport.size = WV.castEngineSize
		LinesHolder = holder2d
		FontSource = load('res://scenes/3d/segment2d.tscn')
	else:
		newPaper.queue_free()
		viewport.queue_free()
		LinesHolder = physicalLinesHolder
		FontSource = load('res://scenes/3d/lineSeqment.tscn')
		
	
	yield(get_tree().create_timer(2.5),"timeout")
	
	if ActionManager.PreActionArr.size():
		actionpipeline()

var StopIndex = 0
func _input(event):
	if Input.is_action_just_pressed("escape"):
		remove3dWorld()
	
	if Input.is_action_pressed("space"):
		var state = bool(StopIndex%2)
		set_process(state)
		StopIndex+=1
	
	if event is InputEventMouseButton:
		if event.button_index in [1,2]:
			remove3dWorld()
		if event.button_index in [4,5]:
			var sign_ = -2*(event.button_index-4)+1
			SpeedFac += .05 * sign_
			SpeedFac = clamp(SpeedFac,.1,2)
			setSpeedLabel()
			

func remove3dWorld():
	get_parent().swtichSceneto2d()
	WV.freeMotionLine.clear()

var LastSpeedLabelAction = false
func setSpeedLabel():
	if LastSpeedLabelAction:
		WV.freeMotionLine.erase(LastSpeedLabelAction)
		
	speedLabel.show()
	speedLabel.text = str(SpeedFac) + 'X'
	LastSpeedLabelAction = Motion.new()
	LastSpeedLabelAction.callFunc(self,'HideSpeedLabel',1)
	WV.freeMotionLine.append(LastSpeedLabelAction)

func HideSpeedLabel():
	LastSpeedLabelAction = false
	speedLabel.hide()

var ToolDict:={ # drawingTypes to drawing method
	['ruler/free_line','ruler45','perpendicular_ruler/line','ruler45/dot','perpendicular_ruler/dot',
	'ruler45/line','alongLine/line','alongLine/dot']:'ruler45',
	['ruler/vertical','dot/vertical','dot/down']:'vertical_line',
	
	['ruler/horizantal','dot/horizantal','alongLine/line','alongLine/dot']:'horizantal_line',
	
	['ruler6030','ruler6030/dot','ruler6030/line']:'ruler6030',
	['caliper']:'caliper',
	['dot/free','bezier']:'pencil',
	['compassor/freeAlign','compassor/vertical','compassor/horizantal']:'compassor',
	['erase','erase/circle','erase/line']:'erase'
}

# this contain the all dependances of each drawing method
var Dependances:={ 
	'ruler45':['pencil','ruler45'],
	'vertical_line':['pencil','ruler45','boardRuler'],
	'horizantal_line':['pencil','boardRuler'],
	'ruler6030':['pencil','ruler6030'],
	'caliper':['caliper'],
	'pencil':['pencil'],
	'compassor':['pencil','compassor'],
	'erase':['erase'],
}


func getToolNameFromDrawingType(_drawingType):
	for t in ToolDict:
		if _drawingType in t:
			return ToolDict[t]
	

var CurrentDrawingTool := 'pencil'
func cleanBoard(_drawingType):
	var newTool = getToolNameFromDrawingType(_drawingType)
	if newTool == null:
		print('error')
		print('didnt find tool == ',_drawingType)
	
	var oldToolSet = Dependances[CurrentDrawingTool]
	var newToolSet = Dependances[newTool]
	
	var unrequiredTool = []
	for t in oldToolSet:
		if not t in newToolSet:
			unrequiredTool.append(t)
	throughTool(unrequiredTool)
	
	if 'pencil' in oldToolSet and 'pencil' in newToolSet:
		var m = Motion.new()
		var pos = pen.translation + Vector3(0,.02,randSign()*0.06)
		m.makeMotion(pen,'translation',pos,1)
		WV.freeMotionLine.append(m)
	CurrentDrawingTool = newTool




# warning-ignore:unused_argument
func clearBoard(funcName):
	var list = ['ruler45','ruler6030',
	'boardRuler','pencil','caliper','compassor',
	'erase']
	throughTool(list)

var BackupPos_ruler45 = Vector2(0.187,0.408)
var BackupPos_ruler6030 = Vector2(0.187,.245)
var BackupPos_boardRuler = Vector2(-.121,0)
var BackupPos_pencil = Vector2(.033,-0.062)
var BackupPos_caliper = Vector2(.133,-.046)
var BackupPos_compassor = Vector2(.21,-.05)
var BackupPos_eraser = Vector2(.044,.478)

func throughTool(_toolList):
	var actionList = []
	for toolName in _toolList:
		match toolName:
			'ruler45':
				var m = setRuler45Pos(BackupPos_ruler45)
				var r = rotateObj(ruler45, Vector3())
				actionList.append_array([r,m])
			
			'ruler6030':
				var m = setPos(ruler6030,BackupPos_ruler6030)
				var r = rotateObj(ruler6030, Vector3())
				actionList.append_array([r,m])
			
			'boardRuler':
				var m = setPos(boardRuler,BackupPos_boardRuler)
				actionList.append(m)
			
			'pencil':
				var m = setPenPos(BackupPos_pencil)
				actionList.append(m)
				
			'caliper':
				var m = setCaliperPos(BackupPos_caliper)
				var r = rotateObj(caliper, Vector3())
				actionList.append_array([r,m])
				
				
			'compassor':
				var m = setProtractorPos(BackupPos_compassor)
				var r = rotateObj(protractor, Vector3())
				actionList.append_array([r,m])
			
			'erase':
				var m = setEraserPos(BackupPos_eraser)
				actionList.append(m)
	
	ActionMainList.append_array([actionList])
	syncLastList()


var ActionPipelineIndex = 0
func actionpipeline():
	var newAction = ActionManager.PreActionArr[ActionPipelineIndex]
	processNewAction(newAction)
	ActionPipelineIndex+=1
	
func processNewAction(action):
	if not('DrawingType' in action):
		print(action)
	var drawingType = action['DrawingType']
	var firstName = drawingType.split('/')[0]
	
	cleanBoard(drawingType)
	LastAction = action
	ActionMainList.append(['buildCameraMotion'])
	
	if 'ruler' == firstName:
		var subType = drawingType.split('/')[1]
		WorldUI.resetLine()
		WorldUI.updateMode('pencil/ruler')
		var sideMotion
		if subType == 'horizantal':
			var boardRulerMove = boardRulerLinearMove(action['points/oneLayer'][0])
			ActionMainList.append([boardRulerMove])
			# ui
			var l =uiMeasureDisThreePnt(to2d(rulerStartCounting.translation),
			action['points/oneLayer'][0],
			action['points/oneLayer'][1])
			sideMotion = WorldUI.drawLine(l[0],l[1])
			
		elif subType == 'vertical':
			var boardRulerMove = boardRulerLinearMove(action['points/oneLayer'][0],
			int(action['points/oneLayer'][0].y < action['points/oneLayer'][1].y))
			var ruler45Move = ruler45FullMove(action['points/oneLayer'])
			ActionMainList.append(ruler45Move + [boardRulerMove])
			syncLastList()
			# ui 
			var spam = uiMeasureDisTwoPnt(action['points/oneLayer'][1],action['points/oneLayer'][0])
			sideMotion = WorldUI.drawLine(0,spam)
			
		
		elif subType == 'free_line':
			var ruler45Action = ruler45FullMove(action['points/oneLayer'])
			ActionMainList.append(ruler45Action)
			syncLastList()
			# ui
			var spam = uiMeasureDisTwoPnt(action['points/oneLayer'][1],action['points/oneLayer'][0])
			sideMotion = WorldUI.drawLine(0,spam)
			
		# pen action	
		var penMotion =setPenPos(action['points/oneLayer'][0])
		ActionMainList.append([penMotion])
		var line = linesMaker(action['points/oneLayer'])
		penMotion = setPenPos(action['points/oneLayer'][1])
		penMotion.LineInstance = line
		penMotion.ChildList.append_array(sideMotion)
		ActionMainList.append([penMotion])
		LinesIdInstance[action['id']] = [line]
	
	
	if 'alongLine' == firstName:
		WorldUI.resetLine()
		WorldUI.updateMode('pencil/ruler')
		var subType = drawingType.split('/')[1]
		var linePnt = action['actualLine/oneLayer']
		var values = action['values']
		var directionalPnts = [lerp(linePnt[0],linePnt[1],values[0]),
							   lerp(linePnt[0],linePnt[1],values[1])]
		
		var dict = {0:linePnt[0],1:linePnt[1],
				values[0]:directionalPnts[0],
				values[1]:directionalPnts[1]}
				
		var min_=INF
		var max_=-INF
		for i in dict.keys():
			if i < min_: min_ =i
			if i > max_: max_ =i
		
		var alignLine = [dict[min_],dict[max_]]
		
		if action['type'] == 'free':
			var ruler45Action = ruler45FullMove(alignLine)
			ActionMainList.append(ruler45Action)
			syncLastList()
			
		elif action['type'] == 'horizantal':
			var boardRulerMove = boardRulerLinearMove(action['actualLine/oneLayer'][0])
			ActionMainList.append([boardRulerMove])
			
		elif action['type'] == 'vertical':
			var boardRulerMove = boardRulerLinearMove(alignLine[0],
			int(linePnt[0].y < linePnt[1].y))
			var ruler45Move = ruler45FullMove(alignLine)
			ActionMainList.append(ruler45Move + [boardRulerMove])
			syncLastList()
		
		if subType == 'dot':
			specialDot(alignLine[min_],linePnt[1])
			
		elif subType == 'line':
			spcialLine(action['id'],dict[min_],linePnt[0],linePnt[1])
		
	# work
	if 'compassor' == firstName:
		WorldUI.updateMode('compassor')
		var subType = drawingType.split('/')[1]
		var points = action['points/oneLayer']
		var move = setProtractorPos(points[0])
		var rot = rotateClosetAngle(protractor,-action['mainAngle']+PI)
		ActionMainList.append([rot,move])
		syncLastList()
		
		
		var pos = Vector2()
		if subType == 'vertical' :
			var inverseState = int(points[1].x > points[0].x)*2-1
			pos = points[0] - Vector2(0,.013) * inverseState- Vector2(0.061,0)
			var pos_shifted = pos + Vector2(1,0).rotated(-1.57*int(points[1].x > points[0].x))
			var ruler45Move = ruler45FullMove([pos,pos_shifted])
			ActionMainList.append(ruler45Move)
			syncLastList()
		
		if subType == 'vertical' or subType == 'horizantal':
			if pos.x:
				ActionMainList.append([boardRulerLinearMove(pos)])
			else:
				var inverseState = int(points[1].y > points[0].y)
				var boardRulerPos = points[0] + Vector2(.013,0) * (inverseState*2-1)
				var boardRulerMove = boardRulerLinearMove(boardRulerPos,inverseState)
				ActionMainList.append([boardRulerMove])
		
		var dotPos = (points[1]-points[0]).normalized() * 0.054 +points[0]
		var penMotion =setPenPos(dotPos)
		ActionMainList.append([penMotion])
		ActionMainList.append(['drawDot',dotPos])
		var a = rad2deg(action['angle'])
		penMotion.ChildList.append(WorldUI.setAngle(-a))
		
	
	if 'ruler45' == firstName:
		var actualLine = action['actualLine/oneLayer']
		var basePnt = lerp(actualLine[0],actualLine[1],action['ratio'])
		
		var shift = PI + PI/8
		var angle = shift + action['AlignLineAngle'] - action['diffAngle']
		var alignVec = Vector2(cos(angle),sin(angle))

		var selectedHead = Ruler45_head1
		var otherHead = Ruler45_head2

		var vec1 = (otherHead.global_translation - ruler45.translation).normalized()
		var vec2 = (selectedHead.global_translation - ruler45.translation).normalized()

		var vec3 = to2d((vec1+vec2).normalized())
		var diffAngle = -vec3.angle_to(alignVec) 
		var m = ruler45Motion(selectedHead,diffAngle,basePnt)
		
		ActionMainList.append([m])
		
		if action['realType'] == 'dot':
			specialDot(actualLine[0],actualLine[1])
			
		elif action['realType'] == 'line':
			spcialLine(action['id'],basePnt,actualLine[0],actualLine[1])
			
	
	if 'ruler6030' == firstName:
		var pntIndSht = int(action['angleType']=='30') # 30=1 // 60 = 0
		var actualLine = action['actualLine/oneLayer']
		var basePnt = lerp(actualLine[0],actualLine[1],action['ratio'])
		
		var p1 = ruler6030.translation
		var p2 = Ruler6030Shift_60.global_translation
		var p3 = Ruler6030Shift_30.global_translation
		var pntArr = [p1 , p2 , p3 , p1]
		
		var vec1 = (pntArr[0+pntIndSht] - pntArr[1+pntIndSht]).normalized()
		var vec2 = (pntArr[2+pntIndSht] - pntArr[1+pntIndSht]).normalized()
		
		var vec3 = to2d((vec1+vec2).normalized())
		
		var vecAngle = PI/2 + action['AlignLineAngle'] - action['diffAngle']
		
		var alignVec = Vector2(cos(vecAngle),sin(vecAngle))
		var diffAngle = -vec3.angle_to(alignVec) 

		var instance = [Ruler6030Shift_60,Ruler6030Shift_30][pntIndSht]
		var m =ruler6030Motion(instance,diffAngle,basePnt)
		ActionMainList.append([m])
			
		if action['realType'] == 'dot':
			specialDot(basePnt,actualLine[1])
		elif action['realType'] == 'line':
			spcialLine(action['id'],basePnt,actualLine[0],actualLine[1])

	elif 'caliper' in drawingType:
		WorldUI.updateMode('caliper/ruler')
		
		caliper.rotation.y = remainder(caliper.rotation.y+TAU ,TAU)
		var sideMotion = WorldUI.setCaliperWidth(action['caliperWidth']*100)
		var caliperMove = setCaliperPos(action['circlePos/oneLayer'][0])
		var caliperWidth = setCaliperWidth(action['caliperWidth'])
		
		var angle = -action['visibleLineSeqment'][0][0] + 1.57
		var caliperRot = setCaliperRot(angle)
		
		ActionMainList.append([caliperWidth,caliperMove,caliperRot])
		caliperWidth.ChildList.append_array(sideMotion)
		syncLastList()
		
		var caliper_action = caliperAction(action)
		ActionMainList.append([caliper_action])
		
		# work
	elif 'dot' == firstName:
		var subType = drawingType.split('/')[1]
		var points = action['dotPoints/oneLayer']
		if subType == 'free':
			WorldUI.updateMode('pencil')
			var penMotion =setPenPos(points[0])
			ActionMainList.append([penMotion])
			ActionMainList.append(['drawDot',points[1]])
			
		elif subType== 'horizantal':
			var boardRulerMove = boardRulerLinearMove(points[0])
			ActionMainList.append([boardRulerMove])
			specialDot(points[0],points[1])
			
		elif subType == 'vertical':
			var boardRulerMove = boardRulerLinearMove(points[0])
			var ruler45Move = ruler45FullMove(points)
			ActionMainList.append(ruler45Move + [boardRulerMove])
			syncLastList()
			specialDot(points[0],points[1])
			
		elif subType == 'down':
			var boardRulerMove = boardRulerLinearMove(points[0],1)
			var ruler45Move = ruler45FullMove(points)
			ActionMainList.append(ruler45Move + [boardRulerMove])
			syncLastList()
			var penMotion =setPenPos(points[0])
			ActionMainList.append([penMotion])
			specialDot(points[0],points[1])
			
			
	elif 'perpendicular_ruler' == firstName:
		var actualLine = action['actualLine/oneLayer']
		var basePnt = lerp(actualLine[0],actualLine[1],action['ratio'])
		
		var v = ruler45FullMove([basePnt,actualLine[1]])
		ActionMainList.append(v)
		syncLastList()
		if action['realType'] == 'dot':
			specialDot(basePnt,actualLine[1])
		elif action['realType'] == 'line':
			spcialLine(action['id'],basePnt,actualLine[0],actualLine[1])
	
	elif 'bezier' == firstName:
		WorldUI.updateMode('pencil')
		for list in action['bezier/twoLayer']:
			var penMotion =setPenPos(list[0])
			ActionMainList.append([penMotion])
			
			penMotion =followCurve(pen,list)
			ActionMainList.append([penMotion])
			var line = linesMaker(list)
			penMotion.LineInstance = line
			
			makeFakeAction(1)
			
	elif 'erase' == firstName:
		var subType = drawingType.split('/')[1]
		WorldUI.updateMode('eraser')
		if subType == 'line':
			var id = action['id']
			var index = action['index']
			ActionMainList.append(['rebuildLines',id ,index])
			
			var dict = {}
			dict['lineSeqment'] = action['lineSeqment/twoLayer']
			dict['activeSeqment'] = action['activeSeqment/oneLayer']
			IndexesDict[index] = dict
			
		elif subType == 'circle':
#			var id = action['id']
			var index = action['index']
			ActionMainList.append(['rebuildCircle',action])
			
			var dict = {}
			dict['angleSeqment'] = action['angleSeqment']
			dict['activeAngle'] = action['activeAngle']
			IndexesDict[index] = dict
	
	makeFakeAction(1)
	ActionMainList.append(['loadnewCunk'])
	
func actionTimeline(delta):
	CameraObject.process(delta)
	delta = delta
	cam.look_at(boardCenterNode.global_translation,Vector3.UP)
	if WV.freeMotionLine.size():
		for i in WV.freeMotionLine:
			if i.move(delta):
				WV.freeMotionLine.erase(i)
	
	if ActionMainList.size():
		if ActionMainList[0].size():
			if typeof(ActionMainList[0][0]) == TYPE_STRING:
				callv(ActionMainList[0][0],ActionMainList[0])
				
				ActionMainList.pop_front()
				return
			
			var list:Array = ActionMainList[0]
			for i in list:
				if i.move(delta):
					ActionMainList[0].erase(i)
		else:
			ActionMainList.pop_front()


# warning-ignore:unused_argument
func loadnewCunk(FuncName):
	if ActionManager.PreActionArr.size() != ActionPipelineIndex:
		actionpipeline()
	else:
		ActionMainList.append(['clearBoard'])
		CameraObject.addNewCenter(Vector3())


#ActionMainList.append(['testFunc'])
func testFunc(_funcName):
	pass
	

func spcialLine(_id,_p0,_p1,_p2):
	# move to first position
	var penMotion = setPenPos(_p1)
	penMotion.VerticalMove = .015
	ActionMainList.append([penMotion])
	# move to second position
	penMotion = setPenPos(_p2)
	ActionMainList.append([penMotion])
	# draw line
	var line = linesMaker([_p1,_p2])
	penMotion.LineInstance = line
	LinesIdInstance[_id] = [line]
	# ui
	WorldUI.resetLine()
	WorldUI.updateMode('pencil/ruler')
	var l = uiMeasureDisThreePnt(_p0,_p1,_p2)
	penMotion.ChildList.append_array(WorldUI.drawLine(l[0],l[1]))

func specialDot(_p1,_p2):
	# move to first position
	var penMotion = setPenPos(_p1)
	penMotion.VerticalMove = .015
	ActionMainList.append([penMotion])
	# move to second position
	penMotion = setPenPos(_p2)
	# ui
	WorldUI.resetLine()
	WorldUI.updateMode('pencil/ruler')
	var spam = uiMeasureDisTwoPnt(_p1,_p2)
	penMotion.ChildList.append(WorldUI.drawDot(spam))
	ActionMainList.append([penMotion])
	# draw phycial dot
	ActionMainList.append(['drawDot',_p2])


func uiMeasureDisThreePnt(_p0,_p1,_p2):
	var start = (_p0-_p1).length() * 100
	var end = (_p0-_p2).length() * 100
	return [start,end]

func uiMeasureDisTwoPnt(_p1,_p2):
	return (_p1-_p2).length() * 100


func buildCameraMotion(_funcName):
	var list = []
	for i in LastAction:
		if 'oneLayer' in i :
			list.append_array(LastAction[i])
		if 'twoLayer' in i:
			for j in LastAction[i].size():
				list.append_array(LastAction[i][j])
				
	if list.size():
		var middleOfShape = to3d(getPntsMean(list)) - boardCenterNode.translation
		CameraObject.addNewCenter(middleOfShape)

# warning-ignore:unused_argument
func drawDot(funcName ,_pos):
	linesMaker([_pos])
	
# warning-ignore:unused_argument
func rebuildCircle(funcName, _action):
	var id = _action['id']
	# delete main seqment
	for line in LinesIdInstance[id]:
		line.queue_free()
	# clear 'LinesIdDict' form old instance
	LinesIdInstance[id] = []
	
	var radius = _action['circleRadius']
	var circlePos:Vector2
	for action in ActionManager.PreActionArr:
		if 'id' in action:
			if action['id'] == _action['id']:
				circlePos = action['circlePos/oneLayer'][0]
				break
	
	# draw lines seqment
	for list in IndexesDict[_action['index']]['angleSeqment']:
		var points = drawCirclePart(circlePos,radius,list[0],list[1])
		var line = linesMaker(points)
		line.build(1)
		LinesIdInstance[id].append(line)
	
	var startAngle = _action['activeAngle'][0]
	var diffAngle = _action['activeAngle'][1]
	var activePnts = drawCirclePart(circlePos,radius,startAngle,diffAngle)
	var line = linesMaker(activePnts)
	line.build(1)
	
	var eraserMove = setEraserPos(activePnts[-1])
	ActionMainList.append([eraserMove])
	
	eraserMove = eraserAction(activePnts)
	ActionMainList.append([eraserMove])
	eraserMove.LineInstance = line
	
# return list with all points in arc between startAngle and diff angle
func drawCirclePart(_pos ,_radius , _startAngle ,diffAngle):
	var startAngle = _startAngle+1.57
	var resolution = abs(int(CircleResolution * diffAngle/TAU))+2
	var pnts = []
	for i in resolution:
		var fac = float(i)/(resolution-1)
		var angle = startAngle + fac * diffAngle
		var vect = _radius * Vector2(cos(angle),sin(angle)) + _pos
		pnts.append(vect)
	return pnts

# warning-ignore:unused_argument
func rebuildLines(funcName,_id ,_index):
	# delete main seqment
	for line in LinesIdInstance[_id]:
		line.queue_free()
	# clear 'LinesIdDict' form old instance
	LinesIdInstance[_id] = []
	for line in IndexesDict[_index]['lineSeqment']:
		var l = linesMaker(line)
		l.build(1)
		LinesIdInstance[_id].append(l)
	
	var eraserMove = setEraserPos(IndexesDict[_index]['activeSeqment'][-1])
	ActionMainList.append([eraserMove])
	
	eraserMove = eraserAction(IndexesDict[_index]['activeSeqment'])
	ActionMainList.append([eraserMove])
	
	var line = linesMaker(IndexesDict[_index]['activeSeqment'])
	line.build(1)
	eraserMove.LineInstance = line

func syncLastList():
	mergeTimeMax(ActionMainList[-1])

func mergeTimeMax(_list):
	var maxTime:float = -INF
	for action in _list:
		if action.ActionTime > maxTime:
			maxTime = action.ActionTime
	for action in _list:
		action.ActionTime = maxTime
	
func linesMaker(_list):
	var line = FontSource.instance()
	LinesHolder.add_child(line)
	line.add_list(_list)
	return line

func rotateObj(_insta,_angle):
	var r = Motion.new()
	r.makeMotion(_insta,'rotation_degrees',_angle,1)
	return r

func rotateClosetAngle(_instance,_angle):
	var m = Motion.new()
	var time_2 = abs(_instance.rotation.y-_angle) + .1
	m.rotClosetAngle(_instance,_angle,time_2*AngleTimeFac*getRand())
	return m

func setProtractorPos(_pos):
	var m = Motion.new()
	var time_1 = (protractor.translation-to3d(_pos)).length() +.1
	m.makeMotion(protractor,'translation',to3d(_pos),time_1*DistanceTimeFac*getRand())
	return m


func setPenPos(_pos):
#	penFloatingMotion.moveFactor = 1
	var pos = to3d(_pos)
	var time_1 = (pos-pen.translation).length() + .1
	var penMotion = Motion.new()
	penMotion.makeMotion(pen ,'translation',pos,time_1*DistanceTimeFac*getRand())
	return penMotion


func followCurve(_instance , _path,_reverse=false):
	var time_1 = 0.1
	for i in _path.size()-1:
		time_1 += (_path[i]-_path[i+1]).length()
	var m = Motion.new()
	m.followCurve(_instance ,_path , time_1*DistanceTimeFac*getRand() , _reverse)
	return m

func ruler45FullMove(_list):
	var m = setRuler45Pos(_list[0])
	var r = setRuler45Direction(_list)
	return [m , r]

func setRuler45Pos(_pos):
	var pos = to3d(_pos)
	var time_1 = (ruler45.translation-pos).length() + .1
	var ruler45Move = Motion.new()
	ruler45Move.makeMotion(ruler45 , 'translation',pos ,time_1*DistanceTimeFac*getRand() )
	return ruler45Move

func setRuler45Direction(_list):
	var angle = (_list[1]-_list[0]).angle()
	var m = Motion.new()
	m.caliperRotation(ruler45 , -angle-1.57,1)
	return m

func setPos(_instance,_pos):
	_pos = to3d(_pos)
	var time_1 = (_instance.translation-_pos).length() + .1
	var m = Motion.new()
	m.makeMotion(_instance,'translation',_pos,time_1*DistanceTimeFac*getRand() )
	return m
	
func setBoardRulerPos(_pos):
	var pos = to3d(_pos)
	var time_1 = (pos-boardRuler.translation).length() + .1
	var boardRulerMove = Motion.new()
	boardRulerMove.makeMotion(boardRuler,'translation',pos,time_1*DistanceTimeFac*getRand())
	return boardRulerMove

func setRuler45(_pos):
	var pos = to3d(_pos)
	var time_1 = (pos-ruler45.translation).length() + .1
	var ruler45Move = Motion.new()
	ruler45Move.makeMotion(ruler45,'translation',pos,time_1*DistanceTimeFac*getRand())
	return ruler45Move

# _upperRulerSide' if  it 1 the upper side of ruler will align with
# while if it equal to 0 the lower side of ruler will align with _vec
func boardRulerLinearMove(_vec ,_upperRulerSide=0):
	var vect = Vector2(_vec.x,boardRuler.translation.z)
	var state = _upperRulerSide * 2-1
	vect.x += boardRulerEdgeDis * state
	var m = setBoardRulerPos(vect)
	return m
	
func setCaliperPos(_pos):
	var pos = to3d(_pos)
	var time_1 = (pos-caliper.translation).length() + .1
	var caliperMotion = Motion.new()
	caliperMotion.makeMotion(caliper ,'translation',pos , time_1*DistanceTimeFac*getRand())
	return caliperMotion
	
func setCaliperRot(_angle):
	var time_2 = getAngleDiff(caliper.rotation.y,_angle) + .1
	var caliperRot = Motion.new()
	caliperRot.caliperRotation(caliper ,_angle , time_2*AngleTimeFac*getRand())
	return caliperRot
	
func caliperAction(_dict):
	var startAngle = _dict['visibleLineSeqment'][0][0]+1.57
	var diffAngle = _dict['visibleLineSeqment'][0][1]
	var radius = _dict['caliperWidth']
	var circlePos = _dict['circlePos/oneLayer'][0]
	
	var vec = Vector3(0,-diffAngle,0)
	var caliperRot = Motion.new()
	caliperRot.caliperAction(caliper ,vec,2)
	
	var pnts = []
	var resolution = abs(int(CircleResolution * diffAngle/(2*PI)))
	if resolution ==1:
		resolution=5
	for i in resolution:
		var fac = float(i)/(resolution-1)
		var angle = startAngle + fac * diffAngle
		var vector = radius * Vector2(cos(angle),sin(angle)) + circlePos
		pnts.append(vector)
	
	var time_1 = .1
	for i in pnts.size()-1:
		time_1 += (pnts[i]-pnts[i+1]).length()
	
	caliperRot.ActionTime = time_1 * DistanceTimeFac * getRand()
	
	var line = linesMaker(pnts)
	caliperRot.LineInstance = line
	LinesIdInstance[_dict['id']] = [line]
	
	return caliperRot

func setCaliperWidth(_width):
	var caliperWidth = Motion.new()
	caliperWidth.caliperWidth(caliper ,_width,1)
	return caliperWidth

func setEraserPos(_pos):
	var pos = to3d(_pos)
	var time_1 = (eraser.translation-pos).length() +.1
	var motion = Motion.new()
	motion.makeMotion(eraser ,'translation',pos ,time_1*DistanceTimeFac*getRand())
	motion.VerticalMove = (time_1-.1)*.05
	return motion

func eraserAction(_list):
	var m = Motion.new()
	var list = _list.duplicate(true)
	var time_1 = .1
	for i in list.size()-1:
		time_1 += (list[i]-list[i+1]).length()
	time_1*=3
	list.invert()
	m.followCurve(eraser ,list , time_1*DistanceTimeFac*getRand() , true)
	return m

func ruler6030Motion(_3dPos,_diffAngle,_headPos):
	var m = Motion.new()
	var time_2 = abs(_diffAngle) + .1
	m.ruler6030Motion(ruler6030,_3dPos,_diffAngle,to3d(_headPos),time_2*AngleTimeFac*getRand())
	return m

func ruler45Motion(_3dPos,_diffAngle,_headPos):
	var m = Motion.new()
	var time_2 = abs(_diffAngle) + .1
	m.ruler6030Motion(ruler45,_3dPos,_diffAngle,to3d(_headPos),time_2*AngleTimeFac*getRand())
	return m

func getAngleDiff(_a1,_a2):
	var vec1 = polar2cartesian(1,_a1)
	var vec2 = polar2cartesian(1,_a2)
	return abs(vec1.angle_to(vec2))

func makeFakeAction(_time):
	var f = Motion.new()
	f.fakeAction(.5)
	ActionMainList.append([f])
	
func to2d(vec:Vector3)->Vector2:
	return Vector2(vec.x,vec.z)

func to3d(vec:Vector2) -> Vector3:
	return Vector3(vec.x,0,vec.y)

func getPntsMean(_arr):
	var MinX = INF ;var MaxX = -INF
	var MinY = INF ;var MaxY = -INF
	for pnt in _arr:
		if pnt.x < MinX:
			MinX = pnt.x
		if pnt.x > MaxX:
			MaxX = pnt.x
		if pnt.y > MaxY:
			MaxY = pnt.y
		if pnt.y < MinY:
			MinY = pnt.y
			
	return Vector2(MaxX + MinX,MaxY + MinY)/2

func maxTimeOfActionList(_list):
	var MaxTime = 0
	for action in _list:
		if action.ActionTime > MaxTime:
			MaxTime = action.ActionTime
	return MaxTime

func sumOfMaxes(_arrArr):
	var TimeSum = 0
	for list in _arrArr:
		TimeSum+=maxTimeOfActionList(list)
	return TimeSum

func getRand() -> float:
	return rand_range(1-TimeRandomness,1+TimeRandomness)

func randSign():
	return sign(randf()-.5)

func remainder(num:float ,denum):
	return num-int(num/denum)*denum
