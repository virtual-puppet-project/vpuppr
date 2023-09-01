extends TrackingGui

#-----------------------------------------------------------------------------#
# Builtin functions
#-----------------------------------------------------------------------------#

func _ready() -> void:
	var connect_address := %ConnectAddress
	var connect_port := %ConnectPort
	var bind_port := %BindPort
	
	%Start.pressed.connect(func() -> void:
		started.emit(AbstractTracker.Trackers.MEOW_FACE, {
			connect_address = connect_address.text,
			connect_port = connect_port.text.to_int(),
			bind_port = bind_port.text.to_int(),
		})
	)

#-----------------------------------------------------------------------------#
# Private functions
#-----------------------------------------------------------------------------#

#-----------------------------------------------------------------------------#
# Public functions
#-----------------------------------------------------------------------------#

