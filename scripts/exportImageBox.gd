extends Control

onready var bg = $ColorRect

var rect:Rect2
var rectBack:Rect2

var oldMousePos:Vector2
var startLock:Vector2
var endLock:Vector2

var tol = 20
var Mode = 0

var xClamp:Vector2
var yClamp:Vector2

func _ready():
	rect = SettingLog.fetch('exportImage/exportRect')
	bg.rect_position = rect.position
	bg.rect_size = rect.size
	make(rect)

func make(_rect):
	rect = _rect
	update()

func _draw():
	var pnts = [rect.position , Vector2(rect.end.x,rect.position.y),
	rect.end,Vector2(rect.position.x,rect.end.y),rect.position]
	
	var vec = Vector2(30,0)
	for i in 4:
		var mid = lerp(pnts[i],pnts[i+1],.5)
		draw_line(mid-vec+vec/3,mid+vec-vec/3,Color.white,2.0)
		draw_line(pnts[i],pnts[i]+vec,Color.white,2.0)
		vec*=-1
		draw_line(pnts[i+1],pnts[i+1]+vec,Color.white,2.0)
		vec = Vector2(vec.y,-vec.x)
		
func _input(event):
	if event is InputEventMouseButton:
		if event.button_index == 1:
			Mode = int(event.pressed)
			if event.pressed:
				checkPnt(get_local_mouse_position())
				
	if Mode == 1:
		var pnt = get_local_mouse_position()
		
		pnt.x = clamp(pnt.x , xClamp.x , xClamp.y)
		pnt.y = clamp(pnt.y , yClamp.x , yClamp.y)
		
		rect.position = rectBack.position +startLock*(pnt - oldMousePos)
		rect.end = rectBack.end +endLock*(pnt - oldMousePos)
		
		bg.rect_position = rect.position
		bg.rect_size = rect.size
		SettingLog.save('exportImage/exportRect',rect)
		update()
		
func checkPnt(_pnt):
	oldMousePos = _pnt   ;rectBack = rect
	startLock = Vector2();endLock = Vector2()
	
	if _pnt.x > rect.position.x and _pnt.x < rect.end.x:
		if abs(_pnt.y-rect.position.y) < tol: # up
			 startLock.y = 1
			 yClamp=Vector2(0,rect.end.y-100) 
			
		elif abs(_pnt.y-rect.end.y) < tol:     # down
			endLock.y   = 1
			yClamp=Vector2(rect.position.y+100,rect_size.y) 
		
	if _pnt.y > rect.position.y and _pnt.y < rect.end.y:
		if abs(_pnt.x-rect.position.x) < tol:# left
			 startLock.x = 1
			 xClamp=Vector2(0,rect.end.x-100)  
			
		elif abs(_pnt.x-rect.end.x) < tol:     # right
			endLock.x   = 1
			xClamp=Vector2(rect.position.x+100,rect_size.x) 
	
	var v = rect.size-rect.size/2
	var s = (_pnt - rect.position -v).abs()
	
	if (startLock.x or endLock.x) and (s.y >20 and s.y < v.y-30):
		startLock.x = 0 ; endLock.x = 0
		
	if (startLock.y or endLock.y) and (s.x > 20 and s.x < v.x-30):
		startLock.y = 0 ; endLock.y = 0 
	
	if not(startLock.x or startLock.y or endLock.x or endLock.y):
		if rect.has_point(_pnt):
			startLock = Vector2(1,1);endLock = Vector2(1,1)
			xClamp.y = rect_size.x -(rect.end.x - _pnt.x)
			yClamp.y = rect_size.y -(rect.end.y - _pnt.y)
			xClamp.x = _pnt.x - rect.position.x
			yClamp.x = _pnt.y - rect.position.y








