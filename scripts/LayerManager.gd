extends Node

var ActiveLayer

var LayerNodes:Dictionary # every layer and his children
var LayerNodesBackup:Dictionary 
var LayerPanel:Control

# thie Func is get signal from drawing screen
func addChildToLayer(_childNode):
	LayerNodes[ActiveLayer.LayerId].append(_childNode)

# -f drawingScreen
func addChildToCertainLayer(_id,_child):
	LayerNodes[_id].append(_child)

# reappend obj to his layer / for do and undo
# f drawingScreen 
func addObjtoLayer(_obj):
	LayerNodes[_obj.LayerId].append(_obj)

# get signal from layer panel
func makeNewLayer(_id):
	LayerNodes[_id] = []
	WV.drawingScreen.makeNewLayer(_id)

func updateColumn(_newColumn):
	WV.drawingScreen.updateColumn(_newColumn)
	
# -f layer panel
func deleteLayer(_inst):
	var id = _inst.LayerId
	LayerNodesBackup[id] = LayerNodes[id].duplicate()
	for obj in LayerNodesBackup[id]:
		WV.drawingScreen.deleteObj(obj)
	
# warning-ignore:return_value_discarded
	LayerNodes.erase(id)
	WV.drawingScreen.deleteObjectHolder(id)

# opposite of deleteLayer
# -f layer panel
func reshowLayer(_insta):
	var id = _insta.LayerId
	LayerNodes[id] = []
	for obj in LayerNodesBackup[id]:
		WV.drawingScreen.addObj(obj)

	
# warning-ignore:return_value_discarded
	LayerNodesBackup.erase(id)
	WV.drawingScreen.reshowObjectHolder(id)


# -f drawingScreen
func removeObjFromLayerArr(_obj):
	var objId = _obj.LayerId
	if objId in LayerNodes:
		LayerNodes[objId].erase(_obj)

# -f singleLayer 
func updateVisibility(_layer,_newState):
	var id = _layer.LayerId
	var objectsOfLayer = LayerNodes[id]
	for obj in objectsOfLayer:
		obj.visible = _newState
	if !_newState:
		if CheckIntersection.selectedObjects.size():
			for obj in objectsOfLayer:
				CheckIntersection.deselectObj(obj)
	
# -f singleLayer
func changeColor(_layer , _newColor):
	_layer.LayerColor = _newColor
	var id = _layer.LayerId
	var objectsOfLayer = LayerNodes[id]
	for obj in objectsOfLayer:
		obj.objectColor = _newColor
		obj.changeColor(_newColor)





