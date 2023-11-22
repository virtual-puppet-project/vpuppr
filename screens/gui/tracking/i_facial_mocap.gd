extends "res://screens/gui/tracking/tracking_gui.gd"

@onready
var port := %Port

#-----------------------------------------------------------------------------#
# Builtin functions
#-----------------------------------------------------------------------------#

func _ready() -> void:
	port.text_changed.connect(func(text: String) -> void:
		if not text.is_valid_int():
			return
		property_changed.emit(Trackers.I_FACIAL_MOCAP, &"port", text.to_int())
	)
	
	start.pressed.connect(func() -> void:
		started.emit(Trackers.I_FACIAL_MOCAP)
	)

#-----------------------------------------------------------------------------#
# Private functions
#-----------------------------------------------------------------------------#

#-----------------------------------------------------------------------------#
# Public functions
#-----------------------------------------------------------------------------#

func get_type() -> Trackers:
	return Trackers.I_FACIAL_MOCAP
