extends Line2D

var objectType = 'dot'
var DrawingType = 'specialDot'
var snapedPoint:Array
var objectColor 
var LayerId

var ActionsList:Array
var MeasureToolData:Dictionary
var RealBoardLine:Array = [Vector2(),Vector2()]

var circleInstance
var realPosition:Vector2
var realRect:Rect2

func copy():
	var dict = {}
	# copy as 'specialDot' and paste as dot
	dict['objectType'] = 'specialDot'
	dict['DrawingType'] = DrawingType
	dict['LayerId'] = LayerId
	dict['snapPnts'] = snapedPoint
	dict['realPosition'] = realPosition
	dict['realBoardLine'] = RealBoardLine
	dict['measureToolData'] = MeasureToolData
	dict['ActionsList'] = ActionsList
	return dict


func paste(dict):
	objectType = 'dot'
	DrawingType = dict['DrawingType']
	LayerId = dict['LayerId']
	snapedPoint = dict['snapPnts'].duplicate()
	realPosition = dict['realPosition']
	RealBoardLine = dict['realBoardLine'].duplicate(true)
	MeasureToolData = dict['measureToolData'].duplicate(true)
	var v = WV.drawingScreen.IndexSequenceDict[dict['ActionsList'][0][0]]
	ActionsList.append([v])
	MeasureToolData['index'] = v
	MeasureToolData['id'] = str(v)
	
	WV.allObject.append(self)
	var c = LayerManager.LayerPanel.layerIdDict[LayerId].LayerColor
	changeColor(c)
	objectColor = c
	updateRect()


func _ready():
	pass

func _init():
	drawCircle(3)

func makeDot(pos):
	circleInstance.position = pos
	realPosition = pos/WV.LastScaleBackup
	snapedPoint.append(realPosition)
	updateRect()
	ActionsList.append([ActionManager.getIndex()])
	return self
	
func updateRect():
	realRect.position = realPosition - Vector2(0.01,0.01)
	realRect.end = realPosition + Vector2(0.01,0.01)

func drawCircle(radius:int ):
	var circleReslution:float = 10
	circleInstance = Polygon2D.new()
	add_child(circleInstance)
	var fraction:float
	var list = []
	for index in circleReslution:
		fraction = index/circleReslution
		var vec = polar2cartesian(radius,TAU*fraction)
		list.append(vec)
	circleInstance.polygon = list

# fired from "Checkintersection.gd" globle script
func deselected():
	pass
	

# fired from "Checkintersection.gd" globle script
func selected():
	pass

# warning-ignore:unused_argument
func input(event):
	pass


func changeColor(_newColor):
	circleInstance.color = _newColor


func updateScaleVar(_newFactor):
	circleInstance.position = realPosition * _newFactor

func reDraw(_newFactor):
	circleInstance.position = realPosition * _newFactor

func applyScale(_vec,_value):
	liveScale(_vec,_value)
	realPosition = circleInstance.position/WV.LastScaleBackup
	RealBoardLine[0] = (RealBoardLine[1] -_vec) * _value + _vec
	RealBoardLine[1] = realPosition
	snapedPoint[0] = realPosition
	updateRect()
	
	
func liveScale(_vec,_value):
	circleInstance.position  = ((realPosition-_vec)*_value+_vec)*WV.LastScaleBackup


func finshMove(_shift):
	shiftObj(_shift)
	realPosition = realPosition + _shift
	RealBoardLine[0] = RealBoardLine[0] + _shift
	RealBoardLine[1] = realPosition
	snapedPoint[0] = realPosition
	updateRect()

func shiftObj(_shift):
	circleInstance.position  = ( realPosition+_shift) * WV.LastScaleBackup
	
func liveRotate(_vec,_angle):
	circleInstance.position = ((realPosition-_vec).rotated(_angle)+_vec) * WV.LastScaleBackup

func applyRotate(_vec,_angle):
	liveRotate(_vec,_angle)
	realPosition = (realPosition-_vec).rotated(_angle)+_vec
	RealBoardLine[0] = (RealBoardLine[0]-_vec).rotated(_angle)+_vec
	RealBoardLine[1] = realPosition
	snapedPoint[0] = realPosition
	updateRect()







