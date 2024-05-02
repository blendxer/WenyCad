extends Control

func changelabel(_s):
	$Label.text = _s
	$Label.modulate = Color.from_hsv(randf(),rand_range(0,.7),rand_range(.7,1),1)

func _on_Timer_timeout():
	queue_free()
