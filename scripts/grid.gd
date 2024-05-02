extends Control


onready var pointer = $pointer

var mainColor:Color = Color(1,1,1,.3)
var SubColor:Color = Color(.5,1,1,.2)


var GridSize:Vector2 = Vector2(100,100)
var SubGridSize = GridSize/5
var ScreenSize:Vector2
var OrignalSize:int # used by drawingScreen
var ScalingLimit:=Vector2(1,2000)
var MoveLimit = 1000000
var font = Control.new().get_font('font')

# animation
var ActionTime:float = .3 # in second
var Factor:float=0
var FinalGridSize:Vector2 = GridSize
var InitialGridSize:Vector2 = GridSize
var FinalScreenPos:Vector2 


var MoveShift:Vector2

var RectField:Rect2
var RectHalfSize:Vector2
var RectFieldCenter:Vector2

# prevent double shrink mouse pos 
# by check time delta
var LastTime:int 

var alignScreenState:bool = true
var vGrid = GridSize
var Level = 1.0
var Zoomability = true
var Dynamic = true


func _ready():
	Dynamic = SettingLog.fetch('gird/dynamicState')
	mainColor = SettingLog.fetch('gird/mainColor')
	SubColor = SettingLog.fetch('gird/subColor')
	
# warning-ignore:narrowing_conversion
	OrignalSize = GridSize.x
	ScreenSize = rect_size + 3*GridSize
	set_process(0)

func updateSetting(_dynamicState,_mainColor,_subColor):
	Dynamic = _dynamicState
	mainColor = _mainColor
	SubColor = _subColor
	lerpers(1)
	
	
	
func forceMove(_vec):
	pointer.rect_position += _vec
	WV.drawingScreen.onMotion(pointer.rect_position)
	update()

func input(event):
#	if Zoomability:
	if event is InputEventKey or event is InputEventMouseButton:
		if Input.is_action_just_pressed("pan"):
			MoveShift = pointer.rect_position - get_global_mouse_position() 
			WV.drawingScreen.dashBox.changeState('Pan',true)
			Input.set_mouse_mode(Input.MOUSE_MODE_CONFINED)
			
		elif Input.is_action_just_released("pan"):
			WV.drawingScreen.dashBox.changeState('Pan',false)
			Input.set_mouse_mode(Input.MOUSE_MODE_VISIBLE)
			MoveShift = Vector2()
				
		elif Input.is_action_just_pressed("f"):
			if WV.drawingScreen.insideField():
				alignScreen()
		
	if Input.is_action_pressed("pan"):
		
		pointer.rect_position = MoveShift + get_global_mouse_position() 
		WV.drawingScreen.onMotion(pointer.rect_position)
		update()
		
		if !RectField.has_point(get_global_mouse_position()):
			if (Time.get_ticks_msec()-LastTime) > 50:
				LastTime = Time.get_ticks_msec()
				var vec = get_global_mouse_position() - RectFieldCenter
				
				if vec.x <= -RectHalfSize.x or vec.x >= RectHalfSize.x:
					vec.x += sign(vec.x) * 30
					vec.x *= -1
				
				elif vec.y <= -RectHalfSize.y or vec.y >= RectHalfSize.y:
					vec.y += -sign(vec.y) * 30
					vec.y *= -1
				
				MoveShift += -(RectFieldCenter + vec) + get_global_mouse_position()
				Input.warp_mouse_position(RectFieldCenter + vec)
		
		if abs(pointer.rect_position.x) > MoveLimit or abs(pointer.rect_position.y) > MoveLimit:
			pointer.rect_position.x = clamp(pointer.rect_position.x,-MoveLimit,MoveLimit) 
			pointer.rect_position.y = clamp(pointer.rect_position.y,-MoveLimit,MoveLimit)
			WV.makeAd('9')
		
	if event is InputEventMouseButton:
		if event.pressed and event.button_index in [4,5]:
			if not(WV.drawingScreen.ZoomAblity):
				WV.makeAd('4')
				return
				
			if WV.drawingScreen.insideField():
				var sign_ = -2*(event.button_index-4)+1
				var v = GridSize.x + GridSize.x/2 * sign_
				v = clamp(v,ScalingLimit.x,ScalingLimit.y)
				v = round(v)
				FinalGridSize = Vector2.ONE * v
				InitialGridSize = GridSize
				Factor=0
				set_process(1)
				Zoomability = false


func _process(delta):
	Factor += delta/ActionTime
	if Factor <1:
		lerpers(Factor)
	else:
		lerpers(1)
		WV.drawingScreen.updateScaleVar()
		set_process(0)
		alignScreenState = true
		Zoomability = true
		
func lerpers(_fac):
	_fac = sqrt(_fac)
	if alignScreenState:
		var oldSize = GridSize.x
		var oldVec = pointer.rect_position - get_local_mouse_position()
		GridSize = lerp(InitialGridSize,FinalGridSize,_fac)
		var ratio = GridSize.x / oldSize
		var newVec = oldVec * ratio
		var vec = newVec - oldVec
		pointer.rect_position += vec
	else:
		GridSize = lerp(InitialGridSize,FinalGridSize,_fac)
		pointer.rect_position = lerp(pointer.rect_position,FinalScreenPos,_fac)
	
	if Dynamic:
		vGrid = GridSize * Level
		if   vGrid.x < 40 :Level *= 5
		elif vGrid.x > 300:Level /= 5
	else:
		vGrid = GridSize
		
	# update variable
	ScreenSize = rect_size + 3*vGrid
	SubGridSize = vGrid/5
	update()
	WV.drawingScreen.reDraw()
	WV.drawingScreen.onMotion(pointer.rect_position)


func _draw():
	var xBarsCnt = int(ScreenSize.x/vGrid.x)
	var yBarsCnt = int(ScreenSize.y/vGrid.y)
	var Shift:Vector2 = getOffset(pointer.rect_position) - vGrid
	
	# main grid
	for i in xBarsCnt:
		var x = i * vGrid.x
		draw_line(Vector2(x,0) + Shift
		,Vector2(x,ScreenSize.y) + Shift,mainColor,2)
		
	for i in yBarsCnt:
		var y = i * vGrid.y
		draw_line(Vector2(0,y) + Shift
		,Vector2(ScreenSize.x,y) + Shift,mainColor,2)
		
		var n = (pointer.rect_position.y -y-Shift.y)/GridSize.y
		draw_string(font,Vector2(10,y+Shift.y),str(n))
	
	# sub grid
	for i in xBarsCnt*5:
		if  i%5 != 0:
			var x = i * SubGridSize.x
			draw_line(Vector2(x,0) + Shift,
			Vector2(x,ScreenSize.y) + Shift ,SubColor)

	for i in yBarsCnt*5:
		if  i%5 != 0:
			var y = i * SubGridSize.y
			draw_line(Vector2(0,y) + Shift,
			Vector2(ScreenSize.x,y) + Shift,SubColor)

func alignScreen():
	var allPoints:Array = []
	if CheckIntersection.selectedObjects.size():
		for obj in CheckIntersection.selectedObjects:
			allPoints.append(obj.realRect.position)
			allPoints.append(obj.realRect.end)
	else:
		for layer in LayerManager.LayerPanel.AllLayer:
			if layer.VisiblityState == 0:
				for obj in LayerManager.LayerNodes[layer.LayerId]:
					allPoints.append(obj.realRect.position)
					allPoints.append(obj.realRect.end)
	
	if !allPoints.size():
		return
	
	var rect = WV.getBoundary(allPoints)
	var vec = WV.drawingScreen.field.rect_size / (rect.size+Vector2.ONE)
	FinalGridSize = min(vec.x , vec.y) * Vector2.ONE
	InitialGridSize = GridSize
	var centerOfRect = (rect.position + rect.size/2) * FinalGridSize.x
	var screenCenter = WV.drawingScreen.field.rect_size/2 - WV.drawingScreen.mainHolder.rect_position
	FinalScreenPos = pointer.rect_position + screenCenter - centerOfRect
	Factor=0
	set_process(1)
	alignScreenState = false
	Zoomability = false

func getOffset(vec):
	var xOffset = remainder(vec.x,vGrid.x)
	var yOffset = remainder(vec.y,vGrid.y)
	return Vector2(xOffset,yOffset)

func remainder(n ,d):
	return n-int(n/d)*d

func _on_grid_resized():
	ScreenSize = rect_size + 3*GridSize
	if WV.drawingScreen: WV.drawingScreen.changeFieldSize()
	update()






