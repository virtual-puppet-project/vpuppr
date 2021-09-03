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

	toggle.parent = self
	toggle.event_name = event_name
	toggle.item_name = preset_name

###############################################################################
# Connections                                                                 #
###############################################################################

func _on_preset_toggled(p_preset_name: String, is_visible: bool) -> void:
	if not is_visible:
		return
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
	toggle.pressed = value
