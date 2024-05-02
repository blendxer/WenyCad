extends VBoxContainer

onready var board = $Control/CenterContainer/TextureRect
onready var bg = $Control/CenterContainer2/ColorRect
onready var minViewport = $minViewport
onready var minViewportTexture = $minViewport/TextureRect
onready var minViewportPaper = $minViewport/minViewport_paper
onready var exportViewport = $exportImageViewport
onready var exportViewportPaper = $exportImageViewport/exportImageViewport_paper
onready var changeColorBt = $HBoxContainer/ColorPickerButton

onready var widthLineEdit = $HBoxContainer3/width
onready var hieghtLineEdit = $HBoxContainer3/height

var RatioVec:Vector2 = Vector2(1,1)
var BoxSize:Vector2



func _ready():
	WV.saveImagePanel = self
	
	RatioVec.x = SettingLog.fetch('exportImage/sizeRatio/x')
	RatioVec.y = SettingLog.fetch('exportImage/sizeRatio/y')
	var size = WV.drawingScreen.ExportImageBox.rect.size
	BoxSize = Vector2(round(RatioVec.x*size.x),round(RatioVec.y*size.y))
	widthLineEdit.text = str(BoxSize.x)
	hieghtLineEdit.text = str(BoxSize.y)
	
	var c = SettingLog.fetch('exportImage/backgroundColor')
	changeColorBt.color = c
	minViewportPaper.color = c
	exportViewportPaper.color = c

func _on_Button_pressed():
	WV.main.openFileDialog('save/image',self,'saveImage')
	

func saveImage(path):
	var rect = WV.drawingScreen.ExportImageBox.rect
	var HolderCopy = WV.drawingScreen.objectHolder.duplicate()
	exportViewport.add_child(HolderCopy)
	
	HolderCopy.rect_position = Vector2()
	exportViewport.size = BoxSize
	var ratio = BoxSize/rect.size
	var vec = rect.position-WV.drawingScreen.objectHolder.rect_position
	HolderCopy.rect_scale = ratio
	exportViewportPaper.rect_size = BoxSize
	HolderCopy.rect_position = -ratio*vec
	yield(get_tree().create_timer(.5),"timeout")
	exportViewport.update_worlds()
	var image = exportViewport.get_texture().get_data()
	image.save_png(path)
	HolderCopy.queue_free()

func _on_ColorPickerButton_popup_closed():
	minViewportPaper.color = changeColorBt.color
	exportViewportPaper.color = changeColorBt.color
	SettingLog.save('exportImage/backgroundColor',changeColorBt.color)

func changeSize(_size):
	minViewport.size = _size
	BoxSize = Vector2(round(RatioVec.x*_size.x),round(RatioVec.y*_size.y))
	widthLineEdit.text = str(BoxSize.x)
	hieghtLineEdit.text = str(BoxSize.y)

func _on_width_focus_exited():
	var new_text = max(int(widthLineEdit.text),10)
	var size = WV.drawingScreen.ExportImageBox.rect.size
	var ratio = size.y/size.x
	
	BoxSize = Vector2(new_text , round(new_text * ratio))
	RatioVec = BoxSize / size
	updatesize()

func _on_height_focus_exited():
	var new_text = max(int(hieghtLineEdit.text),10)
	var size = WV.drawingScreen.ExportImageBox.rect.size
	var ratio = size.y/size.x
	
	BoxSize = Vector2(round(new_text/ratio) , new_text)
	RatioVec = BoxSize / size
	updatesize()

func updatesize():
	widthLineEdit.text = str(BoxSize.x)
	hieghtLineEdit.text = str(BoxSize.y)
	SettingLog.save('exportImage/sizeRatio/x',RatioVec.x)
	SettingLog.save('exportImage/sizeRatio/y',RatioVec.y)
