extends BaseElement

onready var label: Label = $HBoxContainer/Label
onready var toggle: CheckButton = $HBoxContainer/CheckButton

var toggle_value: bool = false

###############################################################################
# Builtin functions                                                           #
###############################################################################

func _ready() -> void:
	label.text = label_text
	toggle.pressed = toggle_value
	
	toggle.connect("toggled", self, "_on_toggled")

###############################################################################
# Connections                                                                 #
###############################################################################

func _on_toggled(button_state: bool) -> void:
	_handle_event([event_name, button_state])

###############################################################################
# Private functions                                                           #
###############################################################################

###############################################################################
# Public functions                                                            #
###############################################################################

func get_value():
	return toggle.pressed

func set_value(value) -> void:
	toggle.set_pressed_no_signal(value)
