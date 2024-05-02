extends MeshInstance

onready var minLine = $MeshInstance

var mesh_arr = []
var allPoints:Array
var OrignalPoints
var PathLength:float=0
var PathLengthList:Array=[0]
var LastPathIndex:int=0
var LineMode=false

var lineWidth = .01
var time:=0.0

func _ready():
	mesh_arr.resize(Mesh.ARRAY_MAX)
	
	# test
#	var list:Array=[]
#	var radius =1
#	var res = 30
#	for i in res:
#		var fac = float(i)/(res-1)
#		var x = radius*cos(2*PI*fac)
#		var y = radius*sin(2*PI*fac)
#		list.append(Vector2(x,y))
#	#add_list(list)
#	add_list([Vector2(-1,-1),Vector2(1,1)])
#
#	set_process(0)
#
#func _input(event):
#	if Input.is_action_just_pressed("ui_accept"):
#		set_process(1)
#
#func _process(delta):
#	time+=delta
#	var fac = time/5
#	if fac<1:
#		build(fac)
#	else:
#		build(1)
#		set_process(0)

func build(fac):
#	fac = 1-fac
	var distance:float= fac * PathLength
	if not LineMode:
		for i in len(PathLengthList):
			if distance <= PathLengthList[i]:
				if not LastPathIndex == i:
					LastPathIndex = i
					mesh.clear_surfaces()
					var arr:Array
					for j in i*6:
						arr.append(allPoints[j])
					mesh_arr[Mesh.ARRAY_VERTEX] = arr
					mesh.add_surface_from_arrays(Mesh.PRIMITIVE_TRIANGLES,mesh_arr)
				break
		
		minLine.mesh.clear_surfaces()
		if LastPathIndex != len(OrignalPoints)-1 and fac:
			var lerpFac:float = (distance-PathLengthList[LastPathIndex-1])/(PathLengthList[LastPathIndex]-PathLengthList[LastPathIndex-1])
			var arr = [OrignalPoints[LastPathIndex],lerp(OrignalPoints[LastPathIndex],OrignalPoints[LastPathIndex+1],lerpFac)]
			arr = fixAxis(makeTriangleList(makeThickness(arr)))
			mesh_arr[Mesh.ARRAY_VERTEX] = arr
			minLine.mesh.add_surface_from_arrays(Mesh.PRIMITIVE_TRIANGLES,mesh_arr)
		
	else:
		minLine.mesh.clear_surfaces()
		var arr = [OrignalPoints[0],lerp(OrignalPoints[0],OrignalPoints[1],fac)]
		arr = fixAxis(makeTriangleList(makeThickness(arr)))
		mesh_arr[Mesh.ARRAY_VERTEX] = arr
		minLine.mesh.add_surface_from_arrays(Mesh.PRIMITIVE_TRIANGLES,mesh_arr)

func add_list(list):
	print(list)
	OrignalPoints = list
	if len(list)>2:
		for i in len(list)-1:
			PathLength += (list[i+1]-list[i]).length()
			PathLengthList.append(PathLength)
		allPoints = fixAxis(makeTriangleList(makeThickness(list)))
	
	# this seqment is a line 
	if len(list) == 2: 
		LineMode = true
		
	
func makeThickness(_list):
	var arr:Array
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
	var arr:Array
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
	var arr:Array
	for i in _list:
		arr.append(Vector3(i.x,0,i.y))
	return arr
