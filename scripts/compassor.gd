extends Control

signal finsh_object
var objectType = 'compassor'
var DrawingType = ''
var snapedPoint:Array
var Id
var LayerId
var objectColor

var Mode:String = 'freeAlign'

onready var CompassorHolder = $compassHolder
onready var DotHolder = $dotHolder
onready var position2d = $compassHolder/Position2D
onready var line_1 = $compassHolder/Line2D


var Angle
var CompassorHorizantalLine:=[0,0]
var DirectionVecNor
var CompassorDirectionState = false
var DictionaryBackup = null

var OpIndex = 0

func _ready():
	# grasp the mode 
	Mode = WV.drawingScreen.SubtypePanel.mode
	DrawingType = 'compassor/' + Mode
	
	
	drawCircle(4,Vector2.ZERO)
	# set the first pnt in the horizantal line
	CompassorHorizantalLine[0] = WV.mousePointer
	
	if Mode =='freeAlign':
		var insta = load("res://scenes/drawing side/randoms/ray.tscn").instance()
		add_child(insta)
	
	if Mode == 'horizantal':
		CompassorHorizantalLine[1] = WV.mousePointer + Vector2.RIGHT
		lineSetting()
		updateValues({'angle':0})
	
	elif Mode == 'vertical':
		CompassorHorizantalLine[1] = WV.mousePointer + Vector2.UP
		lineSetting()
		updateValues({'angle':0})
	

func initiateObject():
	pass

func fieldButton():
	if Mode == 'freeAlign':
		if OpIndex == 0 :
			# set the second pnt in horizantal line
			CompassorHorizantalLine[1] = WV.mousePointer
			lineSetting()
			
		elif OpIndex == 1:
			updateValues({'angle':0})
		elif OpIndex == 2:
			finshProcess()
			
	elif Mode == 'horizantal':
		if OpIndex == 0:
			finshProcess()
			
	elif Mode == 'vertical':
		if OpIndex == 0:
			finshProcess()
		
	OpIndex+=1


# warning-ignore:unused_argument
func input(event):
	if Mode == 'freeAlign':
		if OpIndex == 1:
			setCompassorPos()

func lineSetting():
	# compute directional vector
	DirectionVecNor = CompassorHorizantalLine[1]-CompassorHorizantalLine[0]
	DirectionVecNor = DirectionVecNor.normalized()
	# set the rotation of compassor
	var angle = DirectionVecNor.angle()
	CompassorHolder.rect_rotation = rad2deg(angle)
	# show the compassor becuase it is at the  
	# begining is hiding
	CompassorHolder.show()
	# update compassor position
	setCompassorPos()


func setCompassorPos():
	var mouseVec = WV.mousePointer - CompassorHorizantalLine[1]
	var dot = DirectionVecNor.dot(mouseVec)
	var pos = dot * DirectionVecNor + CompassorHorizantalLine[1]
	CompassorHolder.rect_position = pos


func flipCompassor():
	CompassorDirectionState = !CompassorDirectionState
	var angle = DirectionVecNor.angle()
	CompassorHolder.rect_rotation = rad2deg(angle) + 180 * int(CompassorDirectionState)
	updateProcess()
	
func updateValues(_dict):
	DictionaryBackup = _dict
	updateProcess()

# -f protractor panel
func apply():
	finshProcess()

	
func updateProcess():
	if !DictionaryBackup:
		return 
	var angle = deg2rad(float(DictionaryBackup['angle']))
	var angleShift = DirectionVecNor.angle()
	angle += angleShift
	var _sign = int(CompassorDirectionState)*2-1
	var radius = WV.LastScaleBackup * 5.4
	var vec = _sign*radius*Vector2(cos(angle),sin(angle)) + CompassorHolder.rect_position
	
	DotHolder.show()
	DotHolder.rect_position = vec
	
	angle-=angleShift
	var count = line_1.get_point_count()
	for i in count:
		var fac = float(i)/(count-1)
		var diff =  fac * angle 
		var vect = radius * Vector2(cos(diff),-sin(diff))
		vect.x *= -1
		line_1.points[i] = vect 
	

func finshProcess():
		
	var ratio = 1.0/WV.LastScaleBackup
	var pos = DotHolder.rect_position
	var headPos = CompassorHolder.rect_position
	var dict = {}
	var insta = WV.drawingScreen.makeSnapPnt(pos)
	insta.RealBoardLine = [headPos*ratio,pos*ratio]
	dict['angle'] = line_1.points[0].angle_to(line_1.points[-1])
	var vec = -headPos+toGlobal(line_1.points[0])
	dict['mainAngle'] = vec.angle()
	
	var vec2 = vec.normalized()
	if abs(vec2.x) and abs(vec2.y):  dict['DrawingType'] = 'compassor/freeAlign'
	elif abs(vec2.x):                dict['DrawingType'] = 'compassor/horizantal'
	elif abs(vec2.y):                dict['DrawingType'] = 'compassor/vertical'
	
	insta.DrawingType = 'compassor'
	WV.allObject.append(insta)
	var index = ActionManager.getIndex()
	dict['index'] = index
	insta.MeasureToolData = dict
	insta.ActionsList.append(index)

	emit_signal("finsh_object")
	queue_free()

func toGlobal(_vec):
	return CompassorHolder.rect_position + _vec.rotated(deg2rad(CompassorHolder.rect_rotation))

	
func changeColor(_newColor):
	pass

func drawCircle(radius:int ,position:Vector2):
	var circleReslution:float = 10
	var circleInstance = Polygon2D.new()
	circleInstance.color = Color('c5ff6145')
	DotHolder.add_child(circleInstance)
	var fraction:float
	var list = []
	for index in circleReslution:
		fraction = index/circleReslution
		var vec = polar2cartesian(radius,TAU*fraction)
		list.append(vec+position)
	circleInstance.polygon = list



