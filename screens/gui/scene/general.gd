extends VBoxContainer

signal message_received(message: GUIMessage)

@onready
var _enable_fly_camera := %EnableFlyCamera

#-----------------------------------------------------------------------------#
# Builtin functions
#-----------------------------------------------------------------------------#

func _ready() -> void:
	_enable_fly_camera.message_received.connect(func(message: GUIMessage) -> void:
		message.action = GUIMessage.FLY_CAMERA
		
		message_received.emit(message)
	)

#-----------------------------------------------------------------------------#
# Private functions
#-----------------------------------------------------------------------------#

#-----------------------------------------------------------------------------#
# Public functions
#-----------------------------------------------------------------------------#

func update(context: Context) -> void:
	pass
