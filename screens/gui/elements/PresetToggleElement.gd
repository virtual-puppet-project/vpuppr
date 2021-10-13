extends BaseElement

onready var label: Label = $HBoxContainer/VBoxContainer/PresetName
onready var last_modified_label: Label = $HBoxContainer/VBoxContainer/LastModifiedDate

onready var toggle: CheckButton = $HBoxContainer/CheckButton

var preset_name: String
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
	# emit_signal("event", [event_name, preset_name, button_pressed])
	_handle_event([event_name, preset_name, button_pressed])

func _on_preset_toggled(p_preset_name: String, is_visible: bool) -> void:
	if not is_visible:
		return
	if not is_ready:
		yield(self, "ready")
	if p_preset_name != preset_name:
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
