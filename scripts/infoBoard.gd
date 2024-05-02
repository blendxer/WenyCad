extends Control


onready var rect = $ColorRect
onready var holder  = $ColorRect/HBoxContainer



var Instances:Dictionary
var UpdateRectSize = false

func _ready():
	WV.boardInfo = self

	
# warning-ignore:unused_argument
func _input(event):
	if UpdateRectSize:
		UpdateRectSize = false
		

func updateValue(_name,_value):
	if not _name in Instances:
		Instances[_name] = makeNewLabel(_name)
	
	Instances[_name].text =_name +'='+ str(_value)

func updateMouse(_name,_value):
	if not _name in Instances:
		Instances[_name] = makeNewLabel(_name)
	Instances[_name].text =_name +'='+ str(_value)

func reset():
	for i in Instances:
		Instances[i].queue_free()
	Instances.clear()


func makeNewLabel(_name):
	var newLabel = Label.new()
	holder.add_child(newLabel)
	newLabel.rect_min_size = Vector2(220,10)
	return newLabel
	

