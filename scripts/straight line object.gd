extends Line2D


signal finsh_object
var objectType = 'straight_line'
var DrawingType = 'ruler/free_line'
var objectColor = Color('66ffe2')
var snapedPoint:Array
var LayerId


onready var pointerIcon = $pointer
onready var hideLineHolder = $"hide line holder"
onready var lineChooseMark = $"line choose mark"
onready var cutMarker = $"cut marker"
onready var linesHolder = $linesHolder

var boundaryBox
var boundaryBoxPath = 'res://scenes/drawing side/weldaan/straightLine/lineBoundaryBoxDrawer.tscn'

var mode = 'free_draw'
var lineLength:float
var lineAngle:float


var LineSeqmentVisible:Array # contain only visible seqment
var ChoosedLine:Array
var RealBoardLine:Array
var RealBoardLinLength:float
var ActionsList:Array
var ActionsLisBackup:Array

# erase variable
var erase_OpIndex=0
var erase_hitPointList:Array 

var LineHeadPos
var realRect:Rect2

var MeasureToolData:Dictionary

func copy():
	var dict = {}
	dict['objectType'] = objectType
	dict['DrawingType'] = DrawingType
	dict['LayerId'] = LayerId
	
#	dict['snapPnts'] = snapedPoint
	dict['lineLength'] = lineLength
	dict['lineAngle'] = lineAngle
	dict['measureToolData'] = MeasureToolData
	
	dict['LineSeqmentVisible'] = LineSeqmentVisible
	dict['RealBoardLine'] = RealBoardLine
	dict['ActionsList'] = ActionsList
	dict['RealBoardLinLength'] = RealBoardLinLength
	
	return dict


func paste(dict):
	DrawingType = dict['DrawingType']
	LayerId = dict['LayerId']
	lineLength = dict['lineLength']
	lineAngle = dict['lineAngle']
	RealBoardLinLength = dict['RealBoardLinLength']
	LineSeqmentVisible = dict['LineSeqmentVisible'].duplicate(true)
	RealBoardLine = dict['RealBoardLine'].duplicate(true)
	ActionsList = dict['ActionsList'].duplicate(true)
	for i in ActionsList.size():
		ActionsList[i][0] = WV.drawingScreen.IndexSequenceDict[ActionsList[i][0]]
		
	if dict['measureToolData']:
		MeasureToolData = dict['measureToolData'].duplicate(true)
		MeasureToolData['index'] = WV.drawingScreen.IndexSequenceDict[dict['measureToolData']['index']]
		MeasureToolData['id'] = str(MeasureToolData['index'])
		
	clear_points()
	resetAllLines()
	updateRealRect()
	WV.allObject.append(self)
	mode = 'finsh'
	updateSnapPnt()
	var c = LayerManager.LayerPanel.layerIdDict[LayerId].LayerColor
	changeColor(c)
	objectColor = c



func makeLine(p1,p2):
	p1 = p1/WV.LastScaleBackup
	p2 = p2/WV.LastScaleBackup
	
	snapedPoint.append(p1)
	snapedPoint.append(p2)
	snapedPoint.append((p1+p2)/2)

	LineSeqmentVisible = [[p1,p2]]
	RealBoardLine = [p1,p2]
	clear_points()
	resetAllLines()
	updateRealRect()
	mode = 'finsh'
	return self

func input(event):
	if KeyboardHandler.state:
		if mode == 'free_draw':
			mode = 'keyboard'
	else:
		if mode == 'keyboard':
			mode = 'free_draw'
			
	if mode == 'keyboard':
		if WV.drawingScreen.LineALignMode == 'y':
			updatePara(KeyboardHandler.number,-90)
		else:
			updatePara(KeyboardHandler.number,0)
		var a = remainder(-rad2deg((points[1]-points[0]).angle())+360,360)
		updateInfoBar(KeyboardHandler.number/10,round(a))
		
		if Input.is_action_just_pressed("ui_accept"):
			finshProcess()
	
	# update end point in free_draw mode
	if mode == 'free_draw':
		LineHeadPos = WV.mousePointer 
		points[-1] = LineHeadPos
		var l = (points[1]-points[0]).length() / WV.scaleFac *.1
		var a = remainder(-rad2deg((points[1]-points[0]).angle())+360,360)
		updateInfoBar(l,a)
			
	# change draw mode
	if Input.is_action_just_pressed("alt"):
		if mode == 'free_draw':
			mode = 'manual'
		elif mode == 'manual':
			mode = 'free_draw'
	
	if mode == 'chooseSeqment':
		chooseSeqment() 
	elif mode == 'erase':
		updateLinePointer()
	
	if boundaryBox:
		boundaryBox.input(event)
		
func updateInfoBar(_length,_angle):
#	var l = (points[1]-points[0]).length() / WV.scaleFac *.1
#	var a = remainder(-rad2deg((points[1]-points[0]).angle())+360,360)
	WV.infoBoard.updateValue('Length',_length)
	WV.drawingScreen.lastPanel.lengthBoard.text = str(abs(_length))
	WV.infoBoard.updateValue('Angle',_angle)
	WV.drawingScreen.lastPanel.angleBoard.text = str(_angle)
	
func updatePoint():
	var vect = Vector2(lineLength*cos(lineAngle),lineLength*sin(lineAngle))+points[0]
	points[-1] = vect

func initiateObject():
	points[0] = WV.mousePointer
	points[1] = WV.mousePointer
	boundaryBox = load(boundaryBoxPath).instance()
	boundaryBox.Father = self
	add_child(boundaryBox)
	
func updateValues(dict):
	boundaryBox.hide()
	mode = 'manual'
	if dict['length'] == '':
		dict['length'] = str((points[0]-points[1]).length()/WV.scaleFac)
	
	updatePara(float(dict['length'])*10,360-float(dict['angle']))
	updateInfoBar(dict['length'],dict['angle'])

func updatePara(_length,_angle):
	lineLength = _length * WV.scaleFac 
	lineAngle = deg2rad(_angle)
	updatePoint()


func eraseMode():
	if mode in ['chooseSeqment','erase']:
		return
	
	WV.drawingScreen.changePaintState('object_edit')
	# restart operation
	erase_OpIndex = 0
	erase_hitPointList.clear()
	# choose seqment if there more than one seqment
	if LineSeqmentVisible.size() > 1:
		mode = 'chooseSeqment'
		lineChooseMark.visible = true
		return
	
	if len(LineSeqmentVisible) == 0:
		ChoosedLine = RealBoardLine
	elif len(LineSeqmentVisible) == 1:
		ChoosedLine = LineSeqmentVisible[0]
	
	initialCuttingOp()

func undoUpdate(_list):
	LineSeqmentVisible = _list[1]
	
	if _list[2] == 1:
		ActionsLisBackup.append(ActionsList.pop_back()) 
	else:
		ActionsList.append(ActionsLisBackup.pop_back())
	
	
	resetAllLines()

func cancelEdit():
	lineChooseMark.visible = false
	cutMarker.visible = false
	pointerIcon.visible = false
	mode = 'finsh'
	

func LineBeenChoosed(seqment):
	ChoosedLine = seqment
	lineChooseMark.visible = false
	initialCuttingOp()

func initialCuttingOp():
	# set rotation of the pointer icon
	pointerIcon.rect_rotation = rad2deg((RealBoardLine[1] - RealBoardLine[0]).angle())
	# unhide the pointer icon
	pointerIcon.visible = true	
	mode = 'erase'
	

# this func return seqment of line with mouse pointer
# projected on 
func chooseSeqment():
	for i in LineSeqmentVisible:
		if checkLine(i[0],i[1],WV.mousePointer/WV.LastScaleBackup):
			lineChooseMark.points[0] = i[0] * WV.LastScaleBackup
			lineChooseMark.points[1] = i[1] * WV.LastScaleBackup
			return i
	
	# reset 'lineChooseMark' position of there seqment
	# mouse pointer project on
	lineChooseMark.points[0] = Vector2.ZERO
	lineChooseMark.points[1] = Vector2.ZERO
	

# this func return if the point project with the line 
func checkLine(line_start, line_end ,point):
	var line_direction = (line_end - line_start).normalized()
	var point_to_start = point - line_start
	var projection_length = point_to_start.dot(line_direction)
	if projection_length < 0:
		return 0
	elif projection_length > line_start.distance_to(line_end):
		return 0
	else:
		return 1


func updateLinePointer():
	# find the projection of mouse pointer on the line seqment
	var l = (ChoosedLine[1] -ChoosedLine[0]).normalized()
	
	var pos = l.dot(WV.mousePointer/ WV.LastScaleBackup - ChoosedLine[0])* l 
	pos =  pos + ChoosedLine[0]

	# check if projection out of the line seqment to snap pointer to endings
	var length = (ChoosedLine[1]-ChoosedLine[0]).length()
	var d1 = ChoosedLine[0].distance_to(pos)
	var d2 = ChoosedLine[1].distance_to(pos)
	if not(d1 < length && d2 < length):
		if d1 < d2:
			pos = ChoosedLine[0]
		else:
			pos = ChoosedLine[1]

	pointerIcon.rect_position = pos * WV.LastScaleBackup
	cutMarker.points[0] = pos * WV.LastScaleBackup


func remainder(num:float ,denum):
	return num-int(num/denum)*denum

func erasingOp():
	Undo.addNewChunk('editObj',[self,LineSeqmentVisible.duplicate(true),1])
	# the seqment which has haded 
	var activeLine
	# define seqmentation mode
	var erase_mode = 'threeSegment' 
	# erase full line seqment
	if ChoosedLine[0] in erase_hitPointList and ChoosedLine[1] in erase_hitPointList:
		erase_mode = 'zeroSegment'
		activeLine = ChoosedLine.duplicate(true)
	
	else:
		for i in ChoosedLine:
			if i in erase_hitPointList:
				erase_mode = 'twoSegment'
	
	var pointsList:Array # line seqment list
	# three seqment
	if erase_mode == 'threeSegment':
		var t = (ChoosedLine[0]-erase_hitPointList[0]).length() <= (ChoosedLine[0]-erase_hitPointList[1]).length() 
		if t:
			pointsList = [ChoosedLine[0],erase_hitPointList[0],erase_hitPointList[1],ChoosedLine[1]]
		else:
			pointsList = [ChoosedLine[0],erase_hitPointList[1],erase_hitPointList[0],ChoosedLine[1]]
			
		# fill 'LineSeqmentVisible' list
		LineSeqmentVisible.append([pointsList[0],pointsList[1]])
		LineSeqmentVisible.append([pointsList[2],pointsList[3]])
		
		activeLine = [pointsList[1],pointsList[2]]
		
	# two seqment
	elif erase_mode == 'twoSegment':
		var middlePnt
		var other
		for i in ChoosedLine:
			if not(i in erase_hitPointList):
				other = i
		for i in erase_hitPointList:
			if not(i in ChoosedLine):
				middlePnt = i
				
		LineSeqmentVisible.append([middlePnt , other])
		activeLine = erase_hitPointList.duplicate(true)
		
	# remove choosed segment
	for i in LineSeqmentVisible:
		if i[0] == ChoosedLine[0] and i[1] == ChoosedLine[1]:
			LineSeqmentVisible.erase(i)
	
	RealBoardLinLength = (RealBoardLine[0]-RealBoardLine[1]).length()
	ActionsList.append([ActionManager.getIndex(),
	getValues(activeLine),
	getValuesFormList(LineSeqmentVisible)])
	updateRealRect()
	finshCutting()
	resetAllLines()
	CheckIntersection.updateSelectBox()
	
func getValues(list):
	var l1 = (list[0]-RealBoardLine[0]).length() / RealBoardLinLength
	var l2 = (list[1]-RealBoardLine[0]).length() / RealBoardLinLength
	return [l1,l2]
	
func getValuesFormList(arr):
	var list = []
	for i in arr: list.append(getValues(i))
	return list


func fieldButton():
	if mode == 'free_draw':
		mode = 'finsh'
		points[-1] = LineHeadPos
		finshProcess()
		
	elif mode == 'keyboard':
		finshProcess()
	elif mode == 'chooseSeqment':
		var seqment = chooseSeqment() 
		if seqment:
			LineBeenChoosed(seqment)
	
	elif mode == 'erase':
		# fill erase-hitPointList with two vector
		if erase_OpIndex <=1:
			# convert to real board coorinatation
			var pnt = pointerIcon.rect_position/WV.LastScaleBackup
			erase_hitPointList.append(pnt)
			# show and set cutmarker position
			cutMarker.points[1] = pointerIcon.rect_position
			cutMarker.visible = true
		# draw hide line
		if erase_OpIndex == 1:
			# start cutting op after filling 'erase_hitPointList'
			erasingOp()
			# hide cutmarker
			cutMarker.visible = false
		erase_OpIndex+=1
		
func finshCutting():
	WV.drawingScreen.changePaintState('select')
	pointerIcon.visible = false
	lineChooseMark.points = [Vector2.ZERO,Vector2.ZERO]
	mode = 'finsh'
	# updateSnap points
	for i in LineSeqmentVisible:
		for j in i:
			snapedPoint.append(j)
		snapedPoint.append((i[0]+i[1])/2)

func finshProcess():
	if points[0] == points[1]:
		WV.drawingScreen.cancel_object()
		return 
	
	boundaryBox.queue_free()
	boundaryBox = false
	# detect drawing type
	if points[0].x == points[1].x:
		DrawingType = 'ruler/vertical'
	elif points[0].y == points[1].y:
		DrawingType = 'ruler/horizantal'
	
	for i in points:
		snapedPoint.append(i/WV.LastScaleBackup)
	snapedPoint.append((snapedPoint[0]+snapedPoint[1])/2)
	WV.allObject.append(self)
	emit_signal("finsh_object")
	mode = 'finsh'

	LineSeqmentVisible = [[0,0]]
	LineSeqmentVisible[0][0] = points[0]/WV.LastScaleBackup
	LineSeqmentVisible[0][1] = points[1]/WV.LastScaleBackup	
	RealBoardLine = LineSeqmentVisible[0].duplicate(true)

	ActionsList.append([ActionManager.getIndex()])
	
	clear_points()
	resetAllLines()
	updateRealRect()
	

func updateRealRect():
	var arr = []
#	for line in linesArr:
#		for pnt in line.points:
#			arr.append(pnt/WV.LastScaleBackup)
	for list in LineSeqmentVisible:
		arr.append(list[0])
		arr.append(list[1])
	realRect = WV.getBoundary(arr)


func changeColor(_newColor):
	for obj in linesArr:
		obj.default_color = _newColor
	

# fired from "Checkintersection.gd" globle script
func deselected():
	pass

# fired from "Checkintersection.gd" globle script
func selected():
	pass

func resetAllLines():
	# delete old lines
	for obj in linesHolder.get_children():
		obj.queue_free()
	
	linesArr.clear()
	for pointList in LineSeqmentVisible:
		linesArr.append(makeNewLine(pointList[0],pointList[1]))
	
	reDraw(WV.LastScaleBackup)

func makeNewLine(_p1,_p2):
	var line = Line2D.new()
	linesHolder.add_child(line)
	line.add_point(_p1)
	line.add_point(_p2)
	line.width = 3
	line.default_color = objectColor
	return line

func updateSnapPnt():
	snapedPoint.clear()
	for i in LineSeqmentVisible:
		snapedPoint.append(i[0])
		snapedPoint.append(i[1])
		snapedPoint.append((i[1]+i[0])/2)
	

func updateScaleVar(_newFactor):
	for i in LineSeqmentVisible.size():
		linesArr[i].points[0] = LineSeqmentVisible[i][0]* _newFactor
		linesArr[i].points[1] = LineSeqmentVisible[i][1]* _newFactor

var linesArr:Array
func reDraw(_newFactor):
	for i in LineSeqmentVisible.size():
		linesArr[i].points[0] = LineSeqmentVisible[i][0] * _newFactor
		linesArr[i].points[1] = LineSeqmentVisible[i][1] * _newFactor

func finshMove(_shift): 
	shiftObj(_shift)
	RealBoardLine[0] = RealBoardLine[0] + _shift
	RealBoardLine[1] = RealBoardLine[1] + _shift
	for i in LineSeqmentVisible.size():
		for j in 2:
			LineSeqmentVisible[i][j] += _shift
	updateRealRect()
	updateSnapPnt()
	

func shiftObj(_shift): 
	for i in LineSeqmentVisible.size():
		for j in 2:
			linesArr[i].points[j] = (LineSeqmentVisible[i][j] + _shift)*WV.LastScaleBackup

	
func applyScale(_vec,_value):
	liveScale(_vec,_value)
	RealBoardLine[0] = (RealBoardLine[0] -_vec) * _value + _vec
	RealBoardLine[1] = (RealBoardLine[1] -_vec) * _value + _vec
	for i in LineSeqmentVisible.size():
		for j in 2:
			LineSeqmentVisible[i][j] = (LineSeqmentVisible[i][j]-_vec)*_value + _vec
	updateRealRect()
	updateSnapPnt()

	
func liveScale(_vec,_value):
	for i in LineSeqmentVisible.size():
		linesArr[i].points[0] =((LineSeqmentVisible[i][0]-_vec)*_value+_vec)*WV.LastScaleBackup
		linesArr[i].points[1] =((LineSeqmentVisible[i][1]-_vec)*_value+_vec)*WV.LastScaleBackup


func liveRotate(_vec,_angle):
	for i in LineSeqmentVisible.size():
		for j in 2:
			linesArr[i].points[j] = ((LineSeqmentVisible[i][j]-_vec).rotated(_angle)+_vec)*WV.LastScaleBackup

func applyRotate(_vec,_angle):
	liveRotate(_vec,_angle)
	for i in 2:
		RealBoardLine[i] = (RealBoardLine[i]-_vec).rotated(_angle) + _vec
	for i in LineSeqmentVisible.size():
		for j in 2:
			LineSeqmentVisible[i][j] = (LineSeqmentVisible[i][j]-_vec).rotated(_angle) + _vec
	updateRealRect()
	updateSnapPnt()
