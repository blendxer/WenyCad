extends Control

var font = preload('res://dynamicFont/regular.tres')

onready var Vholder = $vPanel/MarginContainer/VBoxContainer
onready var panel = $vPanel
onready var vBg = $vPanel/vBg

onready var Hholder = $hPanel/HBoxContainer
onready var hBg = $hPanel/hBg

var hBox = 80
var vBox = 50
var Type
var Caller

var Vindex = 0
var Hindex = 0
var Vcnt = 0
var Hcnt = 0

var menus = {}

func _ready():
	set_process_input(0)

func _input(event):
	var vec = get_global_mouse_position()-rect_size/2
	if abs(vec.x) > hBox:
		horizantalSwap(sign(vec.x-hBox))
	elif abs(vec.y) > vBox:
		verticalSwap(sign(vec.y-vBox))
	
	if event is InputEventMouseButton:
		if event.pressed:
			if event.button_index in [4,5]:
				verticalSwap(2*(event.button_index-4)-1)
			if event.button_index == 1:
				select()
			if event.button_index == 2:
				removePanel()
			
func initialMenu(_instance,_type):
	Caller = _instance
	Type = _type
	visible = 1
	Input.mouse_mode = 1
	set_process_input(1)
	WV.main.frezzeDrawingScreen(0)
	makeMenu(_instance,menus[_type])

func makeMenu(_instance ,_dict):
	Vindex = _dict['lastSetting'][0]
	Hindex = _dict['lastSetting'][1]
	Vcnt = _dict['vertical'].size()
	Hcnt = _dict['horizantal'].size()
	panel.rect_size.y = 20 + 28 * Vcnt
	for label in _dict['vertical']:
		var insta = Label.new()
		Vholder.add_child(insta)
		insta.text = label
		insta.set('custom_fonts/font',font)
	vBg.rect_position.y = Vindex * 28 + 10
	
	for label in _dict['horizantal']:
		var insta = Label.new()
		Hholder.add_child(insta)
		insta.text = label
		insta.set('custom_fonts/font',font)
		insta.rect_min_size.x = 40
		insta.align = Label.ALIGN_CENTER
		
	yield(get_tree().create_timer(.1),"timeout")
	var child = Hholder.get_children()[Hindex]
	hBg.rect_size = child.rect_size
	hBg.rect_position = child.rect_position
	
	
func verticalSwap(_sign):
	Input.warp_mouse_position(rect_size/2)
	Vindex = remainder(Vindex+_sign+Vcnt,Vcnt)
	vBg.rect_position.y = Vindex * 28 + 10
	
func horizantalSwap(_sign):
	Input.warp_mouse_position(rect_size/2)
	Hindex = clamp(Hindex+_sign,0,Hcnt-1)
	var child = Hholder.get_children()[Hindex]
	hBg.rect_size = child.rect_size
	hBg.rect_position = child.rect_position
	
func select():
	menus[Type]['lastSetting'][0] = Vindex
	menus[Type]['lastSetting'][1] = Hindex
	var vertical = menus[Type]['vertical'][Vindex]
	var horizantal = menus[Type]['horizantal'][Hindex]
	Caller.callv(menus[Type]['func'],[vertical,horizantal])
	removePanel()

func removePanel():
	for obj in Vholder.get_children(): obj.queue_free()
	for obj in Hholder.get_children(): obj.queue_free()
	Input.mouse_mode = 0 
	visible = 0
	set_process_input(0)
	WV.main.frezzeDrawingScreen(1)
	
func remainder(num:float ,denum):
	return num-int(num/denum)*denum
