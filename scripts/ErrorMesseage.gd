extends Node

const dict:={
	'0':'There is no Selected layer Select any layer to paint on',
	'1':'redo log is empty !', 
	'2':'undo log is empty !',
	'3':'There no selected object',
	'4':"You can't change zoom at  object edit mode or object paintings mode",
	'5':'Select any paint tool to before painting',
	'6':"you can't cut circle that already has some erased part",
	'7':"There is no any action to export",
	'8':"you can't scale distance or angle label",
	'9':"you reach the maximum canvas size  unable to move further",
	'10':"hold shift for multiselectoin ,hold alt for deselection  when you hold both what expect me to do ???",
	'11':"you can't paint on hiden layer",
	'12':"insert start value at the least",
	'13':"insert at the least one value of start and end from the panel on left",
	'14':"You can only erase circle with uniform scale",
	'15':"You can only cut circle with uniform scale",
	'16':"you must unhide the upper layer to show this layer",
	'17':"you must select objects to be able to open snap menu",
	'18':"you must select at least 3 object to open object distribution menu",
	'19':"invalid shift value",
	'20':"there is no active layer",
	'21':"File Saved Successfully",
	'22':"you can't rotate distance or angle label",
	'23':"please don't place mouse point on the selection origin and start scaling because that will mean infinite scale",
	'24':"there is no object in the clipboard",



}


func get(index):
	return dict[index]
	
