extends VBoxContainer

signal message_received(message: GUIMessage)

const OPTION_KEY := &"common_options:environment_options"

var _logger := Logger.create("Environment")

@onready
var _background_type := %BackgroundType
@onready
var _chromakey_color := %ChromakeyColor

#-----------------------------------------------------------------------------#
# Builtin functions
#-----------------------------------------------------------------------------#

func _ready() -> void:
	_background_type.message_received.connect(func(message: GUIMessage) -> void:
		# The value must be transformed before passing back to the config since the [Environment]
		# resource works off of enum ints but we display those values as strings
		message.value.value = EnvironmentUtil.background_mode_string_to_enum(message.value.value)
		message_received.emit(message)
	)
	
	_chromakey_color.message_received.connect(_forward)

#-----------------------------------------------------------------------------#
# Private functions
#-----------------------------------------------------------------------------#

func _forward(message: GUIMessage) -> void:
	message_received.emit(message)

#-----------------------------------------------------------------------------#
# Public functions
#-----------------------------------------------------------------------------#

func update(context: Context) -> void:
	var environment: Environment = context.runner_data.common_options.environment_options
	
	_background_type.update_option_button(
		EnvironmentUtil.background_mode_enum_to_string(environment.background_mode),
		EnvironmentUtil.EnvironmentBackground.values()
	)

	_chromakey_color.update_color_picker_button(environment.background_color)
