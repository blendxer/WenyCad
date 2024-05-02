extends Control


var Father

onready var line_1 = $Line2D
onready var label_1 = $Label
onready var label_2 = $Label2
 

func _ready():
	updateBox()

# warning-ignore:unused_argument
func input(event):
	updateBox()

func updateBox():
	var vec = (Father.points[0] - Father.points[1]).abs()
	var center = (Father.points[0] + Father.points[1])/2
	
	if vec.x > 10 and vec.y > 10:
		line_1.points[0] = Father.points[0]
		line_1.points[4] = Father.points[0]
		line_1.points[2] = Father.points[1]
		line_1.points[1].x = Father.points[0].x
		line_1.points[1].y = Father.points[1].y
		line_1.points[3].x = Father.points[1].x
		line_1.points[3].y = Father.points[0].y
		
		if abs(vec.x) > 50 and abs(vec.y) > 50:
			line_1.default_color.a = .8
		else:
			# 0.016 = .8/50 = max opacity/max length 
			line_1.default_color.a = min(abs(vec.x),abs(vec.y))*0.016
			
	else:
		line_1.points[0] = Vector2()
		line_1.points[1] = Vector2()
		line_1.points[2] = Vector2()
		line_1.points[3] = Vector2()
		line_1.points[4] = Vector2()

	
	if vec.x > 20:
		label_1.rect_position = center 
		label_1.rect_position.y +=  vec.y/2 + 5
		label_1.text = str(vec.x/WV.drawingScreen.grid.GridSize.x) 
	else:
		label_1.text = ''
	
	if vec.y > 20:
		label_2.rect_position = center 
		label_2.rect_position.x +=  vec.x/2 + 5
		
		label_2.text = str(vec.y/WV.drawingScreen.grid.GridSize.x)
	else:
		label_2.text = ''
	
