extends "res://gui/tracking/tracking_gui.gd"

#-----------------------------------------------------------------------------#
# Builtin functions
#-----------------------------------------------------------------------------#

func _ready() -> void:
	var address := %Address
	var port := %Port
	
	start.pressed.connect(func() -> void:
		started.emit(AbstractTracker.Trackers.MEOW_FACE, {
			address = address.text,
			port = port.text.to_int(),
		})
	)

#-----------------------------------------------------------------------------#
# Private functions
#-----------------------------------------------------------------------------#

#-----------------------------------------------------------------------------#
# Public functions
#-----------------------------------------------------------------------------#

func get_type() -> Trackers:
	return Trackers.MEOW_FACE
