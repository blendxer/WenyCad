extends Control

signal finsh_object
var objectType = 'ruler45'
var DrawingType = 'ruler45'
var Id
var snapedPoint:Array
var objectColor = Color.white
var LayerId



const Hypotense = 300
onready var ruler = $ruler
onready var dashLine1 = $"dash line 1"
onready var dashLine2 = $"dash line 2"
onready var edgeLine = $"ruler/ruler edge"
onready var drawLine = $ruler/drawLine

var RulerDirection = Vector2(1,-1)

var LinePoint:Array
var OpIndex=0
var DirectionNom:Vector2
var LastAddedDot=null
var DictBackup=false
var DotPos
var Points:Array = [Vector2.ZERO , Vector2.ZERO]
var AlignLine = [0,0]

var HolderAngle=0
var TriFollowMouse = true
var Mode = ''

var CirclePoly

func _ready():
	pass

# warning-ignore:unused_argument
func input(event):
	if OpIndex==1:
		if TriFollowMouse:
			updateLocation()
	
	if event is InputEventKey:
		if Input.is_action_just_pressed("h"):
			flipXaxis()
		elif Input.is_action_just_pressed("v"):
			flipYaxis()


func initiateObject():
	LinePoint.append(WV.mousePointer)


func fieldButton():
	if OpIndex == 0:
		LinePoint.append(WV.mousePointer)
		HolderAngle = (LinePoint[1]-LinePoint[0]).angle()
		ruler.rect_rotation = rad2deg(HolderAngle)
		ruler.rect_position = LinePoint[0]
		DirectionNom = (LinePoint[1]-LinePoint[0]).normalized()
		dashLine1.points[0] = LinePoint[0] + 1000 * DirectionNom
		dashLine1.points[1] = LinePoint[0] - 1000 * DirectionNom
		reDrawRuler()
		TriFollowMouse = false
		OpIndex +=1
	
	TriFollowMouse = not(TriFollowMouse)
	dashLine2.visible = TriFollowMouse
	updateLocation()
	

func updateLocation():
	var vec = WV.mousePointer - LinePoint[0]
	var l = vec.dot(DirectionNom)
	var pos = l * DirectionNom + LinePoint[0]
	ruler.rect_position = pos - edgeLine.points[2].rotated(HolderAngle)
	dashLine2.points[0] = pos
	dashLine2.points[1] = WV.mousePointer


func flipXaxis():
	RulerDirection.x = -sign(RulerDirection.x)
	reDrawRuler()
	updateValues(DictBackup)

func flipYaxis():
	RulerDirection.y = -sign(RulerDirection.y)
	reDrawRuler()
	updateValues(DictBackup)

func reDrawRuler():
	edgeLine.points[1].y = RulerDirection.y * sin(PI/4) * Hypotense
	edgeLine.points[2].x = RulerDirection.x * cos(PI/4) * Hypotense

func updateValues(_dict):
	if not(_dict):
		return

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
	var max_ = max(values[0],values[1]) * 10
	var min_ = min(values[0],values[1]) * 10
	
	if LastAddedDot:
		LastAddedDot.queue_free()
		LastAddedDot = false
	drawLine.clear_points()
	
	var vec = (edgeLine.points[1] - edgeLine.points[2]).normalized()
	Points[0] = min_ * WV.scaleFac * vec + edgeLine.points[2]
	Points[1] = max_ * WV.scaleFac * vec + edgeLine.points[2]
	
	drawLine.visible = Mode == 'line'
	if Mode == 'dot':
		LastAddedDot = drawCircle(3 , Points[1])
		DotPos = Points[1]
	else:
		drawLine.add_point(Points[0])
		drawLine.add_point(Points[1])
		
	DictBackup = _dict
		
func finshProcess():
	if Points[0] == Vector2() and Points[1] == Vector2():
		WV.makeAd('13')
		return 
	
	
	var dict = {}
	dict['DrawingType'] = DrawingType
	
	var basePnt = toGlobal(edgeLine.points[2])
	var p1 = toGlobal(Points[0])
	var p2 = toGlobal(Points[1])
	
	dict['ratio'] = -(basePnt-p1).length()/(p1-p2).length()
	
	var paintLine = p2 - p1
	var toCenter = toGlobal(edgeLine.points[0]) - basePnt
	var rulerCenterAngle = toCenter.angle_to(paintLine)
	dict['diffAngle'] = rulerCenterAngle/2
	
	
	var insta
	if Mode == 'line':
		insta = WV.drawingScreen.makeLine(p1,p2)
		
	elif Mode == 'dot':
		insta = WV.drawingScreen.makeSnapPnt(p2)
		var ratio = 1.0/WV.LastScaleBackup
		insta.RealBoardLine = [p1*ratio,p2*ratio]
	
	WV.allObject.append(insta)
	dict['realType'] = Mode
	dict['DrawingType'] = 'ruler45/' + Mode
	insta.DrawingType = 'ruler45/' + Mode
	var index = ActionManager.getIndex()
	dict['index'] = index
	dict['id'] = str(index)
	insta.MeasureToolData = dict
	insta.ActionsList.append([index])
	
	queue_free()
	emit_signal("finsh_object")

func toGlobal(_pnt):
	return ruler.rect_position + _pnt.rotated(HolderAngle)

func drawCircle(radius:int ,position:Vector2):
	var circleReslution:float = 32
	CirclePoly = Polygon2D.new()
	CirclePoly.color = objectColor
	CirclePoly.color = Color('eaeaea')
	ruler.add_child(CirclePoly)
	var fraction:float
# warning-ignore:unassigned_variable
	var list:Array
	for index in circleReslution:
		fraction = index/circleReslution
		var vec = polar2cartesian(radius,TAU*fraction)
		list.append(vec+position)
	CirclePoly.polygon = list
	return CirclePoly

func remainder(num:float ,denum):
	return num-int(num/denum)*denum

func changeColor(_newColor):
	drawLine.default_color = _newColor
	if CirclePoly:
		if Mode == 'dot':
			CirclePoly.color = _newColor






