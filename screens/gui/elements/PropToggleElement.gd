extends BaseElement

onready var label: Label = $HBoxContainer/Label
onready var toggle: CheckButton = $HBoxContainer/CheckButton

var prop_name: String
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

func _on_toggled(button_pressed: bool) -> void:
	_handle_event([event_name, prop_name, button_pressed])

func _on_prop_toggled(p_prop_name: String, is_visible: bool) -> void:
	if not is_visible:
		return
	if p_prop_name != prop_name:
		toggle.pressed = false

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
