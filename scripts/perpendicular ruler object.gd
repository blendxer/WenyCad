extends Control

signal finsh_object
var objectType = 'perpendicular_ruler'
var DrawingType = 'perpendicular_ruler'
var Id
var snapedPoint:Array
var objectColor
var LayerId

onready var Holder = $holder
onready var RulerLine = $holder/rulerLine
onready var HorizantalLine = $holder/horizantalLine
onready var MouseLine = $mouseLine
onready var DrawLine = $holder/drawLine


var OpIndex = 0
var DirectionalVec:Vector2
var DirectionalNorVec:Vector2
var Points: = [Vector2(),Vector2()] # directional line
var DrawPoints = [Vector2(),Vector2()]
var MoveState = false
var Mode = ''
var Dotinstance
var HolderAngle

func _ready():
	drawCircle(4)
	Dotinstance.hide()

# warning-ignore:unused_argument
func input(event):
	if OpIndex==1 and MoveState:
		updateProjection()


func initiateObject():
	Points[0] = WV.mousePointer

func updateValues(_dict):
	var text1 = _dict['p1']
	var text2 = _dict['p2']
	
	if text1.empty() and text2.empty():
		WV.makeAd('13')
		return
	elif text1.empty() or text2.empty():
		Mode = 'dot'
	else:
		Mode = 'line'
	
	var values = [float(text1),float(text2)]
	var max_ = max(values[0],values[1]) * WV.scaleFac * 10
	var min_ = min(values[0],values[1]) * WV.scaleFac * 10
		
	Dotinstance.visible = Mode == 'dot'
	DrawLine.visible = Mode == 'line'
	
	
	var sign_ = sign(RulerLine.points[1].y)
	if Mode == 'dot':
		DrawPoints[1].y = max_*sign_
		Dotinstance.position.y = max_*sign_
	
	else:
		DrawLine.points[0].y = min_*sign_
		DrawLine.points[1].y = max_*sign_
		DrawPoints[0].y = min_*sign_
		DrawPoints[1].y = max_*sign_
		

func fieldButton():
	if OpIndex == 0:
		Points[1] = WV.mousePointer
		DirectionalVec = Points[1] - Points[0]
		DirectionalNorVec = DirectionalVec.normalized()
		Holder.rect_position = Points[1]
		HolderAngle = DirectionalVec.angle()
		Holder.rect_rotation = rad2deg(HolderAngle)
		HorizantalLine.points[0].x = 1000
		HorizantalLine.points[1].x = -1000
		drawTriangle()
		OpIndex+=1
	
	updateProjection()
	MoveState = !MoveState
	MouseLine.visible = int(MoveState)
	
func drawTriangle():
	RulerLine.points[1].y = -200
	RulerLine.points[2].x = 200


func flipXaxis():
	var sign_ =sign(RulerLine.points[2].x)
	RulerLine.points[2].x = -sign_ * 200
	
func flipYaxis():
	var sign_ =sign(RulerLine.points[1].y)
	RulerLine.points[1].y = -sign_ * 200
	Dotinstance.position.y *= -1
	DrawLine.points[0].y *= -1
	DrawLine.points[1].y *= -1

func updateProjection():
	var pos = DirectionalNorVec.dot(WV.mousePointer-Points[0])
	Holder.rect_position = pos*DirectionalNorVec + Points[0]
	MouseLine.points[0] = WV.mousePointer
	MouseLine.points[1] = Holder.rect_position
	
func drawCircle(radius:int):
	var circleReslution:float = 32
	Dotinstance = Polygon2D.new()
	Dotinstance.color = Color('eaeaea')
	Holder.add_child(Dotinstance)
	var fraction:float
	var list = []
	for index in circleReslution:
		fraction = index/circleReslution
		var vec = polar2cartesian(radius,TAU*fraction)
		list.append(vec)
	Dotinstance.polygon = list



func finshProcess():
	if Points[0] == Vector2() and Points[1] == Vector2():
		WV.makeAd('13')
		return 
	
	var dict = {}
	dict['DrawingType'] = DrawingType
	
	var basePnt = Holder.rect_position
	var p1 = toGlobal(DrawPoints[0])
	var p2 = toGlobal(DrawPoints[1])
	
	var den = (p1-p2).length() 
	dict['ratio'] = -(basePnt-p1).length()/den
	
	var paintLine = p2 - p1
	var toCenter = toGlobal(RulerLine.points[0]) - basePnt
	var rulerCenterAngle = toCenter.angle_to(paintLine)
	dict['diffAngle'] = rulerCenterAngle/2
	
	
	var insta
	if Mode == 'line':
		insta = WV.drawingScreen.makeLine(p1,p2)
		
	elif Mode == 'dot':
		insta = WV.drawingScreen.makeSnapPnt(p2)
		var ratio = 1.0/WV.drawingScreen.LastScaleBackup
		insta.RealBoardLine = [p1*ratio,p2*ratio]
	WV.allObject.append(insta)
	
	dict['realType'] = Mode
	dict['DrawingType'] = 'perpendicular_ruler/' + Mode
	insta.DrawingType = 'perpendicular_ruler/' + Mode
	var index = ActionManager.getIndex()
	dict['index'] = index
	dict['id'] = str(index)
	insta.MeasureToolData = dict
	insta.ActionsList.append([index])
	
	emit_signal("finsh_object")
	queue_free()

func toGlobal(_pnt):
	return Holder.rect_position + _pnt.rotated(HolderAngle)



