extends Control



var InnerRadius = 100
var OutterRadius = 250
var SubPieInstance:Array
var StepAngle
var Center:Vector2
var LastIndex = 0
var SelectIndex=0
var OrignalMousePos

var Options = ['cursor to active center',
				'cursor to selection center',
				'cursor to selection origin',
				'set position',
				'selection to cursor']

func _ready():
	Center = get_viewport_rect().size/2
	OrignalMousePos = get_global_mouse_position()
	Input.warp_mouse_position(Center)
	
	if CheckIntersection.selectedObjects.size():
		makeMenu(Options)
	else:
		setPosPanel()
	


func _input(event):
	if event is InputEventMouseMotion:
		var vec = get_global_mouse_position()-Center
		if vec.length()>50:
			var angle = vec.angle()
			angle = remainder(angle+TAU,TAU)
			var index = int(angle/StepAngle)
			if index != LastIndex:
				if LastIndex != INF:
					SubPieInstance[LastIndex].gradient= WV.pieMenu_normalBg
				LastIndex = index
				SubPieInstance[index].gradient= WV.pieMenu_SelectBg
				SelectIndex = index
		else:
			if LastIndex != INF:
				SubPieInstance[LastIndex].gradient= WV.pieMenu_normalBg
				LastIndex = INF
	
	if event is InputEventMouseButton:
		if event.pressed:
			if event.button_index==1:
				# check if there selection
				if LastIndex != INF:
					var option = Options[LastIndex]
					if option != 'set position':
						Organizer.cursor(option)
						Input.warp_mouse_position(OrignalMousePos)
						WV.main.panelRemover()
						queue_free()
					else:
						setPosPanel()
						
			if event.button_index==2:
				cancel()

func setPosPanel():
	WV.main.panelRemover()
	queue_free()
	WV.main.panelLoader('setCursorPos')

func cancel():
	Input.warp_mouse_position(OrignalMousePos)
	WV.main.panelRemover()
	queue_free()



func makeMenu(_list):
	var cnt  = _list.size()
	StepAngle = TAU/cnt
	
	for i in cnt:
		var insta = WV.pieMenu_chooiceSource.instance()
		insta.changeTitle(_list[i])
		var angle = i * StepAngle + StepAngle/2
		insta.rect_position = ((OutterRadius-InnerRadius)/2+InnerRadius) * Vector2(cos(angle),sin(angle)) + Center
		var line = WV.pieMenu_lineSource.instance()
		add_child(line)
		add_child(insta)
		line.gradient= WV.pieMenu_normalBg
		SubPieInstance.append(line)
		line.width = (OutterRadius-InnerRadius)/2
		for j in 10:
			var fac = float(j)/9
			# minus .1 and then plus .1 to make space between options
			angle = i * StepAngle + fac * (StepAngle-.1) + .1
			var vec = ((OutterRadius-InnerRadius)/2+InnerRadius) * Vector2(cos(angle),sin(angle)) + Center
			line.add_point(vec)
		
func remainder(num:float ,denum):
	return num-int(num/denum)*denum











