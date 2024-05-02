extends Resource
class_name Motion

# constance
const curve = preload('res://smothCurve.tres')

# variable
var Instance
var LineInstance=null
var MotionType:String
var FinalCondition
var ActionTime:float
var FinshSettingState:bool = true
var moveFactor:float
var function = 'buildFrame'

# motion parameter
var InitialCondition
var VerticalMove:float=0
var Delay:float=0
var MotionState:bool = true

# caliper
var Caliper
var CaliperWidth:float
var CaliperDiffAngle
var CaliperStartAngle

# follow curve
var followCur_PathLength=0
var followCur_DistanceStep:Array=[0]
var followCur_PathList:Array
var followCur_reverseDrawing:=false

# ruler 60 30 
var Position3dInst
var FinalAngle
var OrignalAngle
var OrignalPos
var HeadPos
var OrignalDiffVec
var DiffAngle


var ChildList:Array # synchonurs
var tailers:Array # start after finsh of this animation

func childBuild(fac):
	for i in ChildList:
		i.buildFrame(fac)


func rotClosetAngle(_instance,_angle,_time):
	Instance = _instance
	ActionTime = _time
	FinalCondition = _angle
	InitialCondition = _instance.rotation.y
	function = 'lerpClosetAngle'
	
func lerpClosetAngle(fac):
	var angle = lerp_angle(InitialCondition,FinalCondition,fac)
	Instance.rotation.y = angle


func ruler6030Motion(_ruler , _pos3d,_diffAngle,_headPos,_time):
	ActionTime = _time
	Instance = _ruler
	Position3dInst = _pos3d
	HeadPos = _headPos
	DiffAngle = _diffAngle
	function = 'ruler6030Move'

func ruler6030Move(fac):
	if FinshSettingState:
		FinshSettingState = false
		OrignalAngle = Instance.rotation.y
		OrignalPos = Instance.translation
		
	var angle = lerp_angle(OrignalAngle,OrignalAngle+DiffAngle,fac)
	Instance.rotation.y = angle
	var vec = -Position3dInst.global_translation + Instance.translation
	Instance.translation = lerp(OrignalPos,vec+HeadPos,fac)


func makeMotion(_instance ,_motionType,_finalCondition,_actionTime):
	Instance = _instance
	FinalCondition = _finalCondition
	ActionTime = _actionTime
	MotionType = _motionType

func caliperWidth(_caliper,_width ,_time):
	Caliper = _caliper
	CaliperWidth = _width
	ActionTime = _time
	function = 'setCaliperWidth'
	
func caliperAction(_caliper , _diffAngle ,_time):
	Caliper = _caliper
	CaliperDiffAngle = _diffAngle
	ActionTime = _time
	function = 'setCaliperAction'
	
func caliperRotation(_caliper ,_angle ,_time):
	Caliper = _caliper
	ActionTime = _time
	function = 'SetCaliperRot'
	FinalCondition = _angle 

func followCurve(_instance ,_path , _time, _reverse=false):
	Instance = _instance
	ActionTime = _time
	followCur_PathList = _path
	function = 'followCurFunc'
	followCur_reverseDrawing = _reverse
	for i in _path.size()-1:
		var dis = (_path[i]-_path[i+1]).length()
		followCur_PathLength+=dis
		followCur_DistanceStep.append(followCur_PathLength)
	if _reverse:
		EraserNoise.startNewNoise()

func callFunc(_instance,_func,_time):
	Instance = _instance
	ActionTime = _time
	FinalCondition = _func
	function='callWiater'

func callWiater(fac):
	if fac==1:
		Instance.call(FinalCondition)

func fakeAction(_time):
	ActionTime = _time
	function = 'fakeActionFunc'

func move(delta):
	if not MotionState:
		return 0
		
	moveFactor += delta/ActionTime
	if moveFactor < 0:
		return 0
	
	if moveFactor >=1:
		callv(function,[1])
		childBuild(1)
		checkTailers()
		return 1
		
	elif moveFactor > 0:
		callv(function,[moveFactor])
		childBuild(moveFactor)

func buildFrame(fac):
	if FinshSettingState:
		FinshSettingState = false
		InitialCondition = Instance.get(MotionType)
		moveFactor = -Delay
	
	Instance.call('set',MotionType ,lerp(InitialCondition , FinalCondition , fac))
	
	if VerticalMove:
		Instance.translation.y += (1-(abs(fac-.5)*2)) * VerticalMove
		
	if LineInstance:
		LineInstance.build(fac)

func setCaliperWidth(fac):
	if FinshSettingState:
		FinshSettingState = false
		Caliper.newWidth(CaliperWidth)
	Caliper.build(fac)
	
func setCaliperAction(fac):
	if FinshSettingState:
		FinshSettingState = false
		CaliperStartAngle = Caliper.rotation
		
	Caliper.rotation = CaliperStartAngle + fac * CaliperDiffAngle
	LineInstance.build(fac)

func SetCaliperRot(fac):
	if FinshSettingState:
		FinshSettingState = false
		InitialCondition = Caliper.rotation.y 
	
#	fac = curve.interpolate(fac)
	Caliper.rotation.y = lerp_angle(InitialCondition, FinalCondition , fac) 

func followCurFunc(fac):
	if LineInstance:
		if followCur_reverseDrawing:
			LineInstance.build(1-fac)
		else:
			LineInstance.build(fac)
	
	if fac !=1:
		var length = fac * followCur_PathLength
		
		var index:int=0
		for i in followCur_DistanceStep.size():
			if followCur_DistanceStep[i] > length:
				index = i
				break
		
		var num = followCur_DistanceStep[index] - length
		var den = followCur_DistanceStep[index] - followCur_DistanceStep[index-1]
		if den!= 0:
			var minFac = num/den
			var pos = lerp(followCur_PathList[index],followCur_PathList[index-1],minFac)
			if followCur_reverseDrawing:
				pos = pos + EraserNoise.getNoise()
			Instance.translation = to3d(pos)

func checkTailers():
	for i in ChildList:
		i.checkTailers()
	for  i in tailers:
		WV.freeMotionLine.append(i)

func to3d(vec:Vector2) -> Vector3:
	return Vector3(vec.x,0,vec.y)
	
# warning-ignore:unused_argument
func fakeActionFunc(fac):
	pass
	
func remainder(num:float ,denum):
	return num-int(num/denum)*denum

