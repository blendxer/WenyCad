extends Node

var PanelsPath:Dictionary={
	'one_circle':'res://scenes/drawing side/panels/selection panels/one circle.tscn',
	'one_line':'res://scenes/drawing side/panels/selection panels/one line panel.tscn',
	'one_labelLength':'res://scenes/drawing side/panels/selection panels/one label length.tscn',
	'two_circle':'res://scenes/drawing side/panels/selection panels/two circle panel.tscn',
	'two_line':'res://scenes/drawing side/panels/selection panels/two line panel.tscn',
	'circle_line':'res://scenes/drawing side/panels/selection panels/circle line panel.tscn'
}

var selectBox

var interPnts:Array

var hitPnt:Vector2
var touchTol=25

var selectColor = Color( 0.37, 0.61, 0.62, .7 )
var ActiveColor = Color( 0.37, 0.61, 0.62, 1 )
var active
var selectedObjects:Array=[]
var MatchObjects:Dictionary


func makeSnapPnt():
	if !LayerManager.ActiveLayer:
		WV.makeAd('20')
		return 
	var list = []
	for i in interPnts:
		i = i*WV.LastScaleBackup
		var dot = WV.drawingScreen.makeSnapPnt(i)
		list.append(dot)
		WV.allObject.append(dot)
	Undo.addNewChunk('addObj',list)
		
func checkSelect(pos,selectionState):
	var nearestObj = getNearestObj(pos)
	if nearestObj:
		# deselect obj
		if selectionState:
			deselectObj(nearestObj)
		# select obj
		else:             
			newSelect(nearestObj)
			newActive(nearestObj)
			panelUpdate()
			updateSelectBox()

func selectGroup(_arr):
	for obj in _arr:
		newSelect(obj)
	newActive(_arr[-1])
	panelUpdate()
	updateSelectBox()

func getNearestObj(pos):
	MatchObjects.clear()
	hitPnt = pos
	for layer in LayerManager.LayerPanel.AllLayer:
		if layer.VisiblityState == 0:
			for obj in LayerManager.LayerNodes[layer.LayerId]:
				if obj.realRect.has_point(hitPnt):
					if   obj.objectType == 'straight_line': checkLine(obj)
					elif obj.objectType == 'circle':        checkCircle(obj)
					elif obj.objectType == 'bezier':        checkBezier(obj)
					#elif obj.objectType == 'lengthLabel':   checkMeasurement(obj)
					
				if   obj.objectType == 'straight_line': checkLine(obj)
				elif obj.objectType == 'dot':           checkDot(obj)
				
	var dis = INF
	var nearestObj
	for obj in MatchObjects:
		if MatchObjects[obj] < dis:
			dis = MatchObjects[obj]
			nearestObj = obj
	if dis != INF:
		return nearestObj

func boxSelection(_rect,_selectionState):
	var dict = getObjInBox(_rect)
	if dict.size():
		if _selectionState:
			for obj in dict:deselectObj(obj)
		else:
			for obj in dict: 
				newSelect(obj)
			newActive(dict.keys()[-1])
			panelUpdate()
			updateSelectBox()

func newActive(_obj):
	if active:
		if active in selectedObjects:
			active.changeColor(selectColor)
		else:
			active.changeColor(active.objectColor)
			
	_obj.changeColor(ActiveColor)
	active = _obj

func getObjInBox(_rect):
	MatchObjects.clear()
	var lines = convertRect2FourLine(_rect)
	for layer in LayerManager.LayerPanel.AllLayer:
		if layer.VisiblityState == 0:
			for obj in LayerManager.LayerNodes[layer.LayerId]:
				
				if obj.objectType == 'straight_line':
					if _rect.intersects(obj.realRect):
						straightLineCheck(obj,_rect)
						
				elif obj.objectType == 'circle':
					if _rect.intersects(obj.realRect):
						if fullCircleInside(obj,_rect):
							MatchObjects[obj] = 0
						else:
							circleBoxSelection(obj,lines)
							
				elif obj.objectType == 'dot':
					if WV.rectPntInter(obj.realPosition,_rect):
						MatchObjects[obj] = 0
				
				elif obj.objectType == 'bezier':
					if _rect.intersects(obj.realRect):
						for list in obj.pointsRealPos:
							for pnt in list:
								if WV.rectPntInter(pnt,_rect):
									MatchObjects[obj]= 0
									break
									
				elif obj.objectType == 'lengthLabel':
					if _rect.intersects(obj.realRect):
						var pnts:Array
						if obj.MeasureMode == 'length':
							pnts = obj.realDashLinePosList + obj.RealLength_Points
							
						if obj.MeasureMode == 'angle':
							pnts = obj.realAnglePnts
						
						for i in pnts:
							if _rect.has_point(i):
								MatchObjects[obj] = 0
								break
						
						for i in pnts.size()-1:
							for line2 in lines:
								if lineLineIntersection(pnts[i],pnts[i+1],line2[0],line2[1]):
									MatchObjects[obj] = 0
									break
	return MatchObjects

func straightLineCheck(obj,_rect):
	# check if any pnt of line is in the box
	for lineSeg in obj.LineSeqmentVisible:
		var p1 = lineSeg[0]
		var p2 = lineSeg[1]
		for pnt in lineSeg:
			if WV.rectPntInter(pnt,_rect):
				MatchObjects[obj] = 0
				break
	
		# check if the line is outside the box but
		# it intersect with box edges
		if lineBoxIntersection(p1,p2,_rect):
			MatchObjects[obj] = 0
			break

func circleBoxSelection(obj,_lines):
# warning-ignore:unassigned_variable
	var arr:Array
	for line in _lines:
		arr.append_array(lineCircleIntersect(line[0],line[1],
		obj.realCirclePos,obj.realCircleRadius))
	# check if the intersection pnt is within visible angle
	for pnt in arr:
		var vec = pnt-obj.realCirclePos
		for segment in obj.LineSeqmentVisible:
			var segmentAngle = segment[0] + segment[1]/2
			var midVec = Vector2(cos(segmentAngle),sin(segmentAngle))
			if abs(segment[1]/2) > abs(vec.angle_to(midVec)):
				MatchObjects[obj] = 0
				break
				
func fullCircleInside(obj,_rect):
	if (_rect.position.x < obj.realRect.position.x):
		if (_rect.position.y < obj.realRect.position.y):
			if (_rect.end.x > obj.realRect.end.x):
				if (_rect.end.y > obj.realRect.end.y):
					return true

func lineBoxIntersection(p1,p2,_rect):
	var vec = p2-p1
	var p = [-vec.x,vec.x,-vec.y,vec.y]
	var q = [p1.x-_rect.position.x, _rect.end.x-p1.x,
	p1.y-_rect.position.y,_rect.end.y-p1.y]
	var u1 = -INF
	var u2 = INF
	for i in 4:
		if p[i]:
			var t = q[i]/p[i]
			if p[i] < 0 && u1 < t:
				u1 = t
			elif p[i] > 0 && u2 > t :
				u2 = t
	if u1 > u2 || u1 > 1 || u1 < 0:
		return false
	return true

func newSelect(obj):
	# check if the new selected obj already selected
	for i in selectedObjects:
		if i == obj:
			return
	
	WV.drawingScreen.LateUpdate.append(obj)
	obj.selected()
	selectedObjects.append(obj)
	obj.changeColor(selectColor)

# +f layerManager
func deselectObj(obj):
	if obj in selectedObjects:
		WV.drawingScreen.LateUpdate.erase(obj)
		var i = selectedObjects.find(obj)
		selectedObjects[i].deselected()
		selectedObjects[i].changeColor(selectedObjects[i].objectColor)
		selectedObjects.erase(obj)
		
		if selectedObjects.size():
			panelUpdate()
			updateSelectBox()
		else:
			clearSelectElement()
		
		# choose new active if there more selected obj
		if active == obj and selectedObjects.size():
			newActive(selectedObjects[-1])

func deselectAll():
	for i in len(selectedObjects):
		selectedObjects[i].deselected()
		selectedObjects[i].changeColor(selectedObjects[i].objectColor)
		WV.drawingScreen.LateUpdate.erase(selectedObjects[i])
	interPnts.clear()
	clearSelectElement()
	active = null
	backup_selectedObjCnt = 0

func clearSelectElement():
	removePanel()
	removeSelectBox()
	selectedObjects.clear()


func twoCircleIntersection():
	var circle1 = selectedObjects[0]
	var circle2 = selectedObjects[1]
	if (circle1.realCircleRadius+circle2.realCircleRadius) > (circle1.realCirclePos-circle2.realCirclePos).length():
		var r1 = circle1.realCircleRadius
		var r2 = circle2.realCircleRadius
		var d = (circle1.realCirclePos-circle2.realCirclePos).length()
		var y = .5*(d*d-r1*r1+r2*r2)/d
		var h = sqrt(r2*r2-y*y)
		var angle = (circle1.realCirclePos-circle2.realCirclePos).angle()
		var p1 = Vector2(y,h).rotated(angle) + circle2.realCirclePos
		var p2 = Vector2(y,-h).rotated(angle) + circle2.realCirclePos
		
		var dumpList:Array = []
		for pnt in [p1,p2]:
			var pntState = true
			for circle in selectedObjects:
				var angleState = false
				for segment in circle.LineSeqmentVisible:
					var segmentAngle = segment[0] + segment[1]/2
					var vec = Vector2(cos(segmentAngle),sin(segmentAngle))
					var pntVec = pnt - circle.realCirclePos
					if abs(segment[1]/2) > abs(vec.angle_to(pntVec)):
						angleState = true
						break
				pntState = pntState && angleState
			dumpList.append(pntState)
		if dumpList[0]:
			interPnts.append(p1)
		if dumpList[1]:
			interPnts.append(p2)
		makeSnapPnt()

func twoCircleOutterTangentLines():
	var c1 = selectedObjects[0]
	var c2 = selectedObjects[1]
	if c1.realCircleRadius < c2.realCircleRadius:
		c1 = selectedObjects[1]
		c2 = selectedObjects[0]
	
	var d = (c1.realCirclePos-c2.realCirclePos).length()
	var r1 = c1.realCircleRadius
	var r2 = c2.realCircleRadius
	var r3 = r1 - r2
	var h = sqrt(d*d-r3*r3)
	var y = sqrt(h*h+r2*r2)
	var theta = acos((r1*r1+d*d-y*y)/(2*r1*d))
	var p1 = polar2cartesian(r1,theta)
	var v1 =  -p1.normalized() * r3 + p1 
	var vec = (c2.realCirclePos-c1.realCirclePos).normalized()
	var p2 = p1.reflect(vec) 
	var v2 = v1.reflect(vec)
	interPnts.append(p1+c1.realCirclePos)
	interPnts.append(p2+c1.realCirclePos)
	interPnts.append(v1+c2.realCirclePos)
	interPnts.append(v2+c2.realCirclePos)
	makeSnapPnt()


func twoLineIntersection():
	for i in selectedObjects[0].LineSeqmentVisible:
		for j in selectedObjects[1].LineSeqmentVisible:
			var t = lineLineIntersection(i[0],i[1],j[0],j[1])
			if t:
				interPnts.append(t)
				makeSnapPnt()
				return 

func lineLineIntersection(p1,p2,p3,p4):
	var den = ((p4.y-p3.y)*(p2.x-p1.x) - (p4.x-p3.x)*(p2.y-p1.y))
	if den:
		var uA = ((p4.x-p3.x)*(p1.y-p3.y) - (p4.y-p3.y)*(p1.x-p3.x))/den
		var uB = ((p2.x-p1.x)*(p1.y-p3.y) - (p2.y-p1.y)*(p1.x-p3.x))/den
		if uA >= 0 && uA <= 1 && uB >= 0 && uB <= 1:
			return Vector2(p1.x + (uA * (p2.x-p1.x))
			,p1.y + (uA * (p2.y-p1.y)))

func lineCircleIntersect_door():
	var circle
	var line
	# find the circle and line in the 'selectedObjects' list
	if selectedObjects[0].objectType == 'straight_line':
		line = selectedObjects[0]
		circle = selectedObjects[1]
	else:
		circle = selectedObjects[0]
		line = selectedObjects[1]
		
	var list = lineCircleIntersect(line.RealBoardLine[0],line.RealBoardLine[1],
	circle.realCirclePos,circle.realCircleRadius)
	if list.size():
		for pnt in list:
			var vec = pnt-circle.realCirclePos
			for segment in circle.LineSeqmentVisible:
				var segmentAngle = segment[0] + segment[1]/2
				var midVec = Vector2(cos(segmentAngle),sin(segmentAngle))
				if abs(segment[1]/2) > abs(vec.angle_to(midVec)):
					interPnts.append(pnt)
					break
			
		makeSnapPnt()
	
func lineCircleIntersect(_lineStart,_lineEnd,_circlePos,_circleRad):
	var d = _lineEnd - _lineStart
	var f = _lineStart - _circlePos
	var a = d.dot(d)
	var c = f.dot(f) - _circleRad * _circleRad
	var b = 2 * f.dot(d)
	var discriminant = b * b - 4 * a * c
	if discriminant < 0:
		return []
	else:
		var dumpList = []
		discriminant = sqrt(discriminant)
		var den = 2*a
		if den:
			var t1 = (-b - discriminant) / den
			var t2 = (-b + discriminant) / den
			if (t1 >= 0 && t1 <= 1):
				dumpList.append(_lineStart + t1 * d)
			if (t2 >= 0 && t2 <= 1):
				dumpList.append(_lineStart + t2 * d)
#		else:
#			print('error in check intersection line circle')
		return dumpList


func checkLine(obj):
	var line = (obj.RealBoardLine[1] - obj.RealBoardLine[0]).normalized()
	var hyp = hitPnt - obj.RealBoardLine[0]
	var dot = line.dot(hyp)
	
	if dot > 0 and dot < (obj.RealBoardLine[1] - obj.RealBoardLine[0]).length():
		var verticalDis = (dot*line - hyp).length() * WV.LastScaleBackup
		if verticalDis  < touchTol:
			MatchObjects[obj] = verticalDis
	
func checkLineSegment(p1,p2):
	var line = (p2 - p1).normalized()
	var hyp = hitPnt - p1
	var distance = (line.dot(hyp)*line - hyp).length() * WV.LastScaleBackup
	return distance


func checkCircle(obj):
	var vect = obj.realCirclePos - hitPnt
	var radius = obj.realCircleRadius
	var distance = abs(vect.length()-radius) * WV.LastScaleBackup
	if distance<touchTol:
		if circlePorject(obj,-vect.normalized()):
			MatchObjects[obj] = distance

func circlePorject(_obj,_pnt):
	for i in _obj.LineSeqmentVisible:
		var angle = i[0] + i[1]/2
		var vec = Vector2(cos(angle),sin(angle))
		angle = abs(vec.angle_to(_pnt))
		if angle < abs(i[1]/2):
			return true

func checkDot(obj):
	var l = (obj.realPosition-hitPnt).length() * WV.LastScaleBackup
	if l < touchTol:
		MatchObjects[obj] = l
		

func checkBezier(obj):
	var newRect = obj.realRect
	var shift = hitPnt - newRect.position
	
	if shift.x >= 0 and shift.x < newRect.size.x:
		if shift.y >= 0 and shift.y < newRect.size.y:
			var minDis = INF
			var dis
			for list in obj.pointsRealPos:
				for pnt in list:
					dis = (pnt-hitPnt).length()
					if dis < minDis:
						minDis = dis
			
			if touchTol > minDis*WV.LastScaleBackup:
				MatchObjects[obj] = minDis*WV.LastScaleBackup
				
func checkMeasurement(obj):
	var shift = hitPnt - obj.realRect.position
	if shift.x >= 0 and shift.x < obj.realRect.size.x:
		if shift.y >= 0 and shift.y < obj.realRect.size.y:
			
			var pnts:Array
			if obj.MeasureMode == 'length':
				pnts = obj.realDashLinePosList
			if obj.MeasureMode == 'angle':
				pnts = obj.realAnglePnts
				
			var minDis= INF
			for i in pnts.size()-1:
				var l = checkLineSegment(pnts[i],pnts[i+1])
				if l < minDis:
					minDis = l
			if touchTol > minDis:
				MatchObjects[obj] = minDis
					

# utils functions
func convertRect2FourLine(_rect):
# warning-ignore:unassigned_variable
	var arr:Array
	arr.append(_rect.position)
	arr.append(Vector2(_rect.end.x,_rect.position.y))
	arr.append(_rect.end)
	arr.append(Vector2(_rect.position.x,_rect.end.y))
	arr.append(_rect.position)
# warning-ignore:unassigned_variable
	var arr2:Array
	for i in arr.size()-1:
		arr2.append([arr[i],arr[i+1]])
	return arr2


func rectRectInter(_rect1,_rect2):
# warning-ignore:unassigned_variable
	var arr:Array
	arr.append(_rect1.position)
	arr.append(Vector2(_rect1.end.x,_rect1.position.y))
	arr.append(_rect1.end)
	arr.append(Vector2(_rect1.position.x,_rect1.end.y))
	
	for p in arr:
		if WV.rectPntInter(p,_rect2):
			return true
	
# find the type of the panel and then pass it to 'addPanel' func
func panelUpdate():
	# remove last panel if it exist
	removePanel()
	
	match selectedObjects.size():
		1:
			var type = selectedObjects[0].objectType 
			
			if type =='circle':
				addPanel('one_circle', selectedObjects[0])
				
			elif type == 'straight_line':
				addPanel('one_line', selectedObjects[0])
			
			elif type == 'lengthLabel':
				addPanel('one_labelLength', selectedObjects[0])
				
		2:
			# make list contain all selected objects types
			var typeList: = []
			for i in selectedObjects:
				typeList.append(i.objectType)
			
			# two circle selected
			if 'circle' in typeList && typeList[0] == typeList[1]:
				addPanel('two_circle', selectedObjects[0])
			
			# two lines selected
			if 'straight_line' in typeList && typeList[0] == typeList[1]:
				addPanel('two_line', selectedObjects[0])
			
			# line and circle selected
			if 'straight_line' in typeList && 'circle' in typeList:
				addPanel('circle_line', selectedObjects[0])
			
# add panel 
func addPanel(_panelName:String, _obj):
	var panelsHolder = WV.drawingScreen.panelHolder
	var panel = load(PanelsPath[_panelName]).instance()
	panelsHolder.add_child(panel)
	panel.object = _obj


func removePanel():
	var panelsHolder = WV.drawingScreen.panelHolder
	if panelsHolder.get_child_count():
		panelsHolder.get_child(0).queue_free()

######## select box 
###################

func removeSelectBox():
	selectBox.removeBox()

var backup_selectedObjCnt: = 0
func updateSelectBox():
	selectBox.reset()
	for obj in selectedObjects:
		if obj.objectType == 'straight_line':
			selectBox.selectedObj([obj.realRect.position,obj.realRect.end])
		
		elif obj.objectType == 'circle':
			selectBox.selectedObj([obj.realRect.position,obj.realRect.end])
		
		elif obj.objectType == 'dot':
			selectBox.selectedObj([obj.realPosition])
		
		elif obj.objectType == 'bezier':
			selectBox.selectedObj([obj.realRect.position,obj.realRect.end])
			
		elif obj.objectType == 'lengthLabel':
			selectBox.selectedObj([obj.realRect.position,obj.realRect.end])
	
	if backup_selectedObjCnt != selectedObjects.size():
		selectBox.updateSelectedOrignPnt()
	backup_selectedObjCnt = selectedObjects.size()


