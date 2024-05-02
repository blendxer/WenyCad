extends Node



var dict={
	'circleObject/presetting/type':'posRadius',
	'compassorObject/presetting/type':'freeAlign',
	'lengthLabelObject/presetting/type':'length',
	
	'snapMenu/activeIndex':Vector2(),
	'snapMenu/otherIndex':Vector2(),
	
	'distribution/ChooiceIndex':0,
	'distribution/lockVec':'vertical',
	'distribution/lockAxisVec':Vector2(0,1),
	'distribution/constantShift': 1,
	'distribution/pickedPos_0': Vector2(0,0),
	'distribution/pickedPos_1': Vector2(0,0),
	'distribution/pickedPos_2': Vector2(0,0),
	'distribution/radius':1,
	'distribution/startAngle':0,
	'distribution/endAngle':360,
	'distribution/gridOrder/type':'by column',
	'distribution/gridOrder/vec':Vector2(1,-1),
	'distribution/gridOrder/count':1,
	
	'animation/engineType':'basic',
	'animation/speed':1,
	'animation/fps':24,
	
	'gird/dynamicState':true,
	'gird/mainColor':Color(1,1,1,.3),
	'gird/subColor':Color(.5,1,1,.2),
	
	'keycastShowState':false,
	
	
	'exportImage/exportRect':Rect2(100,100,200,200),
	'exportImage/backgroundColor':Color('555555'),
	'exportImage/sizeRatio/x':1,
	'exportImage/sizeRatio/y':1,
	
	
}

func save(_title,_value):
	dict[_title] = _value

func fetch(_title):
	return dict[_title]


#func get(_title):
#	return dict[_title]
