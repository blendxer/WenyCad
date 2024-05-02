extends Line2D

signal finsh_object
var objectType = 'dot'
var DrawingType = 'dot/dot'
var objectColor
var LayerId
var snapedPoint:Array 

var ActionsList:Array

var polygonRadius = 3
var circleInstance:Polygon2D

var mode = 'free_draw'

var distance
var pointAngle:float

var firstHitPnt:Vector2
var realFirstHit:Vector2
var realPosition:Vector2 
var realRect:Rect2


func copy():
	var dict = {}
	dict['objectType'] = objectType
	dict['DrawingType'] = DrawingType
	dict['LayerId'] = LayerId
	
	dict['snapPnts'] = snapedPoint
	dict['realFirstHit'] = realFirstHit
	dict['realPosition'] = realPosition
	dict['ActionsList'] = ActionsList
	
	return dict

func paste(dict):
	objectType = dict['objectType']
	DrawingType = dict['DrawingType']
	LayerId = dict['LayerId']
	var v = WV.drawingScreen.IndexSequenceDict[dict['ActionsList'][0]]
	ActionsList.append(v)
	snapedPoint = dict['snapPnts'].duplicate()
	realFirstHit = dict['realFirstHit']
	realPosition = dict['realPosition']
	WV.allObject.append(self)
	var c = LayerManager.LayerPanel.layerIdDict[LayerId].LayerColor
	objectColor = c
	changeColor(c)
	updateRect()
	snapedPoint[0] = realPosition
	
	

func _ready():
	drawCircle()
	firstHitPnt =  WV.mousePointer
	realFirstHit = WV.mousePointer / WV.LastScaleBackup
	realPosition = WV.mousePointer / WV.LastScaleBackup


func input(event):
	if KeyboardHandler.state:
		if mode == 'manual':
			mode = 'keyboard'
	else:
		if mode == 'keyboard':
			mode = 'manual'
	
	
	if mode == 'keyboard':
		if WV.drawingScreen.LineALignMode == 'y':
			pointAngle = -PI/2
		else:
			pointAngle = 0
		distance = KeyboardHandler.number * WV.scaleFac
			
		setPointPos()
		WV.infoBoard.updateValue('Length',distance/WV.LastScaleBackup)
		if Input.is_action_pressed("ui_accept"):
			finshProcess()
	
func setPointPos():
	circleInstance.position = Vector2(distance*cos(pointAngle),distance*sin(pointAngle)) + firstHitPnt
	realPosition = circleInstance.position/WV.LastScaleBackup

func initiateObject():
	circleInstance.position = WV.mousePointer
	realPosition = WV.mousePointer/WV.LastScaleBackup
	if Input.is_action_pressed("alt"):
		mode = 'manual'
	else:
		return true

func fieldButton():
	finshProcess()

func updateValues(dict):
	KeyboardHandler.reset()
	mode = 'manual'
	if dict['distance'] == '':
		dict['distance'] = 10
	distance = float(dict['distance'] )* WV.scaleFac * 10
	pointAngle = deg2rad(360-float(dict['angle']))
	setPointPos()

func finshProcess():
	ActionsList.append(ActionManager.getIndex())
	updateRect()
	snapedPoint.append(realPosition)
	WV.allObject.append(self)
	emit_signal("finsh_object")
	mode = 'finsh'

func drawCircle():
	var circleReslution:float = 10
	circleInstance = Polygon2D.new()
	add_child(circleInstance)
	var fraction:float
	var list:Array
	for index in circleReslution:
		fraction = index/circleReslution
		var x = polygonRadius*cos(2*PI*fraction)
		var y = polygonRadius*sin(2*PI*fraction)
		list.append(Vector2(x,y))
	circleInstance.polygon = list


func changeColor(_newColor):
	circleInstance.color = _newColor

# fired from "Checkintersection.gd" globle script
func deselected():
	pass
	

# fired from "Checkintersection.gd" globle script
func selected():
	pass


func updateRect():
	realRect.position = realPosition - Vector2(0.01,0.01)
	realRect.end = realPosition + Vector2(0.01,0.01)


func updateScaleVar(_newFactor):
	circleInstance.position = realPosition * _newFactor
	

func reDraw(_newFactor):
	circleInstance.position = realPosition * _newFactor


func finshMove(_shift):
	circleInstance.position  =(realPosition+ _shift) * WV.LastScaleBackup
	realPosition = realPosition+ _shift
	realFirstHit += _shift
	snapedPoint[0] = realPosition
	updateRect()

func shiftObj(_shift):
	circleInstance.position  =(realPosition+ _shift) * WV.LastScaleBackup

func applyScale(_vec,_value):
	liveScale(_vec,_value)
	realPosition = circleInstance.position/WV.LastScaleBackup
	realFirstHit = (realFirstHit-_vec)*_value+_vec
	updateRect()
	snapedPoint[0] = realPosition
	
func liveScale(_vec,_value):
	circleInstance.position  = ((realPosition-_vec)*_value+_vec)*WV.LastScaleBackup

func liveRotate(_vec,_angle):
	circleInstance.position = ((realPosition-_vec).rotated(_angle)+_vec)*WV.LastScaleBackup

func applyRotate(_vec,_angle):
	liveRotate(_vec,_angle)
	realPosition = circleInstance.position/WV.LastScaleBackup
	realFirstHit = (realFirstHit-_vec).rotated(_angle)+_vec
	updateRect()
	snapedPoint[0] = realPosition








