extends Control

onready var spaceBt = $spaceBt
onready var shiftBt = $shiftBt
onready var ctrlBt = $ctrlBt
onready var altBt = $altBt
onready var mouseImg = $mouseImg
onready var labelHolder = $labelHolder

var mouseImg_left = preload("res://image/UI side/icons/keycast/left.png")
var mouseImg_right = preload("res://image/UI side/icons/keycast/right.png")
var mouseImg_normal = preload("res://image/UI side/icons/keycast/normal.png")
var LabelSource = preload("res://scenes/drawing side/randoms/keycast_label.tscn")

var colors  = [Color(1,1,1,1),Color('f9a24e')]

func _input(event):
	if event is InputEventKey:
		if event.pressed:
			var key = char(event.unicode)
			if key!=' ' and key!= '':
				makeLabel(key+getPressedKey())
		
		if   Input.is_action_just_pressed("space"):
			spaceBt.modulate = colors[1]
		elif Input.is_action_just_released("space"):
			spaceBt.modulate = colors[0]
		elif Input.is_action_just_pressed("shift"):
			shiftBt.modulate = colors[1]
		elif Input.is_action_just_released("shift"):
			shiftBt.modulate = colors[0]
		elif Input.is_action_just_pressed("ctrl"):
			ctrlBt.modulate = colors[1]
		elif Input.is_action_just_released("ctrl"):
			ctrlBt.modulate = colors[0]
		elif Input.is_action_just_pressed("alt"):
			altBt.modulate = colors[1]
		elif Input.is_action_just_released("alt"):
			altBt.modulate = colors[0]
		
		elif Input.is_action_just_pressed("enter"):
			makeLabel('Enter')
	
	if event is InputEventMouseButton:
		if event.button_index < 3:
			if event.pressed:
				if event.button_index == 1: 
					mouseImg.texture = mouseImg_left
					makeLabel('Left'+getPressedKey())
				if event.button_index == 2: 
					mouseImg.texture = mouseImg_right
					makeLabel('Right'+getPressedKey())
			else:
				mouseImg.texture = mouseImg_normal

var extraKey = ['ctrl','alt','shift']
func getPressedKey():
	var list = []
	for i in extraKey:
		if Input.is_action_pressed(i):
			list.append(i)
	var s = ' '
	if list.size():
		s+= '+ '
		for i in list.size()-1:
			s+= list[i] + ' + '
		s+= list[-1]
	return s



func makeLabel(_s):
	if labelHolder.get_child_count() > 3:
		labelHolder.get_children()[-1].queue_free()
	var insta = LabelSource.instance()
	labelHolder.add_child(insta)
	insta.changelabel(_s)
	
	
	
	
	
	
