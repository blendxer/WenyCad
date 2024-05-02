extends Control

signal finsh_object
var objectType = 'lengthLabel'
var DrawingType = 'measurement'
var snapedPoint:Array
var objectColor 
var LayerId

onready var DashLine1 = $dashLine1
onready var DashLine2 = $dashLine2
onready var DashLine3 = $dashLine3
onready var DashLine4 = $dashLine4

onready var HeadPointer1 = $head1
onready var HeadPointer2 = $head2
onready var HeadPointer1Poly = $head1/Polygon2D
onready var HeadPointer2Poly = $head2/Polygon2D
onready var label = $labelHolder/Label
onready var LabelHoder = $labelHolder

var OpIndex=0
var MeasureMode = 'length'

var ActionsList:Array


# measure line length
var Length_Points:Array = [0,0]
var LineAngle=0
var LineLength = 0
var LineVec:Vector2
var SelectedFunc='LineInnerDraw'
var CurrentLineMode = 'small'
var MinDisToSwitch = 60.0

# measure angle
var angle_Points = [0,0,0]
var angle_angle=0

const sizeConst = 1
var ShiftState:bool
var RealLength_Points:Array=[Vector2(),Vector2()]
var realDashLinePosList:Array
var realAnglePnts:Array
var realLength
var realAngleLabelPos:Vector2
var realRect:Rect2
var digit = 8

func copy():
	var dict = {}
	dict['objectType'] = objectType
	dict['DrawingType'] = DrawingType
	dict['LayerId'] = LayerId
	dict['MeasureMode'] = MeasureMode
	dict['ActionsList'] = ActionsList
	
	if MeasureMode == 'length':
		dict['RealLength_Points'] = RealLength_Points
		dict['realLength'] = realLength
		dict['realDashLinePosList'] = realDashLinePosList
		dict['ShiftState'] = ShiftState
	
	elif MeasureMode == 'angle':
		dict['realAnglePnts'] = realAnglePnts
		dict['realAngleLabelPos'] = realAngleLabelPos
	
	return dict

func paste(dict):
	objectType = dict['objectType']
	DrawingType = dict['DrawingType']
	LayerId = dict['LayerId']
	MeasureMode = dict['MeasureMode']
	ActionsList.append(WV.drawingScreen.IndexSequenceDict[dict['ActionsList'][0]])
	
	if MeasureMode == 'length':
		ShiftState = dict['ShiftState']
		realLength = dict['realLength']
		RealLength_Points[0] = dict['RealLength_Points'][0]
		RealLength_Points[1] = dict['RealLength_Points'][1]
		if ShiftState:
			realDashLinePosList = dict['realDashLinePosList'].duplicate()
			DashLine3.add_point(Vector2())
			DashLine3.add_point(Vector2())
			DashLine4.add_point(Vector2())
			DashLine4.add_point(Vector2())
		updateRealRectLabel()
	
	if MeasureMode == 'angle':
		HeadPointer1.hide()
		HeadPointer2.hide()
		realAnglePnts = dict['realAnglePnts'].duplicate()
		realAngleLabelPos = dict['realAngleLabelPos']
		DashLine1.add_point(Vector2())
		for i in realAnglePnts.size():
			angle_Points[i] = realAnglePnts[i] * WV.LastScaleBackup
		updataAnglePrt2()
		
	WV.allObject.append(self)
	OpIndex = 100
	
	var c = LayerManager.LayerPanel.layerIdDict[LayerId].LayerColor
	changeColor(c)
	objectColor = c

# warning-ignore:unused_argument
func input(event):
	if MeasureMode == 'length':
		if OpIndex==1:
			Length_Points[1] = WV.mousePointer
			RealLength_Points[1] = WV.mousePointer/WV.LastScaleBackup
			realLength = (RealLength_Points[1] - RealLength_Points[0]).length() 
			updateDashLine1()
		
		elif OpIndex==2:
			updateLineLengthPrt1()

	if MeasureMode == 'angle':
		if OpIndex == 1:
			angle_Points[1] = WV.mousePointer
			updataAnglePrt1()
		elif OpIndex == 2:
			angle_Points[2] = WV.mousePointer
			updataAnglePrt2()
		
func initiateObject():
	# grab measurement type 
	MeasureMode = WV.drawingScreen.SubtypePanel.measureType
	if MeasureMode == 'length':
		OpIndex+=1
		Length_Points[0]= WV.mousePointer
		RealLength_Points[0] = WV.mousePointer/WV.LastScaleBackup
		HeadPointer1.rect_position = Length_Points[0]
		
	if MeasureMode == 'angle':
		HeadPointer1.hide()
		HeadPointer2.hide()
		angle_Points[0] = WV.mousePointer
		DashLine1.points[0] = angle_Points[0]
		DashLine1.points[1] = angle_Points[0]
		OpIndex+=1


func fieldButton():
	if MeasureMode == 'length':
		if OpIndex == 1:
			# the end line point posititon
			if Input.is_action_pressed("alt"): # extra setting
				DashLine3.add_point(Length_Points[0])
				DashLine3.add_point(Length_Points[0])
				DashLine4.add_point(Length_Points[1])
				DashLine4.add_point(Length_Points[1])
				ShiftState = true
			
			else: 
				Length_Points[1] = WV.mousePointer
				RealLength_Points[1] = WV.mousePointer/WV.LastScaleBackup
				OpIndex = 100
				finshProcess()
				
		if OpIndex == 2:
				OpIndex = 100
				finshProcess()
		OpIndex+=1
		
	if MeasureMode == 'angle':
		if OpIndex == 1:
			angle_Points[1] = WV.mousePointer
			updataAnglePrt1()
			DashLine1.add_point(WV.mousePointer)
		elif OpIndex ==2:
			angle_Points[2] = WV.mousePointer
			angle_Points[0] = DashLine1.points[0]
			realAngleLabelPos = LabelHoder.rect_position/WV.LastScaleBackup
			finshProcess()
			
		OpIndex+=1

###########################
######### measure angle

func updataAnglePrt1():
	DashLine1.points[1] = angle_Points[1]

func updataAnglePrt2():
	var vec1 = (angle_Points[0] - angle_Points[1]).normalized()
	var vec2 = (angle_Points[2] - angle_Points[1]).normalized()
	
	# upadate dash line
	var line2Length = (angle_Points[2] - angle_Points[1]).length()
	DashLine1.points[2] = angle_Points[2]
	DashLine1.points[0] = angle_Points[1] + line2Length * vec1
	
	
	# calculate angle
	angle_angle = vec1.angle_to(vec2)
	
	# update label text and position
	label.text = str(rad2deg(abs(angle_angle))).substr(0,digit)
	var pos = 50 * (vec1 + vec2).normalized()
	LabelHoder.rect_position = angle_Points[1] + pos 
	



###########################
######### measure distance
func updateDashLine1():
	# Update variable
	LineAngle = rad2deg((Length_Points[1]-Length_Points[0]).angle())
	LineLength = (Length_Points[0]-Length_Points[1]).length()
	LineVec = (Length_Points[1]-Length_Points[0]).normalized()

	# check line Mode
	var newMode = ['LineInnerDraw','lineOuterDraw'][int(LineLength>=MinDisToSwitch+30)]
	if CurrentLineMode != newMode:
		CurrentLineMode = newMode
		SelectedFunc    = newMode

	# update pointer position
	HeadPointer1.rect_position = Length_Points[0]
	HeadPointer2.rect_position = Length_Points[1]

	label.text = str(realLength).substr(0,digit)
	LabelHoder.rect_position = (Length_Points[0]+Length_Points[1])/2
	
	
	# call the selected func
	call(SelectedFunc)

func updateLineLengthPrt1():
	var vec = LineVec.rotated(PI/2)
	var vec2 = WV.mousePointer - Length_Points[1]
	
	var dot = vec.dot(vec2)
	var p1 = Length_Points[1] + dot * vec
	var p2 = p1 + Length_Points[0]-Length_Points[1]
	HeadPointer2.rect_position = p1
	HeadPointer1.rect_position = p2
	RealLength_Points[0] = p1 / WV.LastScaleBackup
	RealLength_Points[1] = p2 / WV.LastScaleBackup
	
	alignBody(p2,p1)
	LabelHoder.rect_position = (DashLine4.points[1]+DashLine3.points[1])/2
	
	var shift = 20 *vec * sign(dot)
	DashLine4.points[1] = p1 + shift
	DashLine3.points[1] = p2 + shift

func LineInnerDraw():
	HeadPointer1.rect_rotation = LineAngle 
	HeadPointer2.rect_rotation = LineAngle +180
	
	DashLine1.points[0] = Length_Points[0]
	DashLine1.points[1] = Length_Points[0] +30 * -LineVec
	
	DashLine2.points[0] = Length_Points[1]
	DashLine2.points[1] = Length_Points[1] +30 * LineVec


func lineOuterDraw():
	HeadPointer1.rect_rotation = LineAngle + 180
	HeadPointer2.rect_rotation = LineAngle 
	alignBody(Length_Points[0],Length_Points[1])

func alignBody(p1,p2):
	var halfLine = (LineLength)/2 - MinDisToSwitch/2
	DashLine1.points[0] = p1
	DashLine1.points[1] = p1 + halfLine * LineVec
	DashLine2.points[0] = p2
	DashLine2.points[1] = p2 + halfLine * -LineVec


# fired from "Checkintersection.gd" globle script
func deselected():
	pass

# fired from "Checkintersection.gd" globle script
func selected():
	pass


func updateDigitCount(_cnt):
	digit = _cnt
	if MeasureMode == 'length':
		updateDashLine1()
	elif MeasureMode == 'angle':
		updataAnglePrt2()
	reDraw(WV.LastScaleBackup)

func finshProcess():
	WV.allObject.append(self)
	ActionsList.append(ActionManager.getIndex())
	emit_signal("finsh_object")
	if MeasureMode == 'length':
		if ShiftState:
			realDashLinePosList.append(DashLine3.points[0]/WV.LastScaleBackup)
			realDashLinePosList.append(DashLine3.points[1]/WV.LastScaleBackup)
			realDashLinePosList.append(DashLine4.points[0]/WV.LastScaleBackup)
			realDashLinePosList.append(DashLine4.points[1]/WV.LastScaleBackup)
		updateRealRectLabel()
		
	elif MeasureMode == 'angle':
		realAnglePnts.append(angle_Points[0]/WV.LastScaleBackup)
		realAnglePnts.append(angle_Points[1]/WV.LastScaleBackup)
		realAnglePnts.append(angle_Points[2]/WV.LastScaleBackup)
		realRect = getBoundary(realAnglePnts)
	

func updateRealRectLabel():
	var dumpList = RealLength_Points.duplicate()
	if ShiftState:
		dumpList.append_array(realDashLinePosList)
	realRect = WV.getBoundary(dumpList)

func updateRealRectAngle():
	realRect = getBoundary(realAnglePnts)
	
func getBoundary(list):
	var min_ = Vector2(INF,INF)
	var max_ = Vector2(-INF,-INF)
	
	for pnt in list:
		if pnt.x < min_.x:
			min_.x = pnt.x
		if pnt.x > max_.x:
			max_.x = pnt.x
		if pnt.y < min_.y:
			min_.y = pnt.y
		if pnt.y > max_.y:
			max_.y = pnt.y
			
	return Rect2(min_,max_-min_)
	
func changeColor(_newColor:Color):
	DashLine1.default_color = _newColor
	DashLine2.default_color = _newColor
	DashLine3.default_color = _newColor
	DashLine4.default_color = _newColor
	HeadPointer1Poly.color = _newColor
	HeadPointer2Poly.color = _newColor
	label.self_modulate = _newColor


func updateScaleVar(_newFactor): 
	if MeasureMode == 'length':
		Length_Points[0] = RealLength_Points[0]*_newFactor
		Length_Points[1] = RealLength_Points[1]*_newFactor
		if ShiftState:
			DashLine3.points[0] = realDashLinePosList[0]*_newFactor
			DashLine3.points[1] = realDashLinePosList[1]*_newFactor
			DashLine4.points[0] = realDashLinePosList[2]*_newFactor
			DashLine4.points[1] = realDashLinePosList[3]*_newFactor
		updateDashLine1()
	else:
		DashLine1.points[0] = realAnglePnts[0] * _newFactor
		DashLine1.points[1] = realAnglePnts[1] * _newFactor
		DashLine1.points[2] = realAnglePnts[2] * _newFactor
		LabelHoder.rect_position = realAngleLabelPos * _newFactor

func reDraw(_newFactor): # zoom in out 
	if MeasureMode == 'length':
		Length_Points[0] = RealLength_Points[0]*_newFactor
		Length_Points[1] = RealLength_Points[1]*_newFactor
		if ShiftState:
			DashLine3.points[0] = realDashLinePosList[0]*_newFactor
			DashLine3.points[1] = realDashLinePosList[1]*_newFactor
			DashLine4.points[0] = realDashLinePosList[2]*_newFactor
			DashLine4.points[1] = realDashLinePosList[3]*_newFactor
		updateDashLine1()
	else:
		DashLine1.points[0] = realAnglePnts[0] * _newFactor
		DashLine1.points[1] = realAnglePnts[1] * _newFactor
		DashLine1.points[2] = realAnglePnts[2] * _newFactor
		LabelHoder.rect_position = realAngleLabelPos * _newFactor
		
func finshMove(_shift): # apply shift
	shiftObj(_shift)
	if MeasureMode == 'length':
		RealLength_Points[0] +=_shift
		RealLength_Points[1] +=_shift
		for i in realDashLinePosList.size():
			realDashLinePosList[i] += _shift
		updateRealRectLabel()
	else:
		for i in realAnglePnts.size():
			realAnglePnts[i] += _shift
		realAngleLabelPos+=_shift
		updateRealRectAngle()
	
func shiftObj(_shift):  # live shift
	if MeasureMode == 'length':
		Length_Points[0] = (RealLength_Points[0]+_shift)*WV.LastScaleBackup
		Length_Points[1] = (RealLength_Points[1]+_shift)*WV.LastScaleBackup
		if ShiftState:
			DashLine3.points[0] = (realDashLinePosList[0]+_shift)*WV.LastScaleBackup
			DashLine3.points[1] = (realDashLinePosList[1]+_shift)*WV.LastScaleBackup
			DashLine4.points[0] = (realDashLinePosList[2]+_shift)*WV.LastScaleBackup
			DashLine4.points[1] = (realDashLinePosList[3]+_shift)*WV.LastScaleBackup
		updateDashLine1()
	else:
		DashLine1.points[0] = (realAnglePnts[0]+_shift)* WV.LastScaleBackup
		DashLine1.points[1] = (realAnglePnts[1]+_shift)* WV.LastScaleBackup
		DashLine1.points[2] = (realAnglePnts[2]+_shift)* WV.LastScaleBackup
		LabelHoder.rect_position = (realAngleLabelPos+_shift) * WV.LastScaleBackup

func applyScale(_vec,_value):
	WV.makeAd('8')
	

func liveScale(_vec,_value):
	pass

func liveRotate(_vec,_angle):
	pass
func applyRotate(_vec,_angle):
	WV.makeAd('22')




