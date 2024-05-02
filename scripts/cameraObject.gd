extends Spatial

onready var cam = $Spatial/Camera
onready var horizantalAxis = $"."
onready var verticalAxis = $Spatial
onready var lookPnt = $lookPnt

const BoardCenter = Vector3(0,0,0.216)
var InitialCamPos = Vector3(-0.16,0.2,0)

# horizantal rotation
var Spen_startAngle:float= 0.0
var Spen_EndAngle:float= 0.0
var Spen_time:float=0.0
var Spen_factor:float=0.0
var Spen_keepRotating = true
var Spen_RotateState = false
const Spen_angleSpam = PI/3


var Lerpers:Array

func _ready():
	Spen_RotateState = true
	Spen_keepRotating = true
	SpenChangeAngle()
	addLerper(self,'translation',2,InitialCamPos,Vector3())

#
#func _input(event):
#	if Input.is_action_just_pressed("ui_accept"):
#		farLook()

func farLook():
	var time = 3
	addLerper(verticalAxis,'rotation_degrees',time,verticalAxis.rotation_degrees,Vector3(0,180,130))
	addNewCenter(BoardCenter)
	

func process(delta):
	build(delta)
	if Spen_RotateState:
		buildRotation(delta)
	
	cam.look_at(lookPnt.global_translation,Vector3.UP)


###########
###########  
func SpenRestartAngle():
	Spen_startAngle = Spen_EndAngle
	Spen_EndAngle = 0
	Spen_RotateState = true
	Spen_RotateState = false
	

func SpenChangeAngle():
	Spen_startAngle = Spen_EndAngle
	Spen_EndAngle = randf() * Spen_angleSpam - Spen_angleSpam/2
	Spen_time = 14 * abs(Spen_EndAngle - Spen_startAngle)

func buildRotation(delta):
	Spen_factor += delta / Spen_time
	if Spen_factor < 1:
		horizantalAxis.rotation.y = lerp_angle(Spen_startAngle,Spen_EndAngle,Spen_factor*Spen_factor)
	else:
		Spen_factor = 0.0
		if Spen_keepRotating:
			SpenChangeAngle()


##########
########## old testement
func addNewCenter(_pnt):
	newCont(self,'translation',1,_pnt)
#	var dis = (lookPnt.translation - _pnt).length() * 20 +.1
#	addLerper(lookPnt,'translation',dis,lookPnt.translation,_pnt)

	

func addLerper(_instance,_property,_time,_initial,_final):
	var dict = {}
	dict['instance'] = _instance
	dict['property'] = _property
	dict['time'] = _time
	dict['initialCont'] = _initial
	dict['finalCont'] = _final
	dict['factor'] = 0.0
	Lerpers.append(dict)
	

func newCont(_instance,_property,_time,_final):
	var _initial = get(_property)
	addLerper(_instance,_property,_time,_initial,_final)

func build(delta:float):
	var removeList = []
	var index = -1 
	for list in Lerpers:
		index +=1
		list['factor'] = list['factor'] + delta/list['time']
		if list['factor'] < 1:
			var value = lerp(list['initialCont'],list['finalCont'],smooth(list['factor']))
			list['instance'].set(list['property'],value)
		else:
			removeList.append(index)
			var value = lerp(list['initialCont'],list['finalCont'],1)
			list['instance'].set(list['property'],value)
			
	if removeList.size():
		for i in removeList:
			Lerpers.remove(i)


func smooth(fac):
	return 3 * pow(fac,2) - 2 * pow(fac,3)





