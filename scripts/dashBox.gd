extends Control

var lineSource = preload('res://scenes/drawing side/randoms/dashBox_line.tscn')


var Data:Dictionary={
	'Pan':false,
	'Snap':false,
	'Lock Axis : x':false,
	'Lock Axis : y':false,
	'Multi Selection':false,
	'Keyboard':false
}

var Colors:Dictionary={
	'Pan':Color(.7,.7,.7,.3), 
	'Snap':Color(1, 1,0,.3),
	'Lock Axis : x':Color(1,0,0,.3),
	'Lock Axis : y':Color(0,1,0,.3),
	'Multi Selection':Color(0,1,1,.3),
	'Keyboard':Color( 0.39, 0.58, 0.92, .3 )
}


var InstaHolder:Array

func _ready():
	for i in Data.size():
		var insta = lineSource.instance()
		add_child(insta)
		InstaHolder.append(insta)
		insta.rect_position.y = 20 * i
		

var lastType = ''
var lastState = false
func changeState(_type,_state=false):
	if lastType != _type or lastState != _state:
		lastType = _type
		lastState = _state
		if _type == 'cleanAxis':
			Data['Lock Axis : y'] = false
			Data['Lock Axis : x'] = false

		else:
			Data[_type]= _state
		updateLabel()

func updateLabel():
	var i = 0
	for j in Data:
		InstaHolder[i].changeType('',Color(0,0,0,0))
		i+=1
	i = 0
	for j in Data:
		if Data[j]:
			InstaHolder[i].changeType(j,Colors[j])
			i+=1













