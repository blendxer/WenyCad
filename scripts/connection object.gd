extends Line2D

signal finsh_object
var objectType = 'bezier'
var DrawingType = 'bezier'
var objectColor = Color('f360ff')
var LayerId
var snapedPoint:Array = []
var ActionsList:Array = []

onready var line1 = $Line1
onready var line2 = $line2

var mode = 'free_draw'
var curvePoints:Array=[Vector2.ZERO,Vector2.ZERO,Vector2.ZERO,Vector2.ZERO,]
var curveInst:Array
var selectedJointIndex
var selectedJointState:bool=false

var curveRes = 16
var stateIndex:= 0
var minSelectJointDis = 10
var FollowerShift:Vector2
var FollowerIndex:int
var LastClickTime:int

var realCurvePoints:Array
var pointsRealPos:Array = [[]]
var realRect:Rect2


func copy():
	var dict = {}
	dict['objectType'] = 'bezier'
	dict['DrawingType'] = DrawingType
	dict['LayerId'] = LayerId
	dict['snapPnts'] = snapedPoint
	dict['pointsRealPos'] = pointsRealPos
	dict['ActionsList'] = ActionsList
	return dict

func paste(dict):
	objectType = 'bezier'
	DrawingType = dict['DrawingType']
	LayerId = dict['LayerId']
	snapedPoint = dict['snapPnts'].duplicate()
	pointsRealPos = dict['pointsRealPos'].duplicate(true)
	WV.allObject.append(self)
	var v = WV.drawingScreen.IndexSequenceDict[dict['ActionsList'][0][0]]
	ActionsList.append([v])
	realRect = WV.getBoundary(pointsRealPos[0])
	var c = LayerManager.LayerPanel.layerIdDict[LayerId].LayerColor
	changeColor(c)
	objectColor = c
	
	stateIndex = -1
	cancelAndFinsh()
	mode ='finsh'
	for i in curveRes:
		add_point(pointsRealPos[0][i] * WV.LastScaleBackup)

func input(event):
	if stateIndex ==0:
		points[1] = WV.mousePointer
		
	if stateIndex == 1:
		if event is InputEventMouseButton:
			if  event.button_index ==1:
				if event.pressed:
					checkMove()
				else:
					selectedJointState = false
	
		if selectedJointState:
			curvePoints[selectedJointIndex] = WV.mousePointer
			if FollowerIndex:
				curvePoints[FollowerIndex] = (WV.mousePointer + FollowerShift)
			# update circles positiion
			updateCirclePos()
			# update curve 
			buildBezier()

func checkMove():
	# check select one joint or not
	var minimalDis = INF
	FollowerIndex =0
	for i in curvePoints.size():
		var dis = (WV.mousePointer-curvePoints[i]).length()
		if dis < minSelectJointDis and dis < minimalDis:
			minimalDis = dis
			selectedJointIndex = i
			FollowerIndex = i
			
	if minimalDis != INF:
		selectedJointState = true
		if FollowerIndex in [0,3]:
			FollowerIndex += -2*int(FollowerIndex==3)+1
			FollowerShift = curvePoints[FollowerIndex] - curvePoints[selectedJointIndex]
		else:
			FollowerIndex =0
			
func buildBezier():
	for i in curveRes:
		var fac = float(i)/(curveRes-1)
		points[i] = getPoint(fac)
		pointsRealPos[0][i] = points[i]/WV.LastScaleBackup

func getPoint(fac):
	var a1 = lerp(curvePoints[0],curvePoints[1],fac)
	var a2 = lerp(curvePoints[1],curvePoints[2],fac)
	var a3 = lerp(curvePoints[2],curvePoints[3],fac)
	return lerp(lerp(a1,a2,fac),lerp(a2,a3,fac),fac)

func updateCirclePos():
	for i in 4:
		curveInst[i].rect_position = curvePoints[i]
	line1.points[0] = curvePoints[0]
	line1.points[1] = curvePoints[1]
	line2.points[0] = curvePoints[2]
	line2.points[1] = curvePoints[3]

func firstBuild():
	curvePoints[0] = points[0]
	curvePoints[3] = points[1]
	var vect = (points[1] - points[0])/3
	curvePoints[1] = points[0] + vect
	curvePoints[2] = points[0] + vect * 2
	for i in 4:
		realCurvePoints.append(curvePoints[i]/WV.LastScaleBackup)
	clear_points()
	line1.points[0] = curvePoints[0]
	line1.points[1] = curvePoints[1]
	line2.points[0] = curvePoints[2]
	line2.points[1] = curvePoints[3]
	for i in curvePoints:
		var father = Control.new()
		add_child(father)
		father.rect_position = i
		drawCircle(5,Vector2.ZERO,father)
		curveInst.append(father)
	for i in curveRes:
		var fac = float(i)/(curveRes-1)
		var p = curvePoints[0]+3*fac*vect
		add_point(p)
		pointsRealPos[0].append(p/WV.LastScaleBackup)

# warning-ignore:unused_argument
func updateValues(dict):
	pass

func initiateObject():
	add_point(WV.mousePointer)
	add_point(WV.mousePointer)
	
func fieldButton():
	if stateIndex ==0:
		points[1] = WV.mousePointer
		firstBuild()
		stateIndex+=1
	elif stateIndex==1:
		if Time.get_ticks_msec()-LastClickTime < 200:
			finshObject()
		LastClickTime = Time.get_ticks_msec()

func finshObject():
	snapedPoint.append(pointsRealPos[0][0])
	snapedPoint.append(pointsRealPos[0][-1])
	stateIndex = -1
	cancelAndFinsh()
	mode ='finsh'
	ActionsList.append([ActionManager.getIndex()])
	WV.allObject.append(self)
	realRect = WV.getBoundary(pointsRealPos[0])
	emit_signal("finsh_object")
	
func cancelAndFinsh():
	line1.queue_free()
	line2.queue_free()
	for i in curveInst:
		i.queue_free()

# fired from "Checkintersection.gd" globle script
func deselected():
	pass

# fired from "Checkintersection.gd" globle script
func selected():
	pass



func drawCircle(radius:int,pos ,father):
	var circleReslution:float = 15
	var circleInstance = Polygon2D.new()
	father.add_child(circleInstance)
	var fraction:float
# warning-ignore:unassigned_variable
	var list:Array
	for index in circleReslution:
		fraction = index/circleReslution
		var vec = polar2cartesian(radius,TAU*fraction)
		list.append(vec+pos)
	circleInstance.polygon = list
	return circleInstance

func changeColor(_newColor):
	default_color = _newColor

func updateScaleVar(_newFactor):
	for i in curveRes:
		points[i] = pointsRealPos[0][i] * _newFactor

func reDraw(_newFactor):
	for i in curveRes:
		points[i] = pointsRealPos[0][i] * _newFactor

func finshMove(_shift):
	shiftObj(_shift)
	for i in curveRes:
		points[i] = position + points[i]
		pointsRealPos[0][i] = points[i]/WV.LastScaleBackup
	position = Vector2()
	realRect = WV.getBoundary(pointsRealPos[0])
	snapedPoint[0] = pointsRealPos[0][0]
	snapedPoint[1] = pointsRealPos[0][-1]

func shiftObj(_shift):
	position = _shift * WV.LastScaleBackup

func applyScale(_vec,_value):
	liveScale(_vec,_value)
	for i in curveRes:
		pointsRealPos[0][i] = points[i]/WV.LastScaleBackup
	realRect = WV.getBoundary(pointsRealPos[0])
	snapedPoint[0] = pointsRealPos[0][0]
	snapedPoint[1] = pointsRealPos[0][-1]
	
func liveScale(_vec,_value):
	for i in curveRes:
		points[i] =  ((pointsRealPos[0][i]-_vec)*_value+_vec)* WV.LastScaleBackup

func applyRotate(_vec,_angle):
	liveRotate(_vec,_angle)
	for i in curveRes:
		pointsRealPos[0][i] = points[i]/WV.LastScaleBackup
	realRect = WV.getBoundary(pointsRealPos[0])
	snapedPoint[0] = pointsRealPos[0][0]
	snapedPoint[1] = pointsRealPos[0][-1]
	
	
	
func liveRotate(_vec,_angle):
	for i in curveRes:
		points[i] = ((pointsRealPos[0][i]-_vec).rotated(_angle)+_vec)* WV.LastScaleBackup






