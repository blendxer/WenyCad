extends Node

var main
var mousePointer:Vector2
var scaleFac = 10
var allObject:Array
var allObjectBackup:Array
var firstObjectHitPnt:Vector2
var drawingScreen
var infoBoard
var saveImagePanel
var boardInfo
var cursor = Vector2(0,0)
var LastScaleBackup

var freeMotionLine:Array

var boardCenter:Vector2
var castEngineSize = Vector2(2880,2000)


var pieMenu_SelectBg = preload('res://scenes/drawing side/weldaan/pieMenu/selectGradient.tres')
var pieMenu_normalBg = preload('res://scenes/drawing side/weldaan/pieMenu/Normalgradient.tres')
var pieMenu_chooiceSource = preload('res://scenes/drawing side/weldaan/pieMenu/choose.tscn')
var pieMenu_lineSource = preload('res://scenes/drawing side/weldaan/pieMenu/bgLine.tscn')

func getBoundary(list):
	var min_ = Vector2(INF,INF)
	var max_ = Vector2(-INF,-INF)
	for pnt in list:
		if pnt.x < min_.x:
			min_.x = pnt.x
		if pnt.x > max_.x:
			max_.x = pnt.x
		if pnt.y < min_.y:
			min_.y = pnt.y
		if pnt.y > max_.y:
			max_.y = pnt.y
	return Rect2(min_,max_-min_)

func rectPntInter(pnt,rect):
	var shift = pnt - rect.position
	if shift.x >= 0 and shift.x < rect.size.x:
		if shift.y >= 0 and shift.y < rect.size.y:
			return true



var adSource = preload('res://scenes/drawing side/weldaan/ad.tscn')
var LastAd = false
func makeAd(_index):
	if LastAd : LastAd.queue_free()
	LastAd = adSource.instance()
	LastAd.changeTitle(ErrorMesseage.get(_index))
	drawingScreen.field.add_child(LastAd)

func vecToStr(_vec):
	_vec.y*=-1
	_vec = str(_vec)
	_vec = _vec.replace('(','')
	_vec = _vec.replace(')','')
	return _vec

func strToVec(_s):
	if not(',' in _s):
		_s += ',0'
	
	var x =  float(_s.split(',')[0])
	var y = -float(_s.split(',')[1])
	return Vector2(x,y)











