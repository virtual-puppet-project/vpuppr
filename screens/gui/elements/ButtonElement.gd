extends BaseElement

onready var button: Button = $Button

###############################################################################
# Builtin functions                                                           #
###############################################################################

func _ready() -> void:
	button.text = label_text

	button.disabled = is_disabled
	
	button.connect("pressed", self, "_on_pressed")

###############################################################################
# Connections                                                                 #
###############################################################################

func _on_pressed() -> void:
	_handle_event(event_name)

###############################################################################
# Private functions                                                           #
###############################################################################

###############################################################################
# Public functions                                                            #
###############################################################################

func get_value():
	return button.text

func set_value(_value) -> void:
	AppManager.log_message("Tried to set value on a Button element", true)

func setup() -> void:
	pass # Do nothing on setup
