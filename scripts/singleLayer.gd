extends Control


onready var bg = $bg/bg
onready var tapButton = $bg/HBoxContainer/tap
onready var colorButton = $bg/HBoxContainer/color
onready var titleButton = $bg/HBoxContainer/title/titleButton
onready var lineEdit = $bg/HBoxContainer/title
onready var visiblityButton = $bg/HBoxContainer/visiblity
onready var ConnectionPntLeft = $bg/left
onready var ConnectionPntDown= $bg/down
onready var colorPicker = $bg/HBoxContainer/color/ColorPickerButton


var GrandFather
var Father = null

var Children:Array # for layer not objects 
var Index
var LayerId:String
var LayerColor:Color = Color('def2f5')
var OpenState:int=0 # 0:open / 1:close 
var VisiblityState:int=0 # 0:show / 1:hide / 2:forced hide
var Title:String
var Level:int


var lastPressTime = 0
var MouseMoveShift:Vector2
var lastMousePnt:Vector2

var MotionState = 0 # 0:static 1:move

func _ready():
	bg.color = GrandFather.ColorDeactivate


# warning-ignore:unused_argument
func _input(event):
	if MotionState == 1:
		if (lastMousePnt-get_global_mouse_position()).length()> 20:
			GrandFather.HoldLayer(self)
			lastPressTime = 0
			MotionState = 2
	elif MotionState == 2:
		rect_position = get_global_mouse_position()+MouseMoveShift

func reArrange():
	rect_size = GrandFather.LayerSize
	GrandFather.DisHeightArr.append(self)
	var height= 0
	if OpenState == 0 and Children.size():
		sortChildren()
		for i in Children:
			i.rect_position = rect_position + Vector2(GrandFather.LevelShift,height+rect_size.y)
			height+=i.reArrange()
			
		# connection lines
		if Children.size() and OpenState == 0:
			var lastPnt = ConnectionPntDown.position + rect_position
			for i in Children:
				var sidePnt = i.ConnectionPntLeft.position + i.rect_position
				var midPnt = Vector2(lastPnt.x,sidePnt.y)
				GrandFather.ConnectionLinesPnts.append(lastPnt)
				GrandFather.ConnectionLinesPnts.append(midPnt)
				GrandFather.ConnectionLinesPnts.append(sidePnt)
				lastPnt = midPnt
		
	return height+rect_min_size.y

func updateLayerColumn():
	GrandFather.LayerColumn.append(LayerId)
	for i in Children:
		i.updateLayerColumn()

func sortChildren():
	var dumpList = []
	var indexInst:Dictionary = {}
	for i in Children:
		indexInst[i.Index] = i
	var keys = indexInst.keys()
	keys.sort()
	for i in keys.size():
		dumpList.append(indexInst[keys[i]])
		indexInst[keys[i]].Index = i
	Children = dumpList


func hideLayer():
	hide()
	for i in Children:
		i.hideLayer()

func showLayer():
	show()
	if OpenState == 0:
		for i in Children:
			i.showLayer()

func activate():
	bg.color = GrandFather.ColorActivate

func deactivate():
	bg.color = GrandFather.ColorDeactivate

func changeTitle(_text):
	Title = _text
	lineEdit.text = _text


func _on_title_button_up():
	if MotionState == 1:
		if (Time.get_ticks_msec()-lastPressTime) < 200:
			GrandFather.newActive(self)
	MotionState = 0

func getFatherTree():
	return Father.getFatherTree() + [self]

func _on_title_button_down():
	if !Input.is_action_pressed("ctrl"):
		if (Time.get_ticks_msec()-lastPressTime) < 200:
			GrandFather.StartEditTitle(self)
			MotionState = 0
		else:
			lastPressTime = Time.get_ticks_msec()
			MouseMoveShift = rect_position - get_global_mouse_position()
			lastMousePnt = get_global_mouse_position()
			MotionState = 1
	else:
		GrandFather.changeObjLayer(self)


func _on_tap_pressed():
	if Children.size():
		if OpenState==0:
			OpenState = 1
			for i in Children:
				i.hideLayer()
			
		elif OpenState == 1:
			OpenState = 0
			for i in Children:
				i.showLayer()
				
		GrandFather.rearrangeLayers()
		updateTapIcon()
	

func updateTapIcon():
	if Children.size():
		if OpenState==0:
			tapButton.icon = GrandFather.ImageSourceTapOpen
		elif OpenState==1:
			tapButton.icon = GrandFather.ImageSourceTapClose
	else:
		tapButton.icon = GrandFather.EmptyImage

func updateVisiblityIcons():
	if !VisiblityState:
		visiblityButton.icon = GrandFather.ImageSourceEyeOpen
	else:
		visiblityButton.icon = GrandFather.ImageSourceEyeClose
		
func visiblityOFChildren(_state:int=VisiblityState):
	updateVisiblityIcons()
	for i in Children:
		i.VisiblityState = _state*2
		i.visiblityOFChildren(_state)
		LayerManager.updateVisibility(i,!VisiblityState)
		
func _on_visiblity_pressed():
	if VisiblityState != 2:
		VisiblityState = int(!VisiblityState) # 1->0 / 0->1`
		updateVisiblityIcons()
		LayerManager.updateVisibility(self,!VisiblityState)
		visiblityOFChildren(VisiblityState)
	else:
		WV.makeAd('16')

func changeColor(_newColor):
	LayerColor =  _newColor
	LayerManager.changeColor(self,_newColor)
	colorPicker.color = _newColor

var CancelEventWhenMoveColor = false
func _on_color_pressed():
	# when move color of this layer after release this func is fired
	# cancel event by check 'CancelEventWhenMoveColor'
	if CancelEventWhenMoveColor:
		CancelEventWhenMoveColor = false
		return
	Undo.addNewChunk('changeLayerColor',[self,LayerColor])
	
	var c = Color.from_hsv(randf(),randf(),rand_range(.7,1),1)
	changeColor(c)
	
func _on_ColorPickerButton_pressed():
	if colorPicker.color == LayerColor:
		return
	Undo.addNewChunk('changeLayerColor',[self,LayerColor])
	changeColor(colorPicker.color)

func _on_ColorPickerButton_button_down():
	GrandFather.moveColor(self)
	CancelEventWhenMoveColor = true


