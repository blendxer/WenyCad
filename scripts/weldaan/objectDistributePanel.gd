extends Control

onready var chooiceActiveBt = $Panel/VBoxContainer/chooiceActive
onready var buttonsHolder = $HBoxContainer3
onready var linesGridHolder = $Panel/VBoxContainer/chooiceActive/GridContainer
onready var girdButton = $Panel/VBoxContainer/chooiceActive/GridContainer/ColorRect5/ColorRect/VBoxContainer/HBoxContainer/gridBt
onready var gridCntLineEdit = $Panel/VBoxContainer/chooiceActive/GridContainer/ColorRect5/ColorRect/VBoxContainer/HBoxContainer/count
onready var gridShiftLineEdit = $Panel/VBoxContainer/chooiceActive/GridContainer/ColorRect5/ColorRect/VBoxContainer/HBoxContainer2/shift

onready var lineEdit_1 = $Panel/VBoxContainer/chooiceActive/GridContainer/ColorRect4/ColorRect/VBoxContainer/HBoxContainer/LineEdit0
onready var lineEdit_2 = $Panel/VBoxContainer/chooiceActive/GridContainer/ColorRect4/ColorRect/VBoxContainer/HBoxContainer2/LineEdit0
onready var lineEdit_3 = $Panel/VBoxContainer/chooiceActive/GridContainer/ColorRect6/ColorRect/VBoxContainer/HBoxContainer/LineEdit2
onready var constantShiftLineEdit = $Panel/VBoxContainer/chooiceActive/GridContainer/ColorRect3/ColorRect/HBoxContainer/LineEdit

onready var radius = $Panel/VBoxContainer/chooiceActive/GridContainer/ColorRect6/ColorRect/VBoxContainer/HBoxContainer2/radius
onready var startAngle  = $Panel/VBoxContainer/chooiceActive/GridContainer/ColorRect6/ColorRect/VBoxContainer/HBoxContainer3/start
onready var endAngle = $Panel/VBoxContainer/chooiceActive/GridContainer/ColorRect6/ColorRect/VBoxContainer/HBoxContainer4/end

var ChooiceIndex = 0
var LockVec:Vector2 = Vector2(1,1)
var Lines = []
var PickerIndex =0
var PickedPos = [Vector2(),Vector2(),Vector2()]
var GirdDirection = Vector2(1,0)
var PickerLineEditIndex = []

var LinesColor = [Color(1,1,1,.3),Color(0,1,1,1)]
var AxisButtonPath = "HBoxContainer3/"
var Axis = 'vertical'
var ChooicesRect:Rect2

func _ready():
	PickerLineEditIndex.append(lineEdit_1)
	PickerLineEditIndex.append(lineEdit_2)
	PickerLineEditIndex.append(lineEdit_3)
	ChooicesRect.position = $Panel/VBoxContainer/chooiceActive.rect_global_position
	ChooicesRect.size = $Panel/VBoxContainer/chooiceActive.rect_size
	Lines = linesGridHolder.get_children()
	
	
	updateChooice(SettingLog.fetch('distribution/ChooiceIndex'))
	updateButtons(SettingLog.fetch('distribution/lockVec'))
	LockVec =  SettingLog.fetch('distribution/lockAxisVec')
	constantShiftLineEdit.text = str(SettingLog.fetch('distribution/constantShift'))
	radius.text = str(SettingLog.fetch('distribution/radius'))
	startAngle.text = str(SettingLog.fetch('distribution/startAngle'))
	endAngle.text = str(SettingLog.fetch('distribution/endAngle'))
	for i in 3:
		var pos = SettingLog.fetch('distribution/pickedPos_'+str(i))
		PickerLineEditIndex[i].text =  str(WV.vecToStr(pos))
	
	gridCntLineEdit.text = str(SettingLog.fetch('distribution/gridOrder/count'))
	gridShiftLineEdit.text = WV.vecToStr(SettingLog.fetch('distribution/gridOrder/vec'))
	if SettingLog.fetch('distribution/gridOrder/type') != 'by column':
		_on_gridBt_pressed()
	

func updateChooice(_index):
	ChooiceIndex = _index
	for i in Lines.size():
		Lines[i].color = LinesColor[int(_index==i)]
	buttonsHolder.visible = _index<3


func _on_apply_pressed():
	SettingLog.save('distribution/ChooiceIndex',ChooiceIndex)
	SettingLog.save('distribution/lockVec',Axis)
	SettingLog.save('distribution/lockAxisVec',LockVec)
	match ChooiceIndex:
		0: 
			Organizer.distribution_evenSpace(LockVec)
		1: 
			Organizer.distribution_sideToSide(LockVec)
		2: 
			var num = float(constantShiftLineEdit.text)
			if num:
				Organizer.distribution_constantShift(LockVec,num)
				SettingLog.save('distribution/constantShift',num)
			else:
				WV.makeAd('19')
		3:
			var p1 = WV.strToVec(PickerLineEditIndex[0].text)
			var p2 = WV.strToVec(PickerLineEditIndex[1].text)
			SettingLog.save('distribution/pickedPos_0',p1)
			SettingLog.save('distribution/pickedPos_1',p2)
			Organizer.distribution_betweenTwoPnts(p1,p2)
		
		4:
			var cnt = int(gridCntLineEdit.text)
			var shift = WV.strToVec(gridShiftLineEdit.text)
			SettingLog.save('distribution/gridOrder/count',cnt)
			SettingLog.save('distribution/gridOrder/vec',shift)
			SettingLog.save('distribution/gridOrder/type',girdButton.text)
			Organizer.distribution_grid(cnt,shift,GirdDirection)
		5:	
			var pos = WV.strToVec(PickerLineEditIndex[2].text)
			SettingLog.save('distribution/pickedPos_2',pos)
			var rad = float(radius.text)
			var start = float(startAngle.text)
			var end = float(endAngle.text)
			SettingLog.save('distribution/radius',rad)
			SettingLog.save('distribution/startAngle',start)
			SettingLog.save('distribution/endAngle',end)
			Organizer.distribution_circular(pos,rad,start,end)
	
	WV.main.panelRemover()
	queue_free()
	

func _on_vertical_pressed():
	LockVec = Vector2(0,1)
	updateButtons('vertical')

func _on_both_pressed():
	LockVec = Vector2(1,1)
	updateButtons('both')

func _on_horizantal_pressed():
	LockVec = Vector2(1,0)
	updateButtons('horizantal')

func updateButtons(_newMode):
	get_node(AxisButtonPath + Axis).modulate = Color(1,1,1,1)
	get_node(AxisButtonPath + _newMode).modulate = Color(0,1,1,1)
	Axis = _newMode
	


var pickPntState =false
func _input(event):
		if event is InputEventMouseButton:
			if event.pressed:
				if event.button_index == 1:
					if pickPntState:
						if WV.drawingScreen.insideField():
							makeDot()
					else:
						if ChooicesRect.has_point(get_global_mouse_position()):
							calculateChooice()
					
				if event.button_index == 2:
					WV.main.panelRemover()
					queue_free()

func calculateChooice():
	var vec = get_global_mouse_position() - chooiceActiveBt.rect_global_position
	vec *= Vector2(3,2)
	vec /= chooiceActiveBt.rect_size
	vec = vec.floor()
	var i = int(vec.x + 3 * vec.y)
	updateChooice(i)
	
	

func makeDot():
	var pos = WV.mousePointer/WV.LastScaleBackup
	PickedPos[PickerIndex] = pos
	PickerLineEditIndex[PickerIndex].text = WV.vecToStr(pos)
	
	WV.main.frezzeDrawingScreen(0)
	pickPntState = false
	show()


func picker(_index):
	PickerIndex = _index
	hide()
	WV.main.frezzeDrawingScreen(1)
	pickPntState = true


var gridStateIndex = 1
func _on_gridBt_pressed():
	var list = ['by column','by row']
	var i = int(gridStateIndex%2)
	GirdDirection.y = i
	GirdDirection.x = 1-i
	girdButton.text = list[i]
	gridStateIndex +=1
	

# proxy
func _on_picker0_pressed(): picker(0)
func _on_picker1_pressed(): picker(1)
func _on_picker2_pressed(): picker(2)


