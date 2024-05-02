extends VBoxContainer

# constant
export(NodePath) var drawStraightLineBt
export(NodePath) var drawConnectionBt
export(NodePath) var imageExportBt
export(NodePath) var perpendicular
export(NodePath) var drawCircleBt
export(NodePath) var lengthLabel
export(NodePath) var saveAction
export(NodePath) var loadAction
export(NodePath) var ruler6030
export(NodePath) var alongLine
export(NodePath) var settingBt
export(NodePath) var compassor
export(NodePath) var exportBt
export(NodePath) var deleteBt
export(NodePath) var ruler45
export(NodePath) var mouseBt
export(NodePath) var undoBt
export(NodePath) var redoBt
export(NodePath) var dotBt


onready var alignLine = $downSide/field/holder/shield/mainObjectHolder/effect/alignLine2d
onready var initialHolder = $downSide/field/holder/shield/mainObjectHolder/initialHolder
onready var snapLine1 = $downSide/field/holder/shield/mainObjectHolder/effect/snapLine1
onready var snapLine2 = $downSide/field/holder/shield/mainObjectHolder/effect/snapLine2
onready var panelHolder = $downSide/leftPanel/VBoxContainer/ScrollContainer/panelHolder
onready var backupHolder = $downSide/field/holder/shield/mainObjectHolder/layerBackup
onready var selectBox = $downSide/field/ScrollContainer/shield/underHolder/selectBox
onready var objectHolder = $downSide/field/ViewportContainer/Viewport/steadyHolder
onready var boxShader = $downSide/field/holder/shield/mainObjectHolder/effect/box
onready var stredyHolderViewport = $downSide/field/ViewportContainer/Viewport
onready var underHolder = $downSide/field/ScrollContainer/shield/underHolder
onready var cursor = $downSide/field/holder/shield/mainObjectHolder/cursor
onready var mainHolder = $downSide/field/holder/shield/mainObjectHolder
onready var exportImageBoxHolder = $downSide/field/exportImageBoxHolder
onready var leftPanelSheild = $downSide/leftPanel/leftPanelShield
onready var undoCounter = $tools/HBoxContainer/undo/undoCounter
onready var redoCounter = $tools/HBoxContainer/redo/redoCounter
onready var grid = $downSide/field/ScrollContainer/shield/grid
onready var mousePointerIcon = $downSide/field/mousepointer
onready var toolSelectShield = $tools/toolSelectShield
onready var infoBoard = $downSide/field/infoBoard
onready var dashBox = $downSide/field/dashBox
onready var keycast = $downSide/field/keycast
onready var toolIconsHolder = $tools
onready var field = $downSide/field


var exportImageBoxSource = load('res://scenes/drawing side/randoms/exportImageBox.tscn')
var exportImagePancel = load('res://scenes/drawing side/panels/exportImagePanel.tscn')
var specialDotSource = load('res://scenes/drawing side/randoms/special dot.tscn')
var ButtonOverSource = load('res://scenes/drawing side/randoms/buttonOver.tscn')

var objectsPathes:Dictionary={
	'perpendicular':'res://scenes/drawing side/objects/perpendicular ruler object.tscn',
	'straight_line':'res://scenes/drawing side/objects/straight line object.tscn',
	'bezier':'res://scenes/drawing side/objects/connection object.tscn',
	'lengthLabel':'res://scenes/drawing side/objects/lengthLabel.tscn',
	'specialDot':'res://scenes/drawing side/randoms/special dot.tscn',
	'circle':'res://scenes/drawing side/objects/circle object.tscn',
	'compassor':'res://scenes/drawing side/objects/compassor.tscn',
	'ruler6030':'res://scenes/drawing side/objects/ruler6030.tscn',
	'alongLine':'res://scenes/drawing side/objects/alongLine.tscn',
	'ruler45':'res://scenes/drawing side/objects/ruler45.tscn',
	'dot':'res://scenes/drawing side/objects/dot object.tscn',
}
var panelsPath:Dictionary={
	'straight_line':'res://scenes/drawing side/panels/straight line panel.tscn',
	'perpendicular':'res://scenes/drawing side/panels/perpendicular panel.tscn',
	'lengthLabel':'res://scenes/drawing side/panels/length label panel.tscn',
	'bezier':'res://scenes/drawing side/panels/connection panel.tscn',
	'compassor':'res://scenes/drawing side/panels/compassor panel.tscn',
	'alongLine':'res://scenes/drawing side/panels/alongLine panel.tscn',
	'ruler6030':'res://scenes/drawing side/panels/ruler6030.tscn',
	'circle':'res://scenes/drawing side/panels/circle panel.tscn',
	'ruler45':'res://scenes/drawing side/panels/ruler45.tscn',
	'dot':'res://scenes/drawing side/panels/dot panel.tscn',
}


var PresettingPanelGlobalPath='res://scenes/drawing side/panels/presettingPanels/'
var availablePressettingPanels=['lengthLabel','compassor','circle']


var BtDict:Dictionary
var ToolDict:Dictionary
var FullDict:Dictionary
var ButtonOverList:Array
	
	
############# variable
var selectedToolName:String
var lastaddedObject
var lastPanel
var screenShift_buttonState:bool=false
var screenShift_shiftVect:Vector2
var SubtypePanel
var ActiveObjectHolder
var LineAlignState:bool= false
var LastSelectedTool:String
var ZoomAblity:=true
var LateUpdate:Array
var InstanceBackup # for undo
var CopyData:Array

# parameter
var paintState = 'idle'
var snapDis = 40

# line align
var LineALignMode = 'free'
var LineAlignPnt:Vector2

# select
var Selection_lastPnt:Vector2
var Selection_boxState: = false
var Selection_multi: = false # multiselection mode

# export image
var ExportImageBox
var ExportImageState:=false

func _ready():
	BtDict={
		'undoButton':undoBt,
		'redoButton':redoBt,
		'exportAction':exportBt,
		'saveActionBt':saveAction,
		'loadActionBt':loadAction,
		'deleteSelection':deleteBt,
		'imageExport':imageExportBt,
		'settingPanel':settingBt,
		'selectTool':mouseBt,
	}
	
	ToolDict={
		'straight_line':drawStraightLineBt,
		'circle':drawCircleBt,
		'bezier':drawConnectionBt,
		'dot':dotBt,
		'perpendicular':perpendicular,
		'ruler6030':ruler6030,
		'ruler45':ruler45,
		'lengthLabel':lengthLabel,
		'compassor':compassor,
		'alongLine':alongLine
	}
	FullDict.merge(ToolDict)
	FullDict['selectTool'] = mouseBt
	ButtonOverList = ToolDict.keys() + ['selectTool']
	
	
	WV.drawingScreen = self
	WV.infoBoard = infoBoard
	CheckIntersection.selectBox = selectBox
	LastScaleBackup= grid.GridSize.x
	WV.LastScaleBackup = LastScaleBackup
	keycast.visible = SettingLog.fetch('keycastShowState')
	connectButtons()
	
	# layer initalizing
	onMotion(Vector2())
	yield(get_tree().create_timer(.1),"timeout")
	LayerManager.LayerPanel.makeNewLayer()
	
	grid.forceMove(Vector2(100,field.rect_size.y-100))
	

func _input(event):
	if event is InputEventKey: 
		shortCut()
		lineAlign()
	grid.input(event)
	updateMousePos()
	updateBox()
	exportImagePro()
	
	for i in LateUpdate: i.input(event)
	test()


func test():
	if Input.is_action_pressed("k"):
		pass
		


func updateMousePos():
	if insideField():
		var v = get_global_mouse_position() - mainHolder.rect_global_position
		if Input.is_action_pressed("ctrl"):
			var realBoardMouse = v / LastScaleBackup
			var minDis= (WV.cursor-realBoardMouse).length()
			var closest = WV.cursor
			
			for layer in LayerManager.LayerPanel.AllLayer:
				if layer.VisiblityState == 0:
					for obj in LayerManager.LayerNodes[layer.LayerId]:
						for i in obj.snapedPoint:
							if abs(i.x-realBoardMouse.x) < minDis:
								if abs(i.y-realBoardMouse.y) < minDis:
									if minDis > (realBoardMouse-i).length():
										minDis = (realBoardMouse-i).length()
										closest = i
			
			if (realBoardMouse-closest).length()*LastScaleBackup < snapDis:
				v = closest * LastScaleBackup
				makeCrossSnap()
			else:
				hideCrossSnap()

		var v2 = lineAlignCheck(v)
		var c = v2/grid.GridSize.x
		c.y *=-1
		WV.infoBoard.updateMouse('Pointer',c)

		WV.mousePointer = v2
#		mousePointerIcon.rect_position =  WV.mousePointer + mainHolder.rect_position


func insideField() -> bool:
	var v = get_global_mouse_position() - field.rect_global_position 
	return v.x > 0 and v.x < field.rect_size.x and v.y > 0 and v.y < field.rect_size.y


func changePaintState(_newState):
	var fieldState = _newState in ['object_edit','painting']
	ZoomAblity = not(fieldState)
	LayerManager.LayerPanel.shieldState(fieldState)
	LineAlignState = _newState in ['idle','select']
	
	paintState = _newState

func shortCut():
	if Input.is_action_just_released("ctrl"):
		dashBox.changeState('Snap',false)
		hideCrossSnap()
	
	if get_focus_owner():
		return
		
	if Input.is_action_just_released("shift") :
		dashBox.changeState('Multi Selection',false)
	
	
	if Input.is_action_just_pressed("escape"):
		if paintState == 'painting':
			cancel_object()
		
		elif paintState == 'object_edit':
			CheckIntersection.selectedObjects[0].cancelEdit()
		
		elif paintState == 'idle':
			get_parent().quitPanel()
	
	if Input.is_action_pressed("ctrl"):
		dashBox.changeState('Snap',true)
	
	if ZoomAblity:
		if Input.is_action_just_pressed("shift"):
			dashBox.changeState('Multi Selection',true)
		
		if Input.is_action_pressed("ctrl"):
#			dashBox.changeState('Snap',true)
			updateMousePos()
			if Input.is_action_just_pressed("z"): undoButton()
			if Input.is_action_just_pressed("y"): redoButton()
			if Input.is_action_just_pressed("c"): copyObj()
			if Input.is_action_just_pressed("v"): pasteObj()
			if Input.is_action_just_pressed("x"): cutObj()
			if Input.is_action_just_pressed("s"): 
				dashBox.changeState('Snap',false)
				SaveLoadManager.saveAction()
			
		if Input.is_action_just_pressed("delete"):delete()
		
		
		if Input.is_action_pressed("shift"):
			if Input.is_action_just_pressed("a"): 
				WV.main.panelLoader('pieMenu')
				dashBox.changeState('Multi Selection',false)
			
			if Input.is_action_just_pressed("v"):
				duplicateObj()
			
			if Input.is_action_just_pressed("s"):
				dashBox.changeState('Multi Selection',false)
				
				if paintState != 'exportImage':
					if CheckIntersection.selectedObjects.size():
						WV.main.panelLoader('snapMenu')
					else:
						WV.makeAd('17')
			
			if Input.is_action_just_pressed("d"):
				dashBox.changeState('Multi Selection',false)
				if paintState != 'exportImage':
					if CheckIntersection.selectedObjects.size()>2:
						WV.main.panelLoader('distributeMenu')
					else:
						WV.makeAd('18')
	
	#####################################

# this func fired from grid 
# fired when the grid is moveing
func onMotion(_new):
	mainHolder.rect_position = _new
	objectHolder.rect_position = _new
	underHolder.rect_position = _new

# for double hit to change to othre axis
var AlignTimeCheck =0 
func lineAlign():
	if Input.is_action_just_pressed("y") or Input.is_action_just_pressed("x"):
		# cancel in case press x or y in textedit 
		if not(get_focus_owner() == null) or LineAlignState: return
		dashBox.changeState('cleanAxis') # there other one on reset func 
		var i = int(Input.is_action_just_pressed("y"))
		if Time.get_ticks_msec()-AlignTimeCheck < 250: i = abs(i-1)
		AlignTimeCheck = Time.get_ticks_msec()	
		var axis = ['x','y'][i]
		if axis == LineALignMode: 
			LineALignMode = 'free'
			selectBox.alignLock(Vector2(1,1))
			selectBox.MoveReferencePnt = selectBox.FirstHit
		else:
#			mousePointerIcon.show()
			LineALignMode = axis
			selectBox.alignLock(Vector2('x' == axis,'y' == axis))
			dashBox.changeState('Lock Axis : ' + axis ,true)
			# if there selected obj pos2d should be LineAlignPnt
			if CheckIntersection.selectedObjects.size():
				selectBox.MoveReferencePnt = selectBox.pos2d.position
				LineAlignPnt = selectBox.pos2d.position * LastScaleBackup
			else:
				LineAlignPnt = WV.firstObjectHitPnt
		updateMousePos()
		makeAlignLine()



func makeAlignLine():
	if LineALignMode == 'x':
		alignLine.points[0]= LineAlignPnt -Vector2(1000,0)
		alignLine.points[1]= LineAlignPnt +Vector2(1000,0)
		alignLine.default_color = Color(1,0,0,.6)
		alignLine.show()
		
	elif LineALignMode == 'y':
		alignLine.points[0]= LineAlignPnt -Vector2(0,1000)
		alignLine.points[1]= LineAlignPnt +Vector2(0,1000)
		alignLine.default_color = Color(0,1,0,.6)
		alignLine.show()
	else:
		resetAlignLine()

func resetAlignLine():
	alignLine.points[0]= Vector2()
	alignLine.points[1]= Vector2()
	alignLine.hide()
#	mousePointerIcon.hide()

func lineAlignCheck(_pnt):
	if LineALignMode == 'free': return _pnt
	elif LineALignMode == 'x':  return Vector2(_pnt.x,LineAlignPnt.y)
	elif LineALignMode == 'y':  return Vector2(LineAlignPnt.x,_pnt.y)

func makeCrossSnap():
	snapLine1.points[0] = Vector2(-1000,0)+WV.mousePointer
	snapLine1.points[1] = Vector2(1000,0) +WV.mousePointer
	snapLine2.points[0] = Vector2(0,-1000)+WV.mousePointer
	snapLine2.points[1] = Vector2(0,1000) +WV.mousePointer

func hideCrossSnap():
	snapLine1.points[0] = Vector2();snapLine1.points[1] = Vector2()
	snapLine2.points[0] = Vector2();snapLine2.points[1] = Vector2()



var LastScaleBackup:float
func updateScaleVar():
	LastScaleBackup = grid.GridSize.x
	WV.LastScaleBackup = grid.GridSize.x
	WV.scaleFac = 10 * grid.GridSize.x / grid.OrignalSize
	for obj in WV.allObject:
		obj.updateScaleVar(grid.GridSize.x)

func reDraw():
	for obj in WV.allObject:
		obj.reDraw(grid.GridSize.x)
	selectBox.zoomUpdate(grid.GridSize.x)
	cursor.rect_position = WV.cursor * grid.GridSize.x

func changeCursorPos(_new):
	WV.cursor = _new
	reDraw()

func paintNewObject():
	# add object
	lastaddedObject = load(objectsPathes[selectedToolName]).instance()
	lastaddedObject.connect('finsh_object',self,'finsh_object')
	initialHolder.add_child(lastaddedObject)
	var oneTouchObjCheck = lastaddedObject.initiateObject()
	LateUpdate.append(lastaddedObject)
	InstanceBackup = lastaddedObject
	# reference the new added object to the active layer
	addChildToActiveLayer(lastaddedObject)
	# attach panel
	lastPanel = load(panelsPath[selectedToolName]).instance()
	panelHolder.add_child(lastPanel)
	panelHolder.rect_min_size.y = lastPanel.rect_min_size.y
	lastPanel.object = lastaddedObject
	
	if oneTouchObjCheck:
		lastaddedObject.finshProcess()

func dataToObject(_dict):
	var insta = load(objectsPathes[_dict['objectType']]).instance()
	HolderIdDict[_dict['LayerId']].add_child(insta)
	var id = _dict['LayerId']
	LayerManager.addChildToCertainLayer(id,insta)
	var color = LayerManager.LayerPanel.layerIdDict[id].LayerColor
	insta.objectColor = color
	insta.changeColor(color)
	insta.paste(_dict)
	return insta

func fieldBt():
	# paint new object
	if paintState == 'idle':
		# check if there active layer
		if LayerManager.ActiveLayer:
			# check if object type selected
			if selectedToolName == '':
				WV.makeAd('5')
			else:
				if   SubtypePanel : SubtypePanel.visible = false
				if  !LayerManager.LayerPanel.ActiveLayer: WV.makeAd('0')
				elif LayerManager.LayerPanel.ActiveLayer.VisiblityState != 0:WV.makeAd('11')
				else:
					changePaintState('painting')
					paintNewObject()
				
				
	# pass the press to the object
	elif paintState == 'painting':
		if insideField():lastaddedObject.fieldButton()
	
	elif paintState == 'select':
		makeSelection()
		
	elif paintState == 'object_edit':
		CheckIntersection.selectedObjects[0].fieldButton()
	
	reset()

# +f selectBox
func reset():
	hideCrossSnap()
	selectBox.releaseMouseBt()
	resetAlign()
	KeyboardHandler.reset()

func makeSelection():
	if !Input.is_action_pressed("shift") and !Input.is_action_pressed("alt"): 
		CheckIntersection.deselectAll()
		
	if Input.is_action_pressed("shift") and Input.is_action_pressed("alt"): 
		WV.makeAd('10')
	
	else:
		# point selection
		if Selection_lastPnt ==  WV.mousePointer: 
			CheckIntersection.checkSelect(WV.mousePointer/LastScaleBackup,
			Input.is_action_pressed("alt"))
		# box selection
		else:                                     
			var rect = WV.getBoundary([Selection_lastPnt/grid.GridSize.x,
			WV.mousePointer/grid.GridSize.x])
			CheckIntersection.boxSelection(rect,Input.is_action_pressed("alt"))
		
	# hide boxShader
	Selection_boxState = false
	boxShader.points[0] = Vector2()
	boxShader.points[1] = Vector2()
	boxShader.width = 0

var BoxShaderColor = [Color('caffffff'),Color('f0101010')]
func _on_field_button_down():
	selectBox.leftFieldBt()
	if paintState == 'select':
		boxShader.default_color = BoxShaderColor[int(Input.is_action_pressed("alt"))]
		Selection_lastPnt = WV.mousePointer
		Selection_boxState = true
		
func updateBox():
	if Selection_boxState:
		var vec = 0.5*(WV.mousePointer- Selection_lastPnt)
		boxShader.points[0] = WV.mousePointer + Vector2(0,-vec.y)
		boxShader.points[1] = Selection_lastPnt + Vector2(0,vec.y)
		boxShader.width = 2 * abs(vec.y)

func right_field():
	resetAlign()
	if paintState == 'select':
		if !Input.is_action_pressed("shift"):
			if CheckIntersection.selectedObjects.size():
				CheckIntersection.deselectAll()
				CheckIntersection.removePanel()
			else:                                       
				selectDrawTool(LastSelectedTool)
		
	elif paintState == 'idle':
		buttonControlManager('selectTool')

	elif paintState == 'painting':
		cancel_object()

	elif paintState == 'object_edit':
		CheckIntersection.selectedObjects[0].cancelEdit()
		CheckIntersection.deselectAll()
		CheckIntersection.removePanel()
		changePaintState('select')
	
	elif paintState == 'transform':
		selectBox.rightFieldbt()

func resetAlign():
	dashBox.changeState('cleanAxis')
	resetAlignLine()
	# align setting
	LineALignMode = 'free'
	updateMousePos()
	WV.firstObjectHitPnt = WV.mousePointer
	
func cancel_object():
	reset()
	infoBoard.reset()
	if SubtypePanel:
		SubtypePanel.visible = true
	changePaintState('idle')
	lastPanel.queue_free()
	LayerManager.removeObjFromLayerArr(lastaddedObject)
	LateUpdate.erase(lastaddedObject)
	lastaddedObject.queue_free()
	lastPanel=0

func finsh_object():
	reset()
	initialHolder.remove_child(lastaddedObject)
	HolderIdDict[LayerManager.ActiveLayer.LayerId].add_child(lastaddedObject)
	LateUpdate.erase(lastaddedObject)
	Undo.addNewChunk('addObj',[InstanceBackup]) 
	infoBoard.reset()
	resetAlign()
	if SubtypePanel:
		SubtypePanel.visible = true
		panelHolder.rect_min_size.y = SubtypePanel.rect_min_size.y
		
	changePaintState('idle')
	if lastPanel:
		lastPanel.queue_free()
	lastPanel=0

# work
# -f layer panel
func moveObjToAnotherLayer(_obj,_newLayerId):
	HolderIdDict[_obj.LayerId].remove_child(_obj)
	HolderIdDict[_newLayerId].add_child(_obj)

func connectButtons():
	for _tool in ToolDict:
# warning-ignore:return_value_discarded
		get_node(ToolDict[_tool]).connect("pressed",self,'selectDrawTool',[_tool])
	for bt in BtDict:
# warning-ignore:return_value_discarded
		get_node(BtDict[bt]).connect("pressed",self,'buttonControlManager',[bt])

func imageExport():
	# to avoide more than one press
	if !ExportImageState:
		changePaintState('exportImage')
		paintState = 'exportImage'
		ExportImageState = true
		CheckIntersection.deselectAll()
		ExportImageBox = exportImageBoxSource.instance()
		exportImageBoxHolder.add_child(ExportImageBox)
		
		if SubtypePanel:
			SubtypePanel.queue_free()
			SubtypePanel = false
			
		lastPanel = exportImagePancel.instance()
		panelHolder.add_child(lastPanel)
		panelHolder.rect_min_size.y = lastPanel.rect_min_size.y
		lastPanel.minViewportTexture.texture =  stredyHolderViewport.get_viewport().get_texture()
		LastRectSize = Vector2()
		

func removeImageExportBox():
	ExportImageState = false
	ExportImageBox.queue_free()
	lastPanel.queue_free()

var LastRectSize=Vector2()
func exportImagePro():
	if ExportImageState:
		var ratio = ExportImageBox.rect.size.x/ExportImageBox.rect.size.y
		var max_ = max(ExportImageBox.rect.size.x,ExportImageBox.rect.size.y)
		if max_ == ExportImageBox.rect.size.x:
			lastPanel.board.rect_min_size = Vector2(190,190/ratio)
			lastPanel.board.rect_size = Vector2(190,190/ratio)
		else:
			lastPanel.board.rect_min_size = Vector2(190*ratio,190)
			lastPanel.board.rect_size = Vector2(190*ratio,190)
		
		lastPanel.minViewportTexture.rect_position = -ExportImageBox.rect.position
		if ExportImageBox.rect.size != LastRectSize:
			LastRectSize = ExportImageBox.rect.size
			lastPanel.changeSize(ExportImageBox.rect.size)

# work
func settingPanel():
	LastPaintState = paintState
	WV.main.panelLoader('settingPanel')
	
	
func buttonControlManager(_btName):
	makeButtonOverImage(_btName)
	if paintState == 'painting':  cancel_object()
	call(_btName)

func saveActionBt(): SaveLoadManager.saveAction()
func loadActionBt(): SaveLoadManager.getLoadPath()


var LastPaintState
func exportAction():
	if !checkIfThereActionforExport():
		WV.makeAd('7')
		return
	LastPaintState = paintState
	WV.main.panelLoader('animationSetting')

func checkIfThereActionforExport():
	for layer in LayerManager.LayerPanel.AllLayer:
		if layer.VisiblityState == 0:
			for obj in LayerManager.LayerNodes[layer.LayerId]:
				return true

func backTo2d():
	paintState = LastPaintState
	set_process_input(1)
	set_process(1)
	show()

var lastAddedRecOver = null
func makeButtonOverImage(_instanceName):
	if not lastAddedRecOver:
		lastAddedRecOver = ButtonOverSource.instance()
		toolIconsHolder.add_child(lastAddedRecOver)
	
	
	if _instanceName in ButtonOverList:
		var instance = get_node(FullDict[_instanceName])
		lastAddedRecOver.rect_position = instance.rect_position
		lastAddedRecOver.rect_size = instance.rect_size


# thic func return instance of dot
func makeSnapPnt(pos):
	var point = specialDotSource.instance()
	initialHolder.add_child(point)
	InstanceBackup = point
	addChildToActiveLayer(point)
	return point.makeDot(pos)


func makeLine(_p1,_p2):
	# add object
	var newLine = load(objectsPathes['straight_line']).instance()
	initialHolder.add_child(newLine)
	InstanceBackup = newLine
	# reference the new added object to the active layer
	addChildToActiveLayer(newLine)
	return newLine.makeLine(_p1,_p2)


func selectDrawTool(toolName):
	if CheckIntersection.selectedObjects.size():
		if paintState == 'object_edit':
			CheckIntersection.selectedObjects[0].cancelEdit()
		CheckIntersection.deselectAll()
		
	makeButtonOverImage(toolName)
	if paintState == 'painting':
		cancel_object()
	
		
	elif paintState == 'exportImage':
		removeImageExportBox()
	
	if SubtypePanel:
		SubtypePanel.queue_free()
		SubtypePanel = false
	
	# attach subtype panel if there one for new toolName
	if toolName in availablePressettingPanels:
		var panelPath = PresettingPanelGlobalPath + toolName + '_Subpanel.tscn'
		SubtypePanel = load(panelPath).instance()
		panelHolder.add_child(SubtypePanel)
		panelHolder.rect_min_size.y = SubtypePanel.rect_min_size.y
		
	
	changePaintState('idle')
	selectedToolName = toolName
	LastSelectedTool = toolName


func undoButton(): Undo.undo()
func redoButton(): Undo.redo()


func delete():
	if insideField():deleteSelection()
	else:LayerManager.LayerPanel.checkForDeleteLayer()

# +f selectBox
func deleteSelection():
	if !CheckIntersection.selectedObjects.size():
		WV.makeAd('3')
		return 
	var list = CheckIntersection.selectedObjects.duplicate()
	CheckIntersection.deselectAll()
	for obj in list:
		deleteObj(obj)
	Undo.addNewChunk('removeObj',list)


# +f layerManager
func deleteObj(obj):
	if obj in CheckIntersection.selectedObjects:
		CheckIntersection.deselectObj(obj)
	LayerManager.removeObjFromLayerArr(obj)
	WV.allObject.erase(obj)
	obj.hide()

func addObj(obj):
	LayerManager.addObjtoLayer(obj)
	WV.allObject.append(obj)
	obj.show()

var HolderIdDict:Dictionary
func makeNewLayer(_id):
	ActiveObjectHolder = Control.new()
	objectHolder.add_child(ActiveObjectHolder)
	HolderIdDict[_id] = ActiveObjectHolder

# f layermanager
func deleteObjectHolder(_id):
	objectHolder.remove_child(HolderIdDict[_id])
	backupHolder.add_child(HolderIdDict[_id])

# -f undo script
func reshowObjectHolder(_id):
	backupHolder.remove_child(HolderIdDict[_id])
	objectHolder.add_child(HolderIdDict[_id])

# -f undo script
func terminateLayerHolder(_id):
	HolderIdDict[_id].queue_free()
# warning-ignore:return_value_discarded
	HolderIdDict.erase(_id)

func updateColumn(_newColumn):
	_newColumn.invert()
	var index = 0
	for id in _newColumn:
		objectHolder.move_child(HolderIdDict[id],index)
		index+=1


var MeasureTool = ['alongLine','perpendicular_ruler','compassor','ruler45','ruler6030']
func addChildToActiveLayer(_child):
	if _child.objectType in MeasureTool: 
		return
	_child.LayerId = LayerManager.ActiveLayer.LayerId
	var color = LayerManager.ActiveLayer.LayerColor
	_child.objectColor = color
	_child.changeColor(color)
	LayerManager.addChildToLayer(_child)

func selectTool():
	if SubtypePanel:
		SubtypePanel.queue_free()
		SubtypePanel = false
	
	if paintState == 'exportImage':
		removeImageExportBox()
	changePaintState('select')
	
var CopyCenter:Vector2
func copyObj():
	CopyData.clear()
	CopyCenter = (selectBox.MaxPos+selectBox.MinPos)/(2*LastScaleBackup)
	for obj in CheckIntersection.selectedObjects:
		CopyData.append(obj.copy())

var IndexSequenceDict = {}
func pasteObj(_shiftState=true):
	if !LayerManager.LayerPanel.ActiveLayer:
		WV.makeAd('0')
		return
	
	if !CopyData.size():
		WV.makeAd('24')
		return
	
	IndexSequenceDict.clear()
	var allIndexes = []
	for data in CopyData:
		var type = typeof(data['ActionsList'][0])
		if type == TYPE_INT:
			allIndexes.append(data['ActionsList'][0])
		if type == TYPE_ARRAY:
			for list in data['ActionsList']:
				allIndexes.append(list[0])
		if 'measureToolData' in data and 'index' in data['measureToolData']:
			allIndexes.append(data['measureToolData']['index'])
	allIndexes.sort()
	for i in allIndexes:
		IndexSequenceDict[i] = ActionManager.getIndex()
	var arr = []
	var vec = WV.mousePointer/LastScaleBackup-CopyCenter
	for data in CopyData:
		var insta = dataToObject(data)
		arr.append(insta)
		if _shiftState:
			insta.finshMove(vec)
	Undo.addNewChunk('addObj',arr)
	CheckIntersection.deselectAll()
	CheckIntersection.selectGroup(arr)

func duplicateObj():
	copyObj()
	pasteObj(false)

func cutObj():
	if !LayerManager.LayerPanel.ActiveLayer:
		WV.makeAd('0')
		return
	copyObj()
	delete()

func loadObj(dict):
	var insta = load(objectsPathes[dict['objectType']]).instance()
	HolderIdDict[dict['LayerId']].add_child(insta)
	insta.paste(dict)
	if 'ActionsList' in dict:
		insta.ActionsList = dict['ActionsList']
	return insta


func buttonShieldState(_state):
	leftPanelSheild.mouse_filter = 2 * int(_state)
	toolSelectShield.mouse_filter = 2 * int(_state)

# fired when field button resized
func changeFieldSize():
	if ExportImageState:
		lastPanel.queue_free()
		lastPanel = exportImagePancel.instance()
		panelHolder.add_child(lastPanel)
		panelHolder.rect_min_size.y = lastPanel.rect_min_size.y
		lastPanel.minViewportTexture.texture =  stredyHolderViewport.get_viewport().get_texture()
	
	grid.RectField.position = field.rect_global_position
	grid.RectField.size = field.rect_size - Vector2(1,1)
	grid.RectHalfSize = field.rect_size/2 - Vector2(1,1)
	grid.RectFieldCenter = grid.RectField.position + grid.RectField.size/2
	grid.update()
