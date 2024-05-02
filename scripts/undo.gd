extends Node

var UndoPipe:Array
var RedoPipe:Array

const LogSize = 10

var Verses:={
	'move':'move',
	'scale':'scale',
	'rotate':'rotate',
	
	'addObj':'removeObj',
	'removeObj':'addObj',
	'editObj':'editObj',
	
	'addLayer':'removeLayer',
	'removeLayer':'addLayer',
	'changeLayerColor':'changeLayerColor',
	'moveLayer':'moveLayer',
	'changeLayerName':'changeLayerName',
	'changeObjLayer':'changeObjLayer'
}

func undo():
	if !UndoPipe.size():
		WV.makeAd('2')
		return 
	var verse = Verses[UndoPipe[-1][0]]
	RedoPipe.append([verse,callv(verse,[UndoPipe[-1][1]])])
	UndoPipe.pop_back()
	if UndoPipe.size() > LogSize:
		actionsTerminator(UndoPipe.pop_front())
	updateCounters()

func redo():
	if !RedoPipe.size():
		WV.makeAd('1')
		return 
	var verse = Verses[RedoPipe[-1][0]]
	UndoPipe.append([verse,callv(verse,[RedoPipe[-1][1]])])
	RedoPipe.pop_back()
	if RedoPipe.size() > LogSize:
		actionsTerminator(UndoPipe.pop_front())
	updateCounters()
		

func addNewChunk(_type,_chunk):
	UndoPipe.append([_type,_chunk])
	if UndoPipe.size() > LogSize:
		actionsTerminator(UndoPipe.pop_front())
	
	if RedoPipe.size():
		for action in RedoPipe:
			actionsTerminator(action)
		RedoPipe.clear()
	
	updateCounters()

func updateCounters():
	WV.drawingScreen.undoCounter.changeNumber(UndoPipe.size())
	WV.drawingScreen.redoCounter.changeNumber(RedoPipe.size())
	
func removeObj(_list):
	for obj in _list:
		WV.drawingScreen.deleteObj(obj)
	return _list

func addObj(_list):
	for obj in _list:
		WV.drawingScreen.addObj(obj)
	return _list

func editObj(_list):
	var backup = [_list[0],_list[0].LineSeqmentVisible.duplicate(true),-_list[2]]
	_list[0].undoUpdate(_list)
	return backup

func move(_list):
	for i in _list.size():
		WV.drawingScreen.selectBox.moveObjList(_list[i][0],-_list[i][1])
		_list[i][1]*=-1
	return _list

func scale(_list):
	WV.drawingScreen.selectBox.scaleObjList(_list[0],_list[1],Vector2.ONE/_list[2])
	return [_list[0],_list[1],Vector2.ONE/_list[2]]

func rotate(_list):
	WV.drawingScreen.selectBox.rotateObjList(_list[0],_list[1],-_list[2])
	return [_list[0],_list[1],-_list[2]]
	
func addLayer(insta):
	LayerManager.LayerPanel.addLayerForUndo(insta)
	return insta

func removeLayer(insta):
	LayerManager.LayerPanel.removeLayerForUndo(insta)
	return insta

func changeLayerColor(_list):
	var oldColor = _list[0].LayerColor
	_list[0].changeColor(_list[1])
	return [_list[0],oldColor]

func moveLayer(_list):
	var backup = [_list[0],_list[0].Father,_list[0].Index]
	LayerManager.LayerPanel.moveChildForUndo(_list)
	return backup

func changeLayerName(_list):
	var oldName = _list[0].Title
	_list[0].changeTitle(_list[1])
	return [_list[0],oldName]

func changeObjLayer(_list):
	var oldIds = []
	for i in _list[0].size():
		var obj = _list[0][i]
		oldIds.append(obj.LayerId)
		LayerManager.LayerPanel.moveObjToLayer(obj,_list[1][i])
	return [_list[0],oldIds]
		

# terminate actions
func actionsTerminator(_action):
	var type = _action[0]
	match type:
		'removeObj':
			_action[1][0].queue_free()
		'removeLayer':
			for obj in LayerManager.LayerNodesBackup[_action[1].LayerId]:
				obj.queue_free()
# warning-ignore:return_value_discarded
			LayerManager.LayerNodesBackup.erase(_action[1].LayerId)
			_action[1].queue_free()
