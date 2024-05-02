extends Control

onready var Line_1 = $Line2D

var Father

var P1:Vector2
var P2:Vector2
var mousePointer
var centerPosCircle

func _ready():
	Father.LineSeqmentVisible = [[0,2*PI]]
	Father.circleRadius = 10
	Father.realCircleRadius = Father.circleRadius/WV.drawingScreen.LastScaleBackup
	P1 = WV.mousePointer / WV.drawingScreen.LastScaleBackup
	Father.resetAllLines()
	
	drawCircle(4,WV.mousePointer)
	centerPosCircle = drawCircle(4,Vector2())
	mousePointer = drawCircle(4,Vector2())
	Line_1.points[0] = WV.mousePointer
	Line_1.points[1] = WV.mousePointer

# warning-ignore:unused_argument
func _input(event):
	if !WV.drawingScreen.lastPanel:
		return
		
	P2 = WV.mousePointer / WV.drawingScreen.LastScaleBackup
	Father.realCirclePos = (P1 + P2)/2
	Father.realCircleRadius = (P1-P2).length()/2
	
	Father.circleRadius = Father.realCircleRadius * WV.drawingScreen.LastScaleBackup
	Father.circlePos = Father.realCirclePos * WV.drawingScreen.LastScaleBackup
	Father.updateCircle()
	
	mousePointer.position = WV.mousePointer
	centerPosCircle.position = (WV.mousePointer + Line_1.points[0])/2
	Line_1.points[1] = WV.mousePointer
	var radius = Father.circleRadius / WV.LastScaleBackup
	WV.infoBoard.updateValue('Radius',radius)
	WV.infoBoard.updateValue('Center',Vector2(1,-1)*Father.circlePos / WV.scaleFac)
	WV.drawingScreen.lastPanel.radius.text = str(radius)
		
	
	if Input.is_action_just_released("alt"):
		var dict={}
		dict['radius'] = str(Father.realCircleRadius)
		dict['start']='0'
		dict['end']='360'
		Father.updateValues(dict)
		queue_free()
	
func fieldButton():
	if Father.realCircleRadius == 0: # cancel
		WV.drawingScreen.cancel_object()
		return 
	
	Father.endSettingCircle()
	queue_free()
		

func drawCircle(radius:int ,position:Vector2):
	var circleReslution:float = 32
	var circleInstance = Polygon2D.new()
	circleInstance.color = Color.tomato
	add_child(circleInstance)
	var fraction:float
	var list = []
	for index in circleReslution:
		fraction = index/circleReslution
		var vec = polar2cartesian(radius,TAU*fraction)
		list.append(vec+position)
	circleInstance.polygon = list
	return circleInstance
