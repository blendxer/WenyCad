extends Control


onready var Line_1 = $Line2D
onready var Line_2 = $Line2D2

var Father
var Points:Array
var DirectionalNorVec:Vector2
var MedPnt:Vector2
var x:float
var P3:Vector2
var MousePointer

func _ready():
	Father.LineSeqmentVisible = [[0,2*PI]]
	Father.circleRadius = 10
	Father.realCircleRadius = Father.circleRadius/WV.drawingScreen.LastScaleBackup
	Points.append(WV.mousePointer / WV.drawingScreen.LastScaleBackup )
	Father.resetAllLines()


# warning-ignore:unused_argument
func _input(event):
	if !WV.drawingScreen.lastPanel:
		return
	if Points.size() ==1:
		Line_2.points[0] = WV.mousePointer
		Line_2.points[1] = Points[0]* WV.drawingScreen.LastScaleBackup
		
	if Points.size() ==2:
		var MouseVec = (WV.mousePointer/WV.drawingScreen.LastScaleBackup - Points[0])
		var dot = DirectionalNorVec.dot(MouseVec)
		P3= DirectionalNorVec * dot + MedPnt
		var y = (P3 - MedPnt).length()
		if y:
			Father.realCircleRadius = (x*x + y*y)/(2*y)
			Father.realCirclePos = -sign(dot) * DirectionalNorVec * Father.realCircleRadius + P3
			
			Father.circleRadius = Father.realCircleRadius * WV.drawingScreen.LastScaleBackup
			Father.circlePos = Father.realCirclePos * WV.drawingScreen.LastScaleBackup
			Father.updateCircle()
			Line_2.points[1] = P3 * WV.drawingScreen.LastScaleBackup
			MousePointer.position = P3 * WV.drawingScreen.LastScaleBackup
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
	if Points.size() ==1:
		Points.append(WV.mousePointer / WV.drawingScreen.LastScaleBackup)
		DirectionalNorVec = (Points[1]-Points[0]).normalized().rotated(PI/2)
		MedPnt = (Points[1] + Points[0])/2
		x = (Points[0]-Points[1]).length()/2
		var p1 = Points[0] * WV.drawingScreen.LastScaleBackup
		var p2 = Points[1] * WV.drawingScreen.LastScaleBackup
		
		Line_1.points[0] = p1
		Line_1.points[1] = p2
		drawCircle(5,p1)
		drawCircle(5,p2)
		MousePointer = drawCircle(5,Vector2())
		Line_2.points[0] = MedPnt * WV.drawingScreen.LastScaleBackup
		Line_2.points[1] = MedPnt * WV.drawingScreen.LastScaleBackup
		
	elif Points.size() == 2:
		if Points[0] == Points[1]: # cancel
			WV.drawingScreen.cancel_object()
			
		else:
			Father.endSettingCircle()
			queue_free()

func drawCircle(radius:int ,position:Vector2):
	var circleReslution:float = 32
	var circleInstance = Polygon2D.new()
	circleInstance.color = Color.tomato
	add_child(circleInstance)
	var fraction:float
	var list:Array
	for index in circleReslution:
		fraction = index/circleReslution
		var vec = polar2cartesian(radius,TAU*fraction)
		list.append(vec+position)
	circleInstance.polygon = list
	return circleInstance

