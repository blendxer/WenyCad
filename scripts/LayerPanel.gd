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
onready var buttonShield = $buttonShield

var ColorActivate = Color(.5,.5,.5,.3)
var ColorDeactivate = Color(.2,.2,.2,.5)

var LayerColumn:Array # layerids sorted
var LayerSize:= Vector2(250,35)
var LevelShift = 30
var ConnectionLinesPnts:Array

var AllLayer:Array
var layerIdDict = {}
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
var TitleBeforeEdit:String

var OverlapState:int=0
var OverlapInstance:Control

var MoveColor_state:=false
var MoveColor_holdedColor:Color
var MoveColor_circle:Node2D


func _ready():
	layerHolder.rect_min_size = scroller.rect_size
	floater2.rect_size = layerHolder.rect_min_size
	LayerManager.LayerPanel = self
	MoveColor_circle = drawCircle(6,-rect_global_position)
	MoveColor_circle.hide()


func _input(event):
	if TitleEditLayer:
		if Input.is_action_just_pressed("ui_accept"):
			finshEditTitle()
		elif event is InputEventMouseButton:
			if event.button_index == 2:
				cancelEditTitle()
			
	elif holdLayerState:
		holdLayer(event)
		
	elif MoveColor_state:
		MoveColor_circle.position = get_global_mouse_position()
		if event is InputEventMouseButton:
			if !event.pressed and event.button_index == 1:
				applyMovingColor()
			if event.button_index == 2:
				cancelMovingColor()
				

func shieldState(_state):
	if _state:buttonShield.mouse_filter = 0 # stop
	else     :buttonShield.mouse_filter = 2 # ignore
	

func holdLayer(event):
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
		var dict = {}
		dict['id'] = IdMaker.getId(7)
		dict['name'] = 'New Layer.01'
		dict['father'] = self
		dict['level'] = 1
		dict['index'] = 1
		dict['visiblity'] = 0
		dict['color'] = Color('def2f5')
		dict['openState'] = 0
		
		var insta = dataToLayer(dict)
		Children.append(insta)
		ActiveLayer = insta
		insta.updateVisiblityIcons()
		columnWork()
		rearrangeLayers()
		
	else:
		if !ActiveLayer:
			WV.makeAd('20')
			return
		var dict = {}
		dict['id'] = IdMaker.getId(7)
		dict['name'] = getName(ActiveLayer.Father)
		dict['level'] = ActiveLayer.Father.Level + 1
		dict['index'] = ActiveLayer.Index - .1
		dict['visiblity'] = ActiveLayer.Father.VisiblityState
		dict['color'] = Color('def2f5')
		dict['openState'] = 0
		dict['father'] = ActiveLayer.Father
		
		var insta = dataToLayer(dict)
		ActiveLayer.Father.Children.append(insta)
		insta.Father.sortChildren()
		rearrangeLayers()
		ActiveLayer.Father.updateTapIcon()
		insta.updateVisiblityIcons()
		Undo.addNewChunk('addLayer',insta)
		columnWork()


func dataToLayer(_dict):
	var insta = SingleLayerSource.instance()
	insta.LayerId = _dict['id']
	layerIdDict[_dict['id']] = insta
	insta.GrandFather = self
	insta.Father = _dict['father']
	layerHolder.add_child(insta)
	insta.Level = _dict['level']
	insta.Index = _dict['index']
	AllLayer.append(insta)
	insta.changeTitle(_dict['name'])
	newActive(insta)
	insta.rect_size = LayerSize
	insta.VisiblityState = _dict['visiblity']
	insta.show_behind_parent=true
	LayerManager.makeNewLayer(insta.LayerId)
	insta.changeColor(_dict['color'])
	insta.OpenState = _dict['openState']
	return insta


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
	Undo.addNewChunk('moveLayer',[_holded,_holded.Father,_holded.Index])
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
	Undo.addNewChunk('moveLayer',[_child,_child.Father,_child.Index])
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
	var indexInst:Dictionary ={}
	for i in Children:
		indexInst[i.Index] = i
	var keys = indexInst.keys()
	keys.sort()
	for i in keys.size():
		dumpList.append(indexInst[keys[i]])
		indexInst[keys[i]].Index = i
	Children = dumpList

func StartEditTitle(_layer):
	# if there already layer in edit title mode -> finsh edit
	if TitleEditLayer:
		finshEditTitle()
	TitleBeforeEdit = _layer.Title
	TitleEditLayer = _layer
	_layer.lineEdit.select(0,-1)
	_layer.lineEdit.grab_focus()
	_layer.titleButton.mouse_filter = Control.MOUSE_FILTER_IGNORE


func finshEditTitle():
	TitleEditLayer.Title = TitleEditLayer.lineEdit.text
	if TitleEditLayer.Title !=  TitleBeforeEdit:
		Undo.addNewChunk('changeLayerName',[TitleEditLayer,TitleBeforeEdit])
	endTitleEdit()

func cancelEditTitle():
	TitleEditLayer.changeTitle(TitleBeforeEdit)
	endTitleEdit()

func endTitleEdit():
	TitleEditLayer.lineEdit.deselect()
	TitleEditLayer.titleButton.mouse_filter = Control.MOUSE_FILTER_STOP
	TitleEditLayer = null

func deleteLayer(_layer):
	if ActiveLayer:
		Undo.addNewChunk('removeLayer',ActiveLayer)
		ActiveLayer = false
		LayerManager.ActiveLayer = false
		_layer.hide()
		_layer.Father.Children.erase(_layer)
		AllLayer.erase(_layer)
		_layer.hideLayer()
		rearrangeLayers()
		LayerManager.deleteLayer(_layer)

func getName(_father):
	var allNum= []
	for i in _father.Children:
		if '.' in i.Title: 
			allNum.append(int(i.Title.split('.')[-1]))
	var i = 0 
	while true:
		i+=1
		if not(i in allNum): break
	return 'New Layer.' + str(i).pad_zeros(2)


func _on_add_pressed():
	makeNewLayer()

func _on_delete_pressed():
	deleteLayer(ActiveLayer)

# -f drawingScreen
func checkForDeleteLayer():
	var vec = get_local_mouse_position()
	if vec.x < 0 or vec.x > rect_size.x:
		return 
	if vec.y < 0 or vec.y > rect_size.y:
		return
	deleteLayer(ActiveLayer)


func deleteAllLayers():
	ActiveLayer = false
	for layer in AllLayer:
		layer.queue_free()
	
	layerIdDict.clear()
	Children.clear()
	AllLayer.clear()
	for obj in WV.drawingScreen.objectHolder.get_children():
		obj.queue_free()
	for obj in WV.drawingScreen.backupHolder.get_children():
		obj.queue_free()
	WV.drawingScreen.HolderIdDict.clear()
	LayerManager.LayerNodes.clear()
	LayerManager.LayerNodesBackup.clear()
	



# -f single layer 
func changeObjLayer(_layer):
	if !Input.is_action_pressed("ctrl") or !CheckIntersection.selectedObjects.size():
		return
	
	var layerOver = false
	var index = layerHolder.get_local_mouse_position().y/LayerSize.y
	if index < DisHeightArr.size():
		var diff = layerHolder.get_local_mouse_position().y - int(index) * LayerSize.y
		if diff >= 0 and DisHeightArr[index]!=HoldedChild:
			layerOver = DisHeightArr[index]
			
	if !layerOver:
		return
	var list = []
	for obj in CheckIntersection.selectedObjects:
		if ! obj in LayerManager.LayerNodes[layerOver.LayerId]:
			list.append(obj)
	if !list.size():
		return
	var ids = []
	for obj in list:
		ids.append(obj.LayerId)
		moveObjToLayer(obj,layerOver.LayerId)
	# deselect if the new layer is not visible
	if layerOver.VisiblityState:
		CheckIntersection.deselectAll()
	
	Undo.addNewChunk('changeObjLayer',[list,ids])

# +f undo
func moveObjToLayer(_obj,_newLayerId):
	WV.drawingScreen.moveObjToAnotherLayer(_obj,_newLayerId)
	LayerManager.LayerNodes[_newLayerId].append(_obj)
	LayerManager.LayerNodes[_obj.LayerId].erase(_obj)
	_obj.LayerId = _newLayerId
	var c = layerIdDict[_newLayerId].LayerColor
	_obj.objectColor = c
	_obj.changeColor(c)
	_obj.visible = !layerIdDict[_newLayerId].VisiblityState
	
func moveColor(_layer):
	MoveColor_state = true
	MoveColor_holdedColor = _layer.LayerColor
	MoveColor_circle.show()
	MoveColor_circle.color = _layer.LayerColor
	MoveColor_circle.position = get_global_mouse_position()

func applyMovingColor():
	MoveColor_circle.hide()
	MoveColor_state = false
	var index = layerHolder.get_local_mouse_position().y/LayerSize.y
	if index < DisHeightArr.size():
		var diff = layerHolder.get_local_mouse_position().y - int(index) * LayerSize.y
		#and DisHeightArr[index]!=HoldedChild
		if diff >= 0 :
			var layerOver = DisHeightArr[index]
			if MoveColor_holdedColor != layerOver.LayerColor:
				Undo.addNewChunk('changeLayerColor',[layerOver,layerOver.LayerColor])
				layerOver.changeColor(MoveColor_holdedColor)

func cancelMovingColor():
	MoveColor_circle.hide()
	MoveColor_state = false

func _on_LayerPanel_2_resized():
	if Children.size():
		rearrangeLayers()
	
func addLayerForUndo(insta):
	newActive(insta)
	LayerManager.ActiveLayer = insta
	ActiveLayer = insta
	insta.Index-=.1
	insta.Father.Children.append(insta)
	insta.Father.sortChildren()
	insta.Father.updateTapIcon()
	insta.show()
	AllLayer.append(insta)
	LayerManager.reshowLayer(insta)
	rearrangeLayers()
	
func removeLayerForUndo(insta):
	if ActiveLayer:
		ActiveLayer.deactivate()
	LayerManager.ActiveLayer = null
	insta.Father.Children.erase(insta)
	insta.Father.sortChildren()
	insta.Father.updateTapIcon()
	insta.hide()
	AllLayer.erase(insta)
	LayerManager.deleteLayer(insta)
	rearrangeLayers()

func moveChildForUndo(_list):
	var child = _list[0]
	var orignalFather = _list[1]
	var orignalIndex = _list[2]
	child.Father.Children.erase(child)
	child.Father.sortChildren()
	child.Father.updateTapIcon()
	child.Index = orignalIndex -.1
	
	orignalFather.Children.append(child)
	orignalFather.sortChildren()
	orignalFather.updateTapIcon()
	
	child.Father = orignalFather
	child.Level = orignalFather.Level + 1
	
	columnWork()
	rearrangeLayers()

func drawCircle(radius:int,pos):
	var circleReslution:float = 32
	var circleInstance = Polygon2D.new()
	add_child(circleInstance)
	var fraction:float
	var list= []
	for index in circleReslution:
		fraction = index/circleReslution
		var vec = polar2cartesian(radius,TAU*fraction)
		list.append(vec+pos)
	circleInstance.polygon = list
	return circleInstance

# fake function don't delete 
func updateTapIcon():
	pass

func getFatherTree():
	return []
