extends Node

var Radius = .003
var Speed = .7
var Factor=0

var LastPnt:Vector2
var FirstPnt:Vector2

func startNewNoise():
	FirstPnt = Vector2.ZERO
	var angle = randf() * 2 * PI
	LastPnt = randf() * Radius * Vector2(cos(angle),sin(angle))

func selectNewPnt():
	FirstPnt = LastPnt
	var angle = randf() * 2 * PI
	LastPnt = randf() * Radius * Vector2(cos(angle),sin(angle))

func getNoise():
	Factor += Speed 
	if Factor>1:
		selectNewPnt()
		Factor = 0
	return lerp(FirstPnt,LastPnt,Factor)
	
