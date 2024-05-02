extends Spatial

var objectDistributionSource = preload('res://scenes/drawing side/weldaan/objectDistribute/objectDistributePanel.tscn')
var setCursorPosSource = preload('res://scenes/drawing side/weldaan/pieMenu/cursor_setPosPanel.tscn')
var animationSettingSource = preload("res://scenes/drawing side/weldaan/animationSettingPanel.tscn")
var pieMenuSource = preload('res://scenes/drawing side/weldaan/pieMenu/pieMenu.tscn')
var QuitPanelSource = preload('res://scenes/drawing side/panels/quitPanel.tscn')
var snapMenSource = preload("res://scenes/drawing side/weldaan/snapMenu/snapMenu.tscn")
var world3dSource = preload('res://scenes/3d/world.tscn')
var settingPanelSource = preload("res://scenes/drawing side/weldaan/settingPanel.tscn")

var PanelDict = {}
var PanelMode = ''

onready var drawingScreen = $"drawing screen"
onready var FileDialog_ = $FileDialog
onready var VHpanel = $VHpanel
var World3d

func _ready():
	WV.main = self
	PanelDict['snapMenu'] = snapMenSource
	PanelDict['distributeMenu'] = objectDistributionSource
	PanelDict['pieMenu'] = pieMenuSource
	PanelDict['setCursorPos'] = setCursorPosSource
	PanelDict['animationSetting'] = animationSettingSource
	PanelDict['settingPanel'] = settingPanelSource
	


func switchSceneTo3d():
	drawingScreen.hide()
	drawingScreen.set_process_input(0)
	drawingScreen.set_process(0)
	World3d = world3dSource.instance()
	add_child(World3d)
	var fps = SettingLog.fetch('animation/fps')
	Engine.set_target_fps(fps)

func swtichSceneto2d():
	World3d.queue_free()
	drawingScreen.backTo2d()
	Engine.set_target_fps(0)


var LastQuitPanel=false
func quitPanel():
	if LastQuitPanel:
		LastQuitPanel.queue_free()
		LastQuitPanel = false
	else:
		LastQuitPanel = QuitPanelSource.instance()
		add_child(LastQuitPanel)


# +f VHPanel
func frezzeDrawingScreen(state):
	drawingScreen.set_process_input(state)
	drawingScreen.set_process(state)
	drawingScreen.hideCrossSnap()

var StateBackup
var CurrentPanel
func panelLoader(_panel):
	if PanelMode == '':
		PanelMode = _panel
		StateBackup = WV.drawingScreen.paintState
		WV.drawingScreen.changePaintState('panels')
		frezzeDrawingScreen(0)
		CurrentPanel = PanelDict[_panel].instance()
		add_child(CurrentPanel)
		WV.drawingScreen.buttonShieldState(0)

func panelRemover():
	PanelMode = ''
	WV.drawingScreen.changePaintState(StateBackup)
	frezzeDrawingScreen(1)
	WV.drawingScreen.buttonShieldState(1)
	

var FileDialogMode
var FileDialogInsta
var FileDialogFunc
func openFileDialog(_mode,_insta,_func):
	FileDialogMode = _mode
	FileDialogInsta = _insta
	FileDialogFunc = _func
	FileDialog_.get_line_edit().text = 'untitled'
	if 'save' in FileDialogMode:
		FileDialog_.mode = FileDialog.MODE_SAVE_FILE
		if 'file' in FileDialogMode:
			FileDialog_.window_title = 'save file'
			FileDialog_.set_filters(PoolStringArray(["*.gd ; WenyCad Files"]))
		if 'image' in FileDialogMode:
			FileDialog_.window_title = 'save image'
			FileDialog_.set_filters(PoolStringArray(["*.png ; PNG Images"]))
	if 'load' in FileDialogMode:
		FileDialog_.mode = FileDialog.MODE_OPEN_FILE
		FileDialog_.window_title = 'load file'
		FileDialog_.set_filters(PoolStringArray(["*.gd ; WenyCad Files"]))
	
	FileDialog_.popup_centered_ratio(.75)
	frezzeDrawingScreen(0)


func _on_FileDialog_file_selected(_p):
	var SelectedPath =  FileDialog_.current_path
	FileDialogInsta.callv(FileDialogFunc,[SelectedPath])
	frezzeDrawingScreen(1)

func _on_FileDialog_popup_hide():
	frezzeDrawingScreen(1)
