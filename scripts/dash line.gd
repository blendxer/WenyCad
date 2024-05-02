extends Line2D

signal finsh_object
var objectType = 'straight_line'
var DrawingType = 'dash'
var objectColor = Color('66ffe2')
var Id


onready var pointerIcon = $pointer
onready var hideLineHolder = $"hide line holder"
onready var lineChooseMark = $"line choose mark"
onready var cutMarker = $"cut marker"

var mode = 'free_draw'
var lineLength:float
var lineAngle:float
var snapedPoint:Array

var LineSeqment:Array # contain all seqment
var LineSeqmentVisible:Array # contain only visible seqment
var ChoosedLine:Array

# erase variable
var erase_OpIndex=0
var erase_hitPointList:Array 

var DashLine = [3,3]

func _ready():
	# global setting
	WV.firstObjectHitPnt = WV.mousePointer

func _input(event):
	# update end point in free_draw mode
	if mode == 'free_draw':
		points[-1] = WV.mousePointer
	
	# cancel object update
#	if mode != 'finsh':
#		if Input.is_action_just_pressed('escape'):
#			cancelObject()
#
#	if not Input.is_action_pressed("shift"):
#		if event is InputEventMouseButton:
#			if event.pressed and event.button_index ==2:
#				cancelObject()
	
	# change draw mode
	if Input.is_action_just_pressed("space"):
		if mode == 'free_draw':
			mode = 'manual'
		elif mode == 'manual':
			mode = 'free_draw'
	
	if mode == 'chooseSeqment':
		var seqment = chooseSeqment() 
		if seqment:
			if event is InputEventMouseButton:
				if event.pressed and event.button_index ==1:
					LineBeenChoosed(seqment)


	elif mode == 'erase':
		# update pointer position
		updateLinePointer()
		if event is InputEventMouseButton:
			if event.pressed and event.button_index ==1:
				
				# fill erase-hitPointList with two vector
				if erase_OpIndex <=1:
					erase_hitPointList.append(pointerIcon.rect_position)
					
					# show and set cutmarker position
					cutMarker.points[0] = pointerIcon.rect_position
					cutMarker.visible = true
					
				# draw hide line
				if erase_OpIndex == 1:
					# start cutting op after filling 'erase_hitPointList'
					cuttingOp()
					# hide cutmarker
					cutMarker.visible = false
				
				erase_OpIndex+=1
			

func updatePoint():
	var vect = Vector2(lineLength*cos(lineAngle),lineLength*sin(lineAngle))+points[0]
	points[-1] = vect

func initiateObject():
	add_point(WV.mousePointer)
	add_point(WV.mousePointer)

func updateValues(dict):
	mode = 'manual'
	if dict['length'] == '':
		dict['length'] = str((points[0]-points[1]).length()/WV.scaleFac)
	lineLength = float(dict['length']) *WV.scaleFac
	lineAngle = deg2rad(360-float(dict['angle']))
	
	if abs(lineAngle) in [PI/2 , 3*PI/2]:
		DrawingType = 'dash/vertical'
		
	elif abs(lineAngle) in [2*PI, 0 , PI]:
		DrawingType = 'dash/horizantal'
		
	updatePoint()

func eraseMode():
	# restart operation
	erase_OpIndex = 0
	erase_hitPointList.clear()
	# choose seqment if there more than one seqment
	if LineSeqmentVisible.size() > 1:
		mode = 'chooseSeqment'
		lineChooseMark.visible = true
		return
	
	if len(LineSeqmentVisible) == 0:
		ChoosedLine = points
	elif len(LineSeqmentVisible) == 1:
		ChoosedLine = LineSeqmentVisible[0]
	
	initialCuttingOp()


func LineBeenChoosed(seqment):
	ChoosedLine = seqment
	lineChooseMark.visible = false
	initialCuttingOp()

func initialCuttingOp():
	# set rotation of the pointer icon
	pointerIcon.rect_rotation = rad2deg((points[1] -points[0]).angle())
	# unhide the pointer icon
	pointerIcon.visible = true	
	mode = 'erase'
	

# this func return seqment of line with mouse pointer
# projected on 
func chooseSeqment():
	for i in LineSeqmentVisible:
		if checkLine(i[0],i[1],WV.mousePointer):
			lineChooseMark.points[0] = i[0]
			lineChooseMark.points[1] = i[1]
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
	var pos = l.dot(WV.mousePointer - ChoosedLine[0])* l + ChoosedLine[0]

	# check if projection out of the line seqment to snap pointer to endings
	var length = (ChoosedLine[1]-ChoosedLine[0]).length()
	var d1 = ChoosedLine[0].distance_to(pos)
	var d2 = ChoosedLine[1].distance_to(pos)
	if not(d1 < length && d2 < length):
		if d1 < d2:
			pos = ChoosedLine[0]
		else:
			pos = ChoosedLine[1]

	pointerIcon.rect_position = pos
	cutMarker.points[1] = pos


func cuttingOp():
	# define seqmentation mode
	var erase_mode = 'three_seqment'
	for i in ChoosedLine:
		if i in erase_hitPointList:
			erase_mode = 'two_seqment'
	
	# the seqment which has haded 
	var activeLine
	
	var pointsList:Array # line seqment list
	# three seqment
	if erase_mode == 'three_seqment':
		var t = (ChoosedLine[0]-erase_hitPointList[0]).length() <= (ChoosedLine[0]-erase_hitPointList[1]).length() 
		if t:
			pointsList = [ChoosedLine[0],erase_hitPointList[0],erase_hitPointList[1],ChoosedLine[1]]
		else:
			pointsList = [ChoosedLine[0],erase_hitPointList[1],erase_hitPointList[0],ChoosedLine[1]]
			
		# fill 'LineSeqmentVisible' list
		LineSeqmentVisible.append([pointsList[0],pointsList[1]])
		LineSeqmentVisible.append([pointsList[2],pointsList[3]])
		
		
		activeLine = [pointsList[1],pointsList[2]]
		
		LineSeqment.append([pointsList[0],pointsList[1]])
		LineSeqment.append([pointsList[2],pointsList[3]])

	# two seqment
	elif erase_mode == 'two_seqment':

		var middlePnt
		for i in erase_hitPointList:
			if not(i in ChoosedLine):
				middlePnt = i
		
		var edgePnt
		for i in ChoosedLine:
			if not(i in erase_hitPointList):
				edgePnt = i
		
		var otherEgdePnt
		for i in erase_hitPointList:
			if i in ChoosedLine:
				otherEgdePnt = i
				break
		
		LineSeqmentVisible.append([middlePnt , edgePnt])
		LineSeqment.append([middlePnt , edgePnt])
		
		activeLine = [otherEgdePnt , middlePnt]
		
	# remove old seqment
	var dump = LineSeqmentVisible
	for i in dump:
		if i[0] == ChoosedLine[0] and i[1] == ChoosedLine[1]:
			var l = LineSeqmentVisible.size()
			LineSeqmentVisible.erase(i)
			if LineSeqmentVisible.size() == l:
				print('no remove Visible')
	
	dump = LineSeqment
	for i in dump:
		if i[0] == ChoosedLine[0] and i[1] == ChoosedLine[1]:
			var l = LineSeqment.size()
			LineSeqment.erase(i)
			if LineSeqment.size() == l:
				print('no remove lineSeqment')
	
	# make action
	var dict:Dictionary
	dict['DrawingType'] = 'erase/line'
	dict['instance'] = self
	dict['id'] = Id
	dict['lineSeqment/twoLayer'] = LineSeqment.duplicate(true)
	dict['activeSeqment/oneLayer'] = activeLine.duplicate(true)
	ActionManager.add_erase_action(dict)
	
	
	# draw hide line 
	var hideLine = load('res://scenes/drawing side/randoms/hide line.tscn').instance()
	hideLineHolder.add_child(hideLine)
	hideLine.add_point(erase_hitPointList[0])
	hideLine.add_point(erase_hitPointList[1])
	
	finshCutting()

func eraseAllLine():
	pass

func fieldButton():
	mode = 'finsh'
	points[-1] = WV.mousePointer
	finshProcess()

func finshCutting():
	pointerIcon.visible = false
	lineChooseMark.points = [Vector2.ZERO,Vector2.ZERO]
	mode = 'finsh'
	# updateSnap points
	for i in LineSeqmentVisible:
		for j in i:
			WV.snapPoints.append(j)
			snapedPoint.append(j)

func finshProcess():
	LineSeqment = [points]
	for i in points:
		WV.snapPoints.append(i)
		snapedPoint.append(i)
	WV.allObject.append(self)
	emit_signal("finsh_object")
	mode = 'finsh'
	
	
	# divide line
	var lineLen = (points[0]-points[1]).length() 
	var totalLen = DashLine[0] + DashLine[1]
	
	var seqCnt = lineLen/totalLen
	var extraSpaceUnit = float(lineLen - int(seqCnt)*totalLen)/( int(seqCnt))
	
	var vec = (points[1]-points[0]).normalized()
	
	var linesList:Array
	for i in int(seqCnt):
		var l = i * totalLen 
		var fac = float(i)/(int(seqCnt)-1)
		l = l + i * extraSpaceUnit + fac* DashLine[1]
		var start = (l * vec) + points[0]
		var end = (l+DashLine[0]) * vec + points[0]
		linesList.append([start,end])
	
	# action job
	var dict:Dictionary
	dict['DrawingType'] = DrawingType
	dict['points/oneLayer'] = linesList
	dict['instance'] = self
	
	ActionManager.add_action(dict)
	
func delete():
	ActionManager.remove_action(Id)


