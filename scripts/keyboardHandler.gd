extends Control

var Sign:int = 1
var number:float
var value = ''
var state = false

func _input(event):	
	if event is InputEventKey and !get_focus_owner():
		
		if WV.drawingScreen.insideField():
			if event.pressed:
				var n = event.scancode-48
				if n >=0 and n <=9:
					value+=str(n)
					updateNumber()

			if Input.is_action_pressed("backSpace"):
				if value.length():
					eraseLast()
					updateNumber()

			if Input.is_action_just_pressed("minus"):
				Sign *=-1
				updateNumber()

			if Input.is_action_just_pressed("."):
				if not '.' in value:
					value +='.'
					updateNumber()

func updateNumber():
	state = !value.empty()
	number = float(value) * Sign * 10
	WV.drawingScreen.dashBox.changeState('Keyboard' ,state)
	

func eraseLast():
	var v = '' 
	for i in value.length()-1:
		v+=value[i]
	value = v

func reset():
	Sign = 1
	value = ''
	updateNumber()
	WV.drawingScreen.dashBox.changeState('Keyboard' ,false)
