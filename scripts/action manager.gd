extends Node

var PreActionArr:Array
var SortBackup:Dictionary

var transformFac:float = .01
var ActionIndex = 0

# boundies of the 2d disk
var boardCenter:Vector2
var MinPos:Vector2 = Vector2(INF,INF) 
var MaxPos:Vector2 = Vector2(-INF,-INF)



func getIndex():
	ActionIndex+=1
	return ActionIndex

func buildActions():
	for layer in LayerManager.LayerPanel.AllLayer:
		if layer.VisiblityState == 0:
			for obj in LayerManager.LayerNodes[layer.LayerId]:
				fillDictionary(obj)
	
	for i in ActionIndex+1:
		if i in SortBackup:
			PreActionArr.append(SortBackup[i])
			
func fillDictionary(obj):
	var id = ''
	var mainType = obj.DrawingType.split('/')[0]
	if obj.objectType == 'circle':
		for action in obj.ActionsList:
			var dict = {}
			if id == '':
				dict['DrawingType'] = 'caliper'
				dict['circlePos/oneLayer'] = [obj.realCirclePos]
				dict['visibleLineSeqment'] = [obj.CircleBoundary]
				dict['caliperWidth'] = scale1Pnt(obj.realCircleRadius)
				id = str(action[0])
				dict['id'] = str(action[0])
				dict['index'] = action[0]
				
			else:
				dict['DrawingType'] = 'erase/circle'
				dict['circleRadius'] = scale1Pnt(obj.realCircleRadius) 
				dict['id'] = id
				dict['activeAngle']  = action[1]
				dict['angleSeqment'] = action[2]
				dict['index']        = action[0]
			
			SortBackup[dict['index']] = dict.duplicate()
	
	elif obj.objectType == 'straight_line':
		for action in obj.ActionsList:
			var dict = {}
			if id.empty():
				match mainType:
					'ruler':
						dict['DrawingType'] = obj.DrawingType 
						dict['points/oneLayer'] = obj.RealBoardLine.duplicate(true)
						dict['index'] = action[0]
						id = str(action[0])
						dict['id'] = str(action[0])
						
					'alongLine':
						dict = alongLine(obj)
						
					'ruler45':
						dict = ruler45(obj)
					
					'perpendicular_ruler':
						dict = ruler45(obj)
					
					'ruler6030':
						dict = ruler6030(obj)
					
			else:
				var vec = (obj.RealBoardLine[1]-obj.RealBoardLine[0]).normalized()
				var l =  (obj.RealBoardLine[1]-obj.RealBoardLine[0]).length()
				dict['id'] = id
				dict['index']  = action[0]
				dict['DrawingType'] = 'erase/line'
				dict['activeSeqment/oneLayer'] = getPntFormVec(action[1],vec,l,obj.RealBoardLine[0])
				dict['lineSeqment/twoLayer']   = getPntFormVecList(action[2],vec,l,obj.RealBoardLine[0])
			
			if id.empty():
				id = dict['id']
				
			SortBackup[dict['index']] = dict.duplicate()
			
	elif obj.objectType == 'dot':
		match mainType:
			"alongLine":          SortBackup[obj.MeasureToolData['index']] = alongLine(obj)
			"ruler45":            SortBackup[obj.MeasureToolData['index']] = ruler45(obj)
			'ruler6030':          SortBackup[obj.MeasureToolData['index']] = ruler6030(obj)
			'perpendicular_ruler':SortBackup[obj.MeasureToolData['index']] = ruler45(obj)
			'compassor':          SortBackup[obj.MeasureToolData['index']] = compassor(obj)
			'dot':                SortBackup[obj.ActionsList[0]] = dotObject(obj)
				
	elif obj.objectType == 'bezier':
		var dict= {}
		dict['DrawingType'] = obj.objectType
		dict['bezier/twoLayer'] = obj.pointsRealPos.duplicate(true)
		SortBackup[obj.ActionsList[0][0]] = dict
		
		
		

func compassor(obj):
	var dict = {}
	dict['DrawingType'] = obj.MeasureToolData['DrawingType']
	dict['points/oneLayer'] = obj.RealBoardLine.duplicate(true)
	dict['angle'] = obj.MeasureToolData['angle']
	dict['mainAngle'] = obj.MeasureToolData['mainAngle']
	return dict

func dotObject(obj):
	var dict = {}
	dict['DrawingType'] = 'dot/free'
	if obj.realFirstHit == obj.realPosition:
		dict['DrawingType'] = 'dot/free'
	elif obj.realFirstHit.y == obj.realPosition.y:
		dict['DrawingType'] = 'dot/horizantal'
	elif obj.realFirstHit.x == obj.realPosition.x:
		if obj.realFirstHit.y < obj.realPosition.y:
			dict['DrawingType'] = 'dot/down'
		else:
			dict['DrawingType'] = 'dot/vertical'
	dict['dotPoints/oneLayer'] = [obj.realFirstHit,obj.realPosition]
	return dict
	

func ruler6030(obj):
	var dict = obj.MeasureToolData
	dict['actualLine/oneLayer'] = obj.RealBoardLine.duplicate()
	dict['AlignLineAngle'] = (obj.RealBoardLine[1]-obj.RealBoardLine[0]).angle()
	dict['index'] = obj.MeasureToolData['index']
	dict['id'] = str(dict['index'])
	return dict

func ruler45(obj):
	var dict = {}
	dict = obj.MeasureToolData
	dict['actualLine/oneLayer'] = obj.RealBoardLine.duplicate(true)
	dict['AlignLineAngle'] = (obj.RealBoardLine[1]-obj.RealBoardLine[0]).angle()
	dict['index'] = obj.MeasureToolData['index']
	dict['id'] = str(dict['index'])
	return dict

func alongLine(obj):
	var dict = {}
	dict['DrawingType'] = obj.MeasureToolData['DrawingType']
	dict['values'] = obj.MeasureToolData['values']
	
	dict['actualLine/oneLayer'] =  obj.RealBoardLine.duplicate(true)
	
	if   obj.RealBoardLine[0].x == obj.RealBoardLine[1].x : dict['type'] = 'vertical'
	elif obj.RealBoardLine[0].y == obj.RealBoardLine[1].y : dict['type'] = 'horizantal'
	else:                                                   dict['type'] = 'free'
	
	dict['index'] = obj.MeasureToolData['index']
	dict['id'] = str(dict['index'])
	
	return dict


func getPntFormVec(list,vec,length,shift):
	var arr = []
	arr.append(list[0] * length * vec + shift)
	arr.append(list[1] * length * vec + shift)
	return arr

func getPntFormVecList(listList,vec,l,shift):
	var arr = []
	for list in listList: arr.append(getPntFormVec(list,vec,l,shift))
	return arr



func add_action(_dict):
	var id = str(ActionIndex)
	_dict['index'] = ActionIndex
	_dict['id'] = id
	_dict['instance'].Id = id 
	PreActionArr.append(_dict)
	ActionIndex+=1
	
func add_erase_action(_dict):
	_dict['index'] = ActionIndex
	PreActionArr.append(_dict)
	ActionIndex+=1


func transform1Pnt(_pnt):
	return (_pnt*transformFac).rotated(1.57)

func scale1Pnt(_pnt):
	return _pnt*transformFac

func transformPnts():
	PreActionArr.clear()
	SortBackup.clear()
	MinPos = Vector2(INF,INF) 
	MaxPos = Vector2(-INF,-INF)
	buildActions()
	if !PreActionArr.size():
		return 
	var index = -1
	for dict in PreActionArr:
		index+=1
		for item in dict:
			# two layer depMoveShiftScaledth
			if 'twoLayer' in item:
				for i in PreActionArr[index][item].size():
					for j in PreActionArr[index][item][i].size():
						checkBondires(PreActionArr[index][item][i][j])
						PreActionArr[index][item][i][j] = (PreActionArr[index][item][i][j]*transformFac).rotated(1.57)
						
			# one layer depth
			elif 'oneLayer' in item:
				for i in PreActionArr[index][item].size():
					checkBondires(PreActionArr[index][item][i])
					PreActionArr[index][item][i] = (PreActionArr[index][item][i]*transformFac).rotated(1.57)
					
	# calculate the center point
	var centerPnt = Vector2(MaxPos.x+MinPos.x,MaxPos.y+MinPos.y)/2
	centerPnt = (centerPnt * transformFac).rotated(1.57)
	
	# shift to swap all the points to the center
	var shift:Vector2 = boardCenter - centerPnt
	
	index = -1
	for dict in PreActionArr:
		index+=1
		for item in dict:
			# two layer depth
			if 'twoLayer' in item:
				for i in PreActionArr[index][item].size():
					for j in PreActionArr[index][item][i].size():
						PreActionArr[index][item][i][j] += shift 
						
			# one layer depth
			elif 'oneLayer' in item:
				for i in PreActionArr[index][item].size():
					PreActionArr[index][item][i] += shift
					
func checkBondires(vec):
	# define the outer boundry of 2d dawring
	if vec.x > MaxPos.x:
		MaxPos.x = vec.x
	if vec.x < MinPos.x:
		MinPos.x = vec.x
	if vec.y > MaxPos.y:
		MaxPos.y = vec.y
	if vec.y < MinPos.y:
		MinPos.y = vec.y
