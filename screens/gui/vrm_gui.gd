extends DefaultGui

#-----------------------------------------------------------------------------#
# Builtin functions
#-----------------------------------------------------------------------------#

func _ready() -> void:
	_logger.set_name("VrmGui")
	
	for i in [
		[%Model, "res://screens/gui/model/vrm.tscn"],
		[%Tracking, "res://screens/gui/tracking/tracking.tscn"],
		[%Scene, "res://screens/gui/scene/scene.tscn"]
	]:
		i[0].pressed.connect(add_popup.bind(i[0].text, i[1]))
	
	super._ready()

#-----------------------------------------------------------------------------#
# Private functions
#-----------------------------------------------------------------------------#

#-----------------------------------------------------------------------------#
# Public functions
#-----------------------------------------------------------------------------#
