extends VBoxContainer

signal message_received(message: GUIMessage)

const OPTION_KEY := &"puppet_data"

var _logger := Logger.create("General")

@onready
var _enable_fly_camera := %EnableFlyCamera

@onready
var _model_x_position := %ModelXPosition
@onready
var _model_y_position := %ModelYPosition
@onready
var _model_z_position := %ModelZPosition

#-----------------------------------------------------------------------------#
# Builtin functions
#-----------------------------------------------------------------------------#

func _ready() -> void:
	_enable_fly_camera.message_received.connect(func(message: GUIMessage) -> void:
		message.action = GUIMessage.FLY_CAMERA
		
		message_received.emit(message)
	)
	
	_model_x_position.message_received.connect(func(message: GUIMessage) -> void:
		message_received.emit(message.to_data_update(
			OPTION_KEY,
			"position:x",
			message.value
		))
	)
	_model_y_position.message_received.connect(func(message: GUIMessage) -> void:
		message_received.emit(message.to_data_update(
			OPTION_KEY,
			"position:y",
			message.value
		))
	)
	_model_z_position.message_received.connect(func(message: GUIMessage) -> void:
		message_received.emit(message.to_data_update(
			OPTION_KEY,
			"position:z",
			message.value
		))
	)

#-----------------------------------------------------------------------------#
# Private functions
#-----------------------------------------------------------------------------#

#-----------------------------------------------------------------------------#
# Public functions
#-----------------------------------------------------------------------------#

func update(context: Context) -> void:
	pass
