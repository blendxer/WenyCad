extends Control

# general 
signal finsh_object
var objectType = 'ruler6030'
var DrawingType = 'ruler6030'
var Id
var snapedPoint:Array
var LayerId
var objectColor 


var DotPoly
var Mode = ''
var Points = [Vector2(),Vector2()]

# ruler 
onready var RulerHolder = $ruler

# ruler line
onready var TriangleLine = $"ruler/ruler line"
onready var TriangleRuler = $ruler
onready var DrawLine = $ruler/drawLine
const ConstHypotenuse = 300
var ConstAdjacentLeg = ConstHypotenuse * cos(PI/6)
var ConstOppositeLeg = ConstHypotenuse * sin(PI/6)

# set direction 
var SetDir_FirstHitPnt:Vector2
var SetDir_LastHitPnt:Vector2
var SetDir_Direction:Vector2
var SetDir_DirectionNor:Vector2 # is SetDir_Direction.normalized
var SetDir_Rot
# SetDir_OpIndex =0  default
# SetDir_OpIndex =1 setting SetDir_LastHitPnt
var SetDir_OpIndex=1

# draw Line
var DrawLine_points:Array = [Vector2.ZERO,Vector2.ZERO]
var RulerAngle = PI/6
var UpdateValuesBackup=false
var AngleIs30 = 30

# dash line
onready var DashLine1 = $dashLine
onready var DashLine2 = $dashLine2


# global setting
var FollowMouseState = false


func _ready():
	drawCircle(3 ,Vector2.ZERO)
	for i in 4:
		TriangleLine.add_point(Vector2(0,0))
	
	
# warning-ignore:unused_argument
func input(event):
	if FollowMouseState:
		trackMouseOp()
#	if Input.is_action_just_pressed("ui_accept"):
#		finshProcess()
	
func trackMouseOp():
	var mouseVec = WV.mousePointer - SetDir_LastHitPnt
	var dot = SetDir_DirectionNor.dot(mouseVec)
	var pos = SetDir_LastHitPnt + dot * SetDir_DirectionNor
	RulerHolder.rect_position = pos - TriangleLine.points[2].rotated(deg2rad(RulerHolder.rect_rotation))
	
	# dash line 2 update
	DashLine2.points[0] = pos
	DashLine2.points[1] = WV.mousePointer
	
func initiateObject():
	# initial setting
	SetDir_FirstHitPnt = WV.mousePointer

func fieldButton():
	if SetDir_OpIndex == 1:
		# time to show triangle
		drawTriangle()
		
		# save step variable
		SetDir_LastHitPnt = WV.mousePointer
		SetDir_Direction = SetDir_LastHitPnt - SetDir_FirstHitPnt
		SetDir_DirectionNor = SetDir_Direction.normalized()
		SetDir_Rot = SetDir_Direction.angle()
		RulerHolder.rect_rotation = rad2deg(SetDir_Rot)
		
		# set dash line 1 position
		DashLine1.points[0] = SetDir_FirstHitPnt + 1000 * SetDir_DirectionNor
		DashLine1.points[1] = SetDir_FirstHitPnt - 1000 * SetDir_DirectionNor
		
		# finsh settting of  this stage
		SetDir_OpIndex +=1

	if SetDir_OpIndex > 0:
		trackMouseOp()
		FollowMouseState = !FollowMouseState
		DashLine2.visible = FollowMouseState
		
func flipAxis1():
	for i in 4:
		TriangleLine.points[i].x = -TriangleLine.points[i].x
	updateValues(UpdateValuesBackup)

func flipAxis2():
	for i in 4:
		TriangleLine.points[i].y = -TriangleLine.points[i].y
	updateValues(UpdateValuesBackup)

func drawTriangle():
	TriangleLine.points[1].y = -ConstOppositeLeg
	TriangleLine.points[2].x = ConstAdjacentLeg
	
	
func switchAngle(newAngle):
	# 'newAngle' is opposite 
	# 'newAngle' is equal to 30 when the newAngle is equal to 60
	AngleIs30 = newAngle != 30
	newAngle = deg2rad(newAngle)
	RulerAngle = newAngle
	ConstAdjacentLeg = ConstHypotenuse * sin(newAngle)
	ConstOppositeLeg = ConstHypotenuse * cos(newAngle)
	drawTriangle()
	updateValues(UpdateValuesBackup)

func updateValues(_dict):
	# if _dict=false mean not get and _dict from panel yet
	if not(_dict):
		return
	
	var text1 = _dict['start']
	var text2 = _dict['end']
	
	if text1.empty() and text2.empty():
		WV.makeAd('13')
		return
	elif text1.empty() or text2.empty():
		Mode = 'dot'
	else:
		Mode = 'line'
	
	var values = [float(text1),float(text2)]
	var max_ = max(values[0],values[1]) * 10
	var min_ = min(values[0],values[1]) * 10
	
	var vec = (TriangleLine.points[1]-TriangleLine.points[2]).normalized()
	Points[0] = min_ * WV.scaleFac * vec + TriangleLine.points[2]
	Points[1] = max_ * WV.scaleFac * vec + TriangleLine.points[2]
	
	var isDot = Mode == 'dot'
	DotPoly.visible = isDot
	DrawLine.visible = !isDot
	
	if isDot:  # dot
		DotPoly.position = Points[1]
	else:   # line
		DrawLine.points[0] = Points[0]
		DrawLine.points[1] = Points[1]
	
	#'UpdateValuesBackup' update so it not equal to false any more
	UpdateValuesBackup = _dict
		
func finshProcess():
	# cancel object if it didn't recive any update
	if not UpdateValuesBackup:
		emit_signal("finsh_object")
		queue_free()
		return
	
	var dict = {}
	if !AngleIs30:
		dict['angleType'] = '60'
	else:
		dict['angleType'] = '30'

	var basePnt = toGlobal(TriangleLine.points[2])
	var p1 = toGlobal(Points[0])
	var p2 = toGlobal(Points[1])
	
	dict['ratio'] = -(basePnt-p1).length()/(p1-p2).length()
	
	var paintLine = p2 - p1
	var toCenter = toGlobal(TriangleLine.points[0]) - basePnt
	var rulerCenterAngle = toCenter.angle_to(paintLine)
	dict['diffAngle'] = rulerCenterAngle/2
	
	var insta
	if Mode == 'line':
		insta = WV.drawingScreen.makeLine(p1,p2)
	
	else:
		insta = WV.drawingScreen.makeSnapPnt(p2)
		var ratio = 1.0/WV.LastScaleBackup
		insta.RealBoardLine = [p1*ratio,p2*ratio]
	
	dict['DrawingType'] = 'ruler6030/' + Mode
	insta.DrawingType = 'ruler6030/' + Mode
	WV.allObject.append(insta)
	dict['realType'] = Mode
	var index = ActionManager.getIndex()
	dict['index'] = index
	dict['id'] = str(index)
	insta.MeasureToolData = dict
	insta.ActionsList.append([index])
	
	queue_free()
	emit_signal("finsh_object")
	
	
func toGlobal(_pnt):
	var angle = deg2rad(RulerHolder.rect_rotation)
	return RulerHolder.rect_position + _pnt.rotated(angle)

func remainder(num:float ,denum):
	return num-int(num/denum)*denum

func refactorAngle(angle):
	return remainder(rad2deg(angle)+360,360)

func drawCircle(radius:int ,position:Vector2):
	var circleReslution:float = 32
	DotPoly = Polygon2D.new()
	DotPoly.hide()
	RulerHolder.add_child(DotPoly)
	DotPoly.color= Color('eaeaea')
	var list = []
	for index in circleReslution:
		var vec = polar2cartesian(radius,TAU*index/circleReslution)
		list.append(vec+position)
	DotPoly.polygon = list

func changeColor(_newColor):
	if Mode == 'dot': # change only dot color
		DotPoly.color = _newColor
		
	else:     # change line color
		DrawLine.default_color = _newColor




