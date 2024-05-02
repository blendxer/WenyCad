extends Control


onready var Line_1 = $Line2D

var Father

var Mode = 'free_draw'

func _ready():
	Father.LineSeqmentVisible = [[0,2*PI]]
	Father.realCirclePos = WV.mousePointer / WV.drawingScreen.LastScaleBackup 
	Father.circlePos = WV.mousePointer
	Father.resetAllLines()
	
	Line_1.points[0] = WV.mousePointer
	Line_1.points[1] = WV.mousePointer
	drawCircle(5,WV.mousePointer)
	

func _input(event):
	if !WV.drawingScreen.lastPanel:
		return
	
	if event is InputEventKey:
		Mode = ['free_draw','keyboard'][int(KeyboardHandler.state)]
		Line_1.visible = Mode == 'free_draw'
		
	if Mode == 'free_draw':
		Father.circleRadius = (WV.mousePointer - Father.circlePos).length()
		Father.realCircleRadius = Father.circleRadius/WV.drawingScreen.LastScaleBackup
		var radius = 0.1* Father.circleRadius / WV.scaleFac
		WV.infoBoard.updateValue('Radius', radius)
		WV.infoBoard.updateValue('Center',Vector2(1,-1)*Father.circlePos / WV.scaleFac)
		
		WV.drawingScreen.lastPanel.radius.text = str(radius)
		Father.updateCircle()
		Line_1.points[1] = WV.mousePointer
			
	elif Mode == 'keyboard':
		Father.circleRadius = abs(KeyboardHandler.number) * WV.scaleFac
		Father.updateCircle()
		var radius =  0.1*Father.circleRadius / WV.scaleFac
		WV.infoBoard.updateValue('Radius',radius)
		WV.drawingScreen.lastPanel.radius.text = str(radius)
		
		if Input.is_action_just_pressed("ui_accept"):
			finshByKeyboard()
			
	if Input.is_action_just_released("alt"):
		var dict={}
		dict['radius'] = str(Father.realCircleRadius)
		dict['start']='0'
		dict['end']='360'
		Father.updateValues(dict)
		queue_free()


func finshByKeyboard():
	Father.circleRadius = abs(KeyboardHandler.number) * WV.scaleFac
	Father.realCircleRadius = Father.circleRadius/ WV.drawingScreen.LastScaleBackup
	Father.endSettingCircle()
	queue_free()

func fieldButton():
	if Father.realCircleRadius == 0: # cancel
		WV.drawingScreen.cancel_object()
		return 
	
	if Mode == 'keyboard':
		finshByKeyboard()
	
	elif Mode == 'free_draw':
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
