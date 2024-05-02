extends Node

var  DataFilePath = ""

func saveAction():
	if DataFilePath == '':
		WV.main.openFileDialog('save/file',self,'updateSavePath')
		return
	
	var save_game = File.new()
	save_game.open(DataFilePath, File.WRITE)
	var data = {}
	
	
	############ save layers
	############
	var layerDict = {}
	for layer in LayerManager.LayerPanel.AllLayer:
		var dict = {}
		dict['id'] = layer.LayerId
		dict['name'] = layer.Title
		dict['level'] = layer.Level
		dict['index'] = layer.Index
		dict['visiblity'] = layer.VisiblityState
		dict['color'] = layer.LayerColor
		dict['openState'] = layer.OpenState
		dict['children'] = []
		for child in layer.Children:
			dict['children'].append(child.LayerId)
		
		if layer.Father != LayerManager.LayerPanel:
			dict['fatherId'] = layer.Father.LayerId
		
		layerDict[layer.LayerId] = dict
	
	var maxLevel = -INF
	var indexes = [] 
	for obj in LayerManager.LayerPanel.AllLayer:
		if obj.Level > maxLevel:
			maxLevel = obj.Level
	for i in maxLevel:
		indexes.append([])
	for obj in LayerManager.LayerPanel.AllLayer:
		indexes[obj.Level-1].append(obj.LayerId)
	
	data['layers'] = layerDict
	data['layersIdLevel'] = indexes
	
	############# save objects
	#############
	var objectDict = {}
	for layer in LayerManager.LayerPanel.AllLayer:
		objectDict[layer.LayerId] = []
	
	for layer in LayerManager.LayerPanel.AllLayer:
		for obj in LayerManager.LayerNodes[layer.LayerId]:
			objectDict[obj.LayerId].append(obj.copy())
	data['objects'] = objectDict
	
	#save variable
	var variableDict={}
	variableDict['ActionIndex'] = ActionManager.ActionIndex
	variableDict['version'] = -1.0
	data['variable'] = variableDict
	
	save_game.store_var(data)
	save_game.close()
	WV.makeAd('21')

func loadAction(_path):
	DataFilePath = _path
	LayerManager.LayerPanel.deleteAllLayers()
	Undo.UndoPipe.clear()
	Undo.RedoPipe.clear()
	for obj in WV.allObject:      obj.queue_free()
	for obj in WV.allObjectBackup:obj.queue_free()
	WV.allObject.clear()
	WV.allObjectBackup.clear()
	ActionManager.ActionIndex = 0
	
	var save_game = File.new()
	save_game.open(DataFilePath, File.READ)
	var data = save_game.get_var()
	
	if 'variable' in data:
		if 'ActionIndex' in data['variable']:
			ActionManager.ActionIndex = data['variable']['ActionIndex']
	
	
	############# load layer 
	#############
	var instaId = {}
	# first load top layers only
	for id in data['layersIdLevel'][0]:
		var layer = data['layers'][id]
		layer['father'] = LayerManager.LayerPanel
		var insta = LayerManager.LayerPanel.dataToLayer(layer)
		instaId[id] = insta
		LayerManager.LayerPanel.Children.append(insta)
	data['layersIdLevel'].pop_front()
	# now load the rest of layers 
	for list in data['layersIdLevel']:
		for id in list:
			var layer = data['layers'][id]
			layer['father'] = instaId[layer['fatherId']]
			var insta = LayerManager.LayerPanel.dataToLayer(layer)
			instaId[id] = insta
			instaId[layer['fatherId']].Children.append(insta)
			instaId[layer['fatherId']].sortChildren()
	
	LayerManager.LayerPanel.sortChildren()
	for obj in instaId.values():
		obj.sortChildren()
		obj.updateTapIcon()
		obj.updateVisiblityIcons()
	
	LayerManager.LayerPanel.rearrangeLayers()
	LayerManager.LayerPanel.updateLayerColumn()
	
	############### load objects
	###############
	for i in 1000:
		WV.drawingScreen.IndexSequenceDict[i] =i
	
	for layerId in data['objects']:
		var objects = data['objects'][layerId]
		LayerManager.LayerNodes[layerId] = []
		for objDict in objects:
			var insta = WV.drawingScreen.loadObj(objDict)
			LayerManager.LayerNodes[layerId].append(insta)
			insta.visible = instaId[layerId].VisiblityState == 0
	WV.drawingScreen.CopyData.clear()
	save_game.close()
	WV.drawingScreen.grid.alignScreen()
	

func updateSavePath(_path):
	if !'.' in _path:
		_path += '.'
	if _path.split('.')[-1] != 'gd':
		_path += 'gd'
	DataFilePath = _path
	saveAction()

func getLoadPath():
	WV.main.openFileDialog('load/file',self,'loadAction')
	




