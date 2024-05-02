extends Node

var Key = ['a','b','c','d','e','f','g','h','i','j','k','l','m','n','o','p','q']

func getId(_length):
	randomize()
	var id = ''
	for i in _length:
		var index = int(randf() * Key.size())
		id += Key[index]
	return id

