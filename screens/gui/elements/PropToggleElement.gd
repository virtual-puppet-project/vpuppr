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

func _exit_tree() -> void:
	toggle.disconnect("toggled", self, "_on_toggled")

###############################################################################
# Connections                                                                 #
###############################################################################

func _on_toggled(button_state: bool) -> void:
	emit_signal("event", [event_name, prop_name, button_state])

func _on_prop_toggled(p_prop_name: String, is_visible: bool) -> void:
	if not is_visible:
		return
	if p_prop_name != prop_name:
		toggle.disconnect("toggled", self, "_on_toggled")
		toggle.pressed = false
		toggle.connect("toggled", self, "_on_toggled")

###############################################################################
# Private functions                                                           #
###############################################################################

###############################################################################
# Public functions                                                            #
###############################################################################

func get_value():
	return toggle.pressed

func set_value(value) -> void:
	toggle.pressed = value
