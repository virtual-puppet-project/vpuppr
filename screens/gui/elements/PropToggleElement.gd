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
	
	toggle.parent = self
	toggle.event_name = event_name
	toggle.item_name = prop_name

###############################################################################
# Connections                                                                 #
###############################################################################

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
	toggle.pressed = value
