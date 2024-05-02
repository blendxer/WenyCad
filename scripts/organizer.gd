extends Node

func snap(_activeVec,_otherVec):
	var active = CheckIntersection.active
	var activePnt = getCenter(active) + active.realRect.size/2 * getVec(_activeVec)
	
	if CheckIntersection.selectedObjects.size() == 1:
		WV.drawingScreen.changeCursorPos(activePnt)
		return 
		
	var AxisLock = Vector2(int(int(_otherVec.x) % 2 == 0 ),
						   int(int(_otherVec.y) % 2 == 0 ))
	
	var vecList = []
	for obj in CheckIntersection.selectedObjects:
		if obj != active: 
			var objPnt = getCenter(obj) + obj.realRect.size/2 * getVec(_otherVec)
			var vec = (activePnt - objPnt) * AxisLock
			obj.finshMove(vec)
			vecList.append([[obj],vec])
			
	Undo.addNewChunk('move',vecList)
	CheckIntersection.updateSelectBox()
	
func getVec(_vec):
	_vec -= Vector2(2,2)
	_vec.x += -sign(_vec.x) * int(bool(_vec.x))
	_vec.y += -sign(_vec.y) * int(bool(_vec.y))
	return _vec

func getCenter(obj):
	return (obj.realRect.position + obj.realRect.end)/2


############### cursor event
###############

func cursor(_option):
	match _option:
		'cursor to selection center': cursor_toSelectionCenter()
		'cursor to active center': cursor_toActiveCenter()
		'cursor to selection origin': cursor_toPivot()
		'selection to cursor':cursor_selectoToCursor()

func cursor_selectoToCursor():
	var vec = WV.cursor - WV.drawingScreen.selectBox.pos2d.position
	var vecList = []
	for obj in CheckIntersection.selectedObjects:
		obj.finshMove(vec)
		vecList.append([[obj],vec])
		
	Undo.addNewChunk('move',vecList)
	CheckIntersection.updateSelectBox()
	WV.drawingScreen.selectBox.updateSelectedOrignPnt()
	

func cursor_toPivot():
	var pos = WV.drawingScreen.selectBox.pos2d.position
	WV.drawingScreen.changeCursorPos(pos)
	

func cursor_toActiveCenter():
	var active = CheckIntersection.active
	var pos = active.realRect.position + active.realRect.size/2
	WV.drawingScreen.changeCursorPos(pos)

func cursor_toSelectionCenter():
	var arr = []
	for obj in CheckIntersection.selectedObjects:
		arr.append(obj.realRect.position)
		arr.append(obj.realRect.end)
	var boundary = WV.getBoundary(arr)
	var pos = boundary.position + boundary.size/2
	WV.drawingScreen.changeCursorPos(pos)

################## object distribution
##################
func distribution_circular(_pos,_rad,_start,_end):
	_start = -deg2rad(_start);_end = -deg2rad(_end)
	var angleDiff = _end - _start
	var count = CheckIntersection.selectedObjects.size()
	var vecList = []
	for i in count:
		var obj = CheckIntersection.selectedObjects[i]
		var fac = float(i)/(count-1)
		var angle = fac * angleDiff + _start
		var finalPos = _pos + polar2cartesian(_rad,angle)
		var vec = finalPos - getCenter(obj)
		obj.finshMove(vec)
		vecList.append([[obj],vec])
	
	Undo.addNewChunk('move',vecList)
	CheckIntersection.updateSelectBox()
	

func distribution_grid(_cnt , _shift,_directionVec):
	var AdirectionVec = Vector2(_directionVec.y,_directionVec.x)
	var count = CheckIntersection.selectedObjects.size()
	var otherCnt = int(count/_cnt) + 1
	var activePos = getCenter(CheckIntersection.active)
	var vecList = []
	for i in otherCnt:
		var basePos = activePos + i * _shift * AdirectionVec 
		for j in _cnt:
			var index = i*_cnt+j
			if index < count:
				var obj = CheckIntersection.selectedObjects[index]
				var vec = basePos + j * _shift * _directionVec
				vec -= getCenter(obj)
				obj.finshMove(vec)
				vecList.append([[obj],vec])
		
	Undo.addNewChunk('move',vecList)
	CheckIntersection.updateSelectBox()


func distribution_betweenTwoPnts(_p1,_p2):
	var count = CheckIntersection.selectedObjects.size()
	var vecList = []
	for i in count:
		var obj = CheckIntersection.selectedObjects[i]
		var fac = float(i)/(count-1)
		var finalPos = lerp(_p1,_p2,fac)
		var vec = finalPos - getCenter(obj)
		obj.finshMove(vec)
		vecList.append([[obj],vec])
		
	Undo.addNewChunk('move',vecList)
	CheckIntersection.updateSelectBox()


func distribution_constantShift(_lockVec,_shift):
	_lockVec *= _shift * Vector2(1,-1)
	var active = CheckIntersection.active
	var activeCenter = getCenter(active)
	var i = 1
	var vecList = []
	for obj in CheckIntersection.selectedObjects:
		if obj != active:
			var vec = activeCenter + i * _lockVec - getCenter(obj)
			obj.finshMove(vec)
			vecList.append([[obj],vec])
			i+=1
			
	Undo.addNewChunk('move',vecList)
	CheckIntersection.updateSelectBox()


func distribution_sideToSide(_lockVec):
	_lockVec *= Vector2(1,-1)
	var active = CheckIntersection.active
	var lastPnt = getCenter(active) + active.realRect.size/2 * _lockVec
	var vecList = []
	for obj in CheckIntersection.selectedObjects:
		if obj != active:
			lastPnt += obj.realRect.size/2 * _lockVec
			var vec = lastPnt - getCenter(obj)
			obj.finshMove(vec)
			vecList.append([[obj],vec])
			lastPnt += obj.realRect.size/2 * _lockVec
	Undo.addNewChunk('move',vecList)
	CheckIntersection.updateSelectBox()
	

func distribution_evenSpace(_lockVec):
	var arr = []
	for obj in CheckIntersection.selectedObjects:
		arr.append(getCenter(obj))
	
	var boundary = WV.getBoundary(arr)
	var step = boundary.size/(arr.size()-1)
	
	var i = 0
	var vecList = []
	for obj in CheckIntersection.selectedObjects:
		var vec = boundary.position + i * step * _lockVec - getCenter(obj)
		obj.finshMove(vec)
		vecList.append([[obj],vec])
		i+=1
	
	Undo.addNewChunk('move',vecList)
	CheckIntersection.updateSelectBox()













