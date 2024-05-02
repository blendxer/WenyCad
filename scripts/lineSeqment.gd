extends Spatial

onready var completeLine = $complete
onready var mainLine = $main

var mesh_arr = []
var allPoints:Array
var OrignalPoints
var PathLength:float=0
var PathLengthList:Array=[]
var LastPathIndex:int=0
var LineMode=false

var lineWidth = .0005
var time:=0.0

func _ready():
	mesh_arr.resize(Mesh.ARRAY_MAX)
	
func build(fac):
	var distance:float= fac * PathLength
	if not LineMode:
		for i in len(PathLengthList):
			if distance <= PathLengthList[i]:
				if not LastPathIndex == i:
					LastPathIndex = i
					mainLine.mesh.clear_surfaces()
					var arr = []
					for j in i*6:
						arr.append(allPoints[j])
					mesh_arr[Mesh.ARRAY_VERTEX] = arr
					mainLine.mesh.add_surface_from_arrays(Mesh.PRIMITIVE_TRIANGLES,mesh_arr)
				break
		
		if completeLine:
			completeLine.mesh.clear_surfaces()
			if LastPathIndex != len(OrignalPoints)-1 and fac:
				var lerpFac:float = (distance-PathLengthList[LastPathIndex-1])/(PathLengthList[LastPathIndex]-PathLengthList[LastPathIndex-1])
				var arr = [OrignalPoints[LastPathIndex],lerp(OrignalPoints[LastPathIndex],OrignalPoints[LastPathIndex+1],lerpFac)]
				arr = fixAxis(makeTriangleList(makeThickness(arr)))
				mesh_arr[Mesh.ARRAY_VERTEX] = arr
				completeLine.mesh.add_surface_from_arrays(Mesh.PRIMITIVE_TRIANGLES,mesh_arr)
		
	else:
		completeLine.mesh.clear_surfaces()
		var arr = [OrignalPoints[0],lerp(OrignalPoints[0],OrignalPoints[1],fac)]
		arr = fixAxis(makeTriangleList(makeThickness(arr)))
		mesh_arr[Mesh.ARRAY_VERTEX] = arr
		completeLine.mesh.add_surface_from_arrays(Mesh.PRIMITIVE_TRIANGLES,mesh_arr)

func add_list(list):
	OrignalPoints = list
	if len(list)>2:
		completeLine.mesh = ArrayMesh.new()
		mainLine.mesh = ArrayMesh.new()
		for i in len(list)-1:
			PathLength += (list[i+1]-list[i]).length()
			PathLengthList.append(PathLength)
		allPoints = fixAxis(makeTriangleList(makeThickness(list)))
	
	# this seqment is a line 
	if len(list) == 2: 
		completeLine.mesh = ArrayMesh.new()
		LineMode = true
		
	# this for dot only 
	if len(list) == 1:
		var cylinder = CylinderMesh.new()
		var radius = .001
		mainLine.mesh = cylinder
		cylinder.top_radius = radius
		cylinder.bottom_radius = radius
		cylinder.height = radius
		translation = fixAxis(list)[0]
		
func addDashLine(_list):
	completeLine.mesh = ArrayMesh.new()
	mainLine.mesh = ArrayMesh.new()
	var bigList = []
	for list in _list:
		for i in len(list)-1:
			PathLength += (list[i+1]-list[i]).length()
		var subList = fixAxis(makeTriangleList(makeThickness(list)))
		bigList.append(subList)
		
func makeThickness(_list):
	var arr = []
	var vec:Vector2 = (_list[1] - _list[0]).normalized()
	vec = vec.rotated(PI/2)
	arr.append(_list[0]+vec*lineWidth)
	arr.append(_list[0]-vec*lineWidth)
	for i in len(_list)-2:
		var vec1 = _list[i+1]-_list[i]
		var vec2 = _list[i+2]-_list[i+1]
		var shift = (vec2-vec1).normalized()*lineWidth
		arr.append(_list[i+1]+shift)
		arr.append(_list[i+1]-shift)
	vec = (_list[-1] - _list[-2]).normalized()
	vec = vec.rotated(PI/2)
	arr.append(_list[-1]+vec*lineWidth)
	arr.append(_list[-1]-vec*lineWidth)
	return arr

func makeTriangleList(list):
	var arr = []
# warning-ignore:integer_division
	var length = len(list)/2 -1
	for i in length:
		var index = 2*i
		arr.append(list[index])
		arr.append(list[index+2])
		arr.append(list[index+3])
		arr.append(list[index])
		arr.append(list[index+1])
		arr.append(list[index+3])
	return arr
	
func fixAxis(_list):
	var arr = []
	for i in _list:
		arr.append(Vector3(i.x,0,i.y))
	return arr
