extends Control

signal finsh_object
var objectType = 'alongLine'
var DrawingType = 'alongLine'
var snapedPoint:Array
var objectColor
var LayerId

onready var DashLine1 = $dashLine1
onready var DashLine2 = $dashLine2
onready var DrawLine = $drawLine
onready var DotHolder = $dotHolder


var Mode = 'oneDirection'
#var Mode = 'connect'

# this the align line which define the direction
# and the start point of draw line or dot
# the zeros going to replaced with vector in array though the process
var DirectionLine:Array = [0,0]
var DirectionalVecNor:Vector2 

var LinePnt:Array= [Vector2(),Vector2()]
var HitPnts:Array

var DrawingMode:String = ''
var OpIndex = 0

func _ready():
	# initialization
	drawCircle(4,Vector2.ZERO)
	DirectionLine[0] = WV.mousePointer 
	HitPnts.append(WV.mousePointer)

# warning-ignore:unused_argument
func input(event):
	pass

func initiateObject():
	pass


func fieldButton():
	if OpIndex == 0:
		DirectionLine[1] = WV.mousePointer
		HitPnts.append(WV.mousePointer)
		calculateDirection()
		if DirectionLine[0]==DirectionLine[1]:
			WV.drawingScreen.cancel_object()
		
	elif OpIndex == 1:
		DrawingMode = 'dot'
		LinePnt[0] = Vector2(INF,INF)
		LinePnt[1] = setPosManual()
		updateLineStatus()
	elif OpIndex == 2:
		DrawingMode = 'line'
		LinePnt[0] = LinePnt[1]
		LinePnt[1] = setPosManual()

		updateLineStatus()
		finshProcess()
		
	OpIndex+=1
	
func calculateDirection():
	DirectionalVecNor = (DirectionLine[1]-DirectionLine[0]).normalized()
	DashLine1.add_point(1000*DirectionalVecNor+DirectionLine[0])
	DashLine1.add_point(DirectionLine[1])
	DashLine2.add_point(-1000*DirectionalVecNor+DirectionLine[0])
	DashLine2.add_point(DirectionLine[1])

func setPosManual():
	var mouseVec = WV.mousePointer - DirectionLine[1]
	var dot = DirectionalVecNor.dot(mouseVec) 
	return dot * DirectionalVecNor + DirectionLine[1]


func updateValues(_dict):
	var text1 = _dict['p1']
	var text2 = _dict['p2']
	
	DrawingMode = ''
	if text1.empty() and text1.empty():
		WV.makeAd('12')
		return
	
	if text1.empty() or text2.empty():
		DrawingMode = 'dot'
	else:
		DrawingMode = 'line'
	
	var values = [float(text1),float(text2)]
	
	var max_ = max(values[0],values[1])*10
	var min_ = min(values[0],values[1])*10
	
	var l1 = min_ * WV.scaleFac
	var l2 = max_ * WV.scaleFac
	LinePnt[0] = l1 * DirectionalVecNor + DirectionLine[1]
	LinePnt[1] = l2 * DirectionalVecNor + DirectionLine[1]
	
	updateLineStatus()


func updateLineStatus():
	if DrawingMode == 'dot':
		DotHolder.rect_position = LinePnt[1] 
		DotHolder.show()
		DrawLine.hide()
	elif DrawingMode == 'line':
		DrawLine.points[0] = LinePnt[0] 
		DrawLine.points[1] = LinePnt[1]
		DotHolder.hide()
		DrawLine.show()
	
func drawCircle(radius:int ,position:Vector2):
	var circleReslution:float = 6
	var DotInstance = Polygon2D.new()
	DotInstance.color = Color('eaeaea')
	DotHolder.add_child(DotInstance)
	var fraction = 0.0
	var list = []
	for index in circleReslution:
		fraction = index/circleReslution
		var vec = polar2cartesian(radius,TAU*fraction)
		list.append(vec+position)
	DotInstance.polygon = list


func finshProcess():
	if DrawingMode == '':
		WV.drawingScreen.cancel_object()
		return
	
	# dot
	if LinePnt[0].x == INF:
		var l1 = (LinePnt[1]-DirectionLine[0]).length()
		var l2 = (LinePnt[1]-DirectionLine[1]).length()
		if l1 > l2 : LinePnt[0] = DirectionLine[0]
		else       : LinePnt[0] = DirectionLine[1]
	
	var p1 = LinePnt[0]
	var p2 = LinePnt[1]

	var a_b = p2-p1
	var r1 = ((DirectionLine[0]-p1)/a_b).x
	var r2 = ((DirectionLine[1]-p1)/a_b).x
	
	var insta
	var dict = {}
	if DrawingMode == 'line':
		insta = WV.drawingScreen.makeLine(p1,p2)
	
	elif DrawingMode == 'dot':
		insta = WV.drawingScreen.makeSnapPnt(p2)
		var ratio = 1.0 / WV.drawingScreen.LastScaleBackup
		insta.RealBoardLine = [p1*ratio,p2*ratio]
	
	dict['values'] = [r1,r2]
	var index = ActionManager.getIndex()
	dict['index'] = index
	insta.ActionsList.append([index])
	
	dict['DrawingType'] = 'alongLine/' + DrawingMode
	insta.DrawingType = 'alongLine/' + DrawingMode
	
	insta.MeasureToolData = dict
	WV.allObject.append(insta)
	
	emit_signal("finsh_object")
	queue_free()
	

func changeColor(_newColor):
	DrawLine.default_color = _newColor
	DotHolder.get_child(0).color = _newColor


func toReal(arr:Array):
	var list = []
	for i in arr.size():
		list.append(arr[i]/WV.drawingScreen.LastScaleBackup)
	return list


