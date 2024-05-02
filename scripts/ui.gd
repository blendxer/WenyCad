extends ScrollContainer


onready var ruler = $shield/Control/Position2D

# ruler line drawer
onready var rulerLayer = $shield/Control/pencil
onready var pos2d = $shield/Control/Position2D/Position2D
onready var line = $shield/Control/pencil/line
onready var dot = $shield/Control/pencil/dot

# caliper
onready var caliperLayer = $shield/Control/caliper
onready var leg1 = $shield/Control/caliper/leg1
onready var leg2 = $shield/Control/caliper/leg2


# compassor
onready var compassorLayer = $shield/Control/compassor
onready var compassor = $shield/Control/compassor/compassorHolder


# eraser
onready var eraserLayer = $shield/Control/eraser

 # modes are 'pencil','caliper' ,'compassor' , 'eraser'
var CurrentMode:String = 'pencil'


var visilblityDict:Dictionary
var WidthFac:float
var DotOriginalSize:= Vector2(6,6)

func _ready():
	WidthFac = pos2d.position.x / 42
	visilblityDict['pencil/ruler'] = rulerLayer
	visilblityDict['caliper/ruler'] = caliperLayer
	visilblityDict['compassor'] = compassorLayer
	visilblityDict['eraser'] = eraserLayer
#	updateMode('pencil')


func updateMode(_newMode):
	# show the ruler in two cases
	ruler.visible = 'ruler' in _newMode
	
	for i in visilblityDict:
		if  _newMode in i:
			visilblityDict[i].show()
		else:
			visilblityDict[i].hide()
		

### compassor
#############

# _angle in degree system
func setAngle(_angle):
	var m = Motion.new()
	m.makeMotion(compassor,'rect_rotation',_angle,1)
	return m
	

##### caliper
#############
func setCaliperWidth(_width):
	var m = Motion.new()
	var vec = Vector2(-_width*WidthFac,6)
	m.makeMotion(ruler,'position',vec,1)
	
	var n = Motion.new()
	n.makeMotion(leg2,'rect_position',vec,1)
	return [m,n]

#### ruler line drawer
######################
func drawLine(_start,_end):
	# hide dot by resize to 0 
	dot.rect_size = Vector2(0,0)
	var actions = [] # hold all actions
	# go to start
	var m = Motion.new()
	var vec = Vector2(-_start*WidthFac,6)
	m.makeMotion(ruler,'position',vec,1)
	WV.freeMotionLine.append(m)
	
	# move from start to end
	var move = Motion.new()
	vec = Vector2(-_end * WidthFac,6)
	move.makeMotion(ruler,'position',vec,2)
	
	# scale line
	var lineWidth = abs(_end - _start)
	vec = Vector2(lineWidth * WidthFac,3)
	var lineScale = Motion.new()
	lineScale.makeMotion(line,'rect_size',vec,2)
	actions.append(move)
	actions.append(lineScale)
	
	if _end > _start:
		var lineShift = Motion.new()
		vec = Vector2(-WidthFac*lineWidth,41) 
		lineShift.makeMotion(line,'rect_position',vec,2) 
		actions.append(lineShift)

	return actions

func resetLine():
	line.rect_size = Vector2(0,3)
	line.rect_position = Vector2(0,41)
	var m = Motion.new()
	var vec = Vector2(0,6)
	m.makeMotion(ruler,'position',vec,.5)
	WV.freeMotionLine.append(m)

func drawDot(_pos):
	# hide line by resize to 0 on the x axis
	line.rect_size = Vector2(0,3)
	dot.rect_size = Vector2()
	var m = Motion.new()
	var vec = Vector2(-_pos*WidthFac,6)
	m.makeMotion(ruler,'position',vec,1)
	var n = Motion.new()
	n.makeMotion(dot,'rect_size',DotOriginalSize,.1)
	m.tailers.append(n)
	return m

func dotRulerBoard(_start,_end):
	# restart
	line.rect_size = Vector2(0,3)
	dot.rect_size = Vector2()
	# go to start
	var m = Motion.new()
	var vec = Vector2(-_start*WidthFac,6)
	m.makeMotion(ruler,'position',vec,1)
	WV.freeMotionLine.append(m)
	
	# move from start to end
	var move = Motion.new()
	vec = Vector2(-_end * WidthFac,6)
	move.makeMotion(ruler,'position',vec,2)
	
	var n = Motion.new()
	n.makeMotion(dot,'rect_size',DotOriginalSize,.1)
	move.tailers.append(n)
	
	return move
