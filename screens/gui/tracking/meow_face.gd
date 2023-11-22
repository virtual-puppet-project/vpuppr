extends "res://screens/gui/tracking/tracking_gui.gd"

@onready
var address := %Address
@onready
var port := %Port

#-----------------------------------------------------------------------------#
# Builtin functions
#-----------------------------------------------------------------------------#

func _ready() -> void:
	address.text_changed.connect(func(text: String) -> void:
		property_changed.emit(Trackers.MEOW_FACE, &"address", text)
	)
	port.text_changed.connect(func(text: String) -> void:
		if not text.is_valid_int():
			return
		property_changed.emit(Trackers.MEOW_FACE, &"port", text.to_int())
	)
	
	start.pressed.connect(func() -> void:
		started.emit(AbstractTracker.Trackers.MEOW_FACE)
	)

#-----------------------------------------------------------------------------#
# Private functions
#-----------------------------------------------------------------------------#

#-----------------------------------------------------------------------------#
# Public functions
#-----------------------------------------------------------------------------#

func get_type() -> Trackers:
	return Trackers.MEOW_FACE
