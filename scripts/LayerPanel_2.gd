extends Control


var EmptyImage = preload('res://image/UI side/icons/layers/emptyImage.png')
var ImageSourceTapOpen = preload('res://image/UI side/icons/layers/openTap.png')
var ImageSourceTapClose = preload('res://image/UI side/icons/layers/closeTap.png')
var ImageSourceEyeOpen = preload('res://image/UI side/icons/layers/openEye.png')
var ImageSourceEyeClose = preload('res://image/UI side/icons/layers/closeEye.png')

var SingleLayerSource = preload('res://scenes/drawing side/layeres/singleLayer.tscn')
onready var layerHolder = $VBoxContainer/ScrollContainer/shield/holder
onready var floater1 = $VBoxContainer/ScrollContainer/shield/floater1
onready var floater2 = $VBoxContainer/ScrollContainer/shield/floater2
onready var shield =  $VBoxContainer/ScrollContainer/shield
onready var scroller = $VBoxContainer/ScrollContainer

var ColorActivate = Color(.5,.5,.5,.3)
var ColorDeactivate = Color(.2,.2,.2,.5)

var LayerColumn:Array # layerids sorted
var LayerSize:= Vector2(250,35)
var LevelShift = 30
var ConnectionLinesPnts:Array

var AllLayer:Array
var ActiveLayer=null
var Children:Array
# fake variable
const Level = 0
const VisiblityState = 0

var DisHeightArr:Array
var holdLayerState:bool = false
var HoldedChild
var HighestLevel:int=1

var CursorRect:Rect2
var TitleEditLayer=null

var OverlapState:int=0
var OverlapInstance:Control

func _ready():
	layerHolder.rect_min_size = scroller.rect_size
	floater2.rect_size = layerHolder.rect_min_size
	
	LayerManager.LayerPanel = self


func _input(event):
	if TitleEditLayer:
		if Input.is_action_just_pressed("ui_accept"):
			finshEditTitle()

	if holdLayerState:
		OverlapState = 3
		var index = layerHolder.get_local_mouse_position().y/LayerSize.y
		if index < DisHeightArr.size():
			var diff = layerHolder.get_local_mouse_position().y - int(index) * LayerSize.y
			if diff >= 0 and DisHeightArr[index]!=HoldedChild:
				
				OverlapInstance = DisHeightArr[index]
				if HoldedChild in  OverlapInstance.getFatherTree():
					# the green channel of color is used to determine
					# state of this if condition in @f3d45fd
					  floater2.c = Color(1,0,0,.7)
				else: floater2.c = Color(1,1,1,.7)
				
					
				if     diff <= 0.28*LayerSize.y:  OverlapState = 0
				elif   diff <= 0.71*LayerSize.y:  OverlapState = 1
				else:                             OverlapState = 2

		proform()
				
		if event is InputEventMouseButton:
			if event.button_index == 1:
				if !event.pressed:
					holdLayerState = false
					floater2.updateRect(Rect2())
					
					# @f3d45fd
					if !floater2.c.g:
						OverlapState = 3
					applyTrans()


func proform():
	if OverlapState<3:
		match OverlapState:
			0:
				CursorRect.position = OverlapInstance.rect_position 
				CursorRect.size = Vector2(OverlapInstance.rect_size.x,(0.28*LayerSize.y))
			1:
				CursorRect.position = OverlapInstance.rect_position
				CursorRect.size = OverlapInstance.rect_size 
			2:
				CursorRect.position = OverlapInstance.rect_position + Vector2(0,0.71*LayerSize.y) 
				CursorRect.size = Vector2(OverlapInstance.rect_size.x,0.28*LayerSize.y)
				
		floater2.updateRect(CursorRect)
	else:
		floater2.updateRect(Rect2())



func makeNewLayer():
	# if there is layer make layer and make
	# the active one
	if AllLayer.size() == 0:
		var insta = SingleLayerSource.instance()
		insta.LayerId = IdMaker.getId(7)
		insta.GrandFather = self
		insta.Father = self
		layerHolder.add_child(insta)
		AllLayer.append(insta)
		insta.VisiblityState = 0
		ActiveLayer = insta
		insta.Index = 1
		Children.append(insta)
		insta.changeTitle(getName(self))
		insta.rect_size = LayerSize
		insta.Level = 1
		insta.updateVisiblityIcons()
		LayerManager.ActiveLayer = insta
		LayerManager.makeNewLayer(insta.LayerId)
		newActive(insta)
		columnWork()
		rearrangeLayers()

	else:
		if ActiveLayer:
			var insta = SingleLayerSource.instance()
			insta.LayerId = IdMaker.getId(7)
			insta.GrandFather = self
			layerHolder.add_child(insta)
			insta.Level = ActiveLayer.Father.Level
			insta.Father = ActiveLayer.Father
			insta.Index = ActiveLayer.Index - .1
			AllLayer.append(insta)
			ActiveLayer.Father.Children.append(insta)
			insta.changeTitle(getName(ActiveLayer.Father))
			newActive(insta)
			insta.rect_size = LayerSize
			insta.Father.sortChildren()
			rearrangeLayers()
			ActiveLayer.Father.updateTapIcon()
			insta.VisiblityState = ActiveLayer.Father.VisiblityState
			insta.updateVisiblityIcons()
			insta.show_behind_parent=true
			LayerManager.ActiveLayer = insta
			LayerManager.makeNewLayer(insta.LayerId)
			columnWork()
	
		else:
			print('select a layer please !!!')

func HoldLayer(_layer):
	holdLayerState = true
	HoldedChild = _layer

func rearrangeLayers():
	DisHeightArr.clear()
	ConnectionLinesPnts.clear()
	var height:int=0
	for i in Children:
		i.rect_position = Vector2(0,height)
		height += i.reArrange()
		
	shield.rect_min_size.y = DisHeightArr.size() * LayerSize.y
	shield.rect_min_size.x = LayerSize.x + HighestLevel * LevelShift
	floater1.updateLines(ConnectionLinesPnts)

func newActive(_insta):
	if ActiveLayer:
		ActiveLayer.deactivate()
	ActiveLayer = _insta
	ActiveLayer.activate()
	LayerManager.ActiveLayer = _insta

func applyTrans():
	match OverlapState:
		0:  moveLayer(OverlapInstance,HoldedChild,-.1)
		1:  addChildtoLayer(OverlapInstance,HoldedChild)
		2:  moveLayer(OverlapInstance,HoldedChild,.1)
		3:  rearrangeLayers()
		
	


func moveLayer(_over ,_holded,_indexShift):
	if _over.Father == _holded.Father:
		_holded.Index = _over.Index + _indexShift
		_over.Father.sortChildren()
	else:
		_holded.Level = _over.Father.Level
		_holded.Index = _over.Index + _indexShift
		_holded.Father.Children.erase(_holded)
		_holded.Father.sortChildren()
		_over.Father.Children.append(_holded)
		_over.Father.sortChildren()
		_holded.Father.updateTapIcon()
		_holded.Father = _over.Father

		_holded.Father.updateTapIcon()
		_over.updateTapIcon()
		# cancel forced hide mode
		if _holded.VisiblityState == 2:
			_holded.VisiblityState = 1
			
	columnWork()
	rearrangeLayers()

func addChildtoLayer(_father,_child):
	_child.Father.Children.erase(_child)
	_child.Father.sortChildren()
	_child.Father.updateTapIcon()
	_child.Index = -1
	
	_father.Children.append(_child)
	_father.sortChildren()
	_father.updateTapIcon()
	
	_child.Father = _father
	_child.Level = _father.Level + 1
	
	HighestLevel = 0
	for i in AllLayer:
		if i.Level > HighestLevel:
			HighestLevel = i.Level
			
	columnWork()
	rearrangeLayers()

	if _father.VisiblityState == 1:
		 _child.VisiblityState = 2
	else:      
		_child.VisiblityState = _father.VisiblityState
	_child.visiblityOFChildren()


func columnWork():
	updateLayerColumn()
	LayerManager.updateColumn(LayerColumn)

func updateLayerColumn():
	LayerColumn.clear()
	for i in Children:
		i.updateLayerColumn()

func sortChildren():
	var dumpList = []
# warning-ignore:unassigned_variable
	var indexInst:Dictionary
	for i in Children:
		indexInst[i.Index] = i
	var keys = indexInst.keys()
	keys.sort()
	for i in keys.size():
		dumpList.append(indexInst[keys[i]])
		indexInst[keys[i]].Index = i
	Children = dumpList

func StartEditTitle(_layer):
	TitleEditLayer = _layer
	_layer.lineEdit.select(0,-1)
	_layer.lineEdit.grab_focus()
	_layer.titleButton.mouse_filter = Control.MOUSE_FILTER_IGNORE

func finshEditTitle():
	TitleEditLayer.lineEdit.deselect()
	TitleEditLayer.lineEdit.release_focus()
	TitleEditLayer.titleButton.mouse_filter = Control.MOUSE_FILTER_STOP
	TitleEditLayer = null

func deleteLayer(_layer):
	if ActiveLayer:
		ActiveLayer = false
		_layer.hide()
		_layer.Father.Children.erase(_layer)
		AllLayer.erase(_layer)
		_layer.hideLayer()
		rearrangeLayers()
		LayerManager.deleteLayer(_layer)

func getName(_father):
	var allNum:Array
	for i in _father.Children:
		if '.' in i.Title: 
			allNum.append(int(i.Title.split('.')[-1]))
	var i = 0 
	while true:
		i+=1
		if not(i in allNum): break
	return 'New Layer.' + str(i).pad_zeros(2)

# fake function don't deleted
func updateTapIcon():
	pass

func getFatherTree():
	return []

func _on_add_pressed():
	makeNewLayer()

func _on_delete_pressed():
	deleteLayer(ActiveLayer)


func _on_LayerPanel_2_resized():
	LayerSize.x = rect_size.x
	if Children.size():
		rearrangeLayers()
	
