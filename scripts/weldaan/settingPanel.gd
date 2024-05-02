extends Control


onready var bgPanel = $Panel
onready var dynamicGridBt = $Panel/ScrollContainer/VBoxContainer2/VBoxContainer3/HBoxContainer/VBoxContainer/Control/dynamicGrid
onready var gridMainColorPicker =$Panel/ScrollContainer/VBoxContainer2/VBoxContainer3/HBoxContainer/VBoxContainer/Control2/gridMainColor 
onready var gridSubColorPicker = $Panel/ScrollContainer/VBoxContainer2/VBoxContainer3/HBoxContainer/VBoxContainer/Control3/gridSubColor
onready var keycastBt = $Panel/ScrollContainer/VBoxContainer2/VBoxContainer4/HBoxContainer/VBoxContainer/Control/CheckButton


func _ready():
	dynamicGridBt.pressed = SettingLog.fetch('gird/dynamicState')
	gridMainColorPicker.color = SettingLog.fetch('gird/mainColor')
	gridSubColorPicker.color =  SettingLog.fetch('gird/subColor')
	keycastBt.pressed = SettingLog.fetch('keycastShowState')

func _input(event):
	if event is InputEventMouseButton:
		if event.button_index == 2:
			var pos = get_global_mouse_position() - bgPanel.rect_global_position
			if pos.x < 0 or pos.y < 0:
				cancel()
			if pos.x > bgPanel.rect_size.x or pos.y > bgPanel.rect_size.y:
				cancel()


# warning-ignore:unused_argument
func _on_gridSubColor_color_changed(color):
	WV.drawingScreen.grid.updateSetting(dynamicGridBt.pressed,gridMainColorPicker.color,gridSubColorPicker.color)

# warning-ignore:unused_argument
func _on_gridMainColor_color_changed(color):
	WV.drawingScreen.grid.updateSetting(dynamicGridBt.pressed,gridMainColorPicker.color,gridSubColorPicker.color)

func _on_dynamicGrid_pressed():
	WV.drawingScreen.grid.updateSetting(dynamicGridBt.pressed,gridMainColorPicker.color,gridSubColorPicker.color)

func _on_CheckButton_pressed():
	WV.drawingScreen.keycast.visible = keycastBt.pressed

func apply():
	SettingLog.save('gird/dynamicState',dynamicGridBt.pressed)
	SettingLog.save('gird/mainColor',gridMainColorPicker.color)
	SettingLog.save('gird/subColor',gridSubColorPicker.color)
	SettingLog.save('keycastShowState',keycastBt.pressed)
	WV.main.panelRemover()
	queue_free()
	
func cancel():
	WV.drawingScreen.keycast.visible = SettingLog.fetch('keycastShowState')
	WV.drawingScreen.grid.updateSetting(SettingLog.fetch('gird/dynamicState'),
	SettingLog.fetch('gird/mainColor'),
	SettingLog.fetch('gird/subColor'))
	
	WV.main.panelRemover()
	queue_free()









