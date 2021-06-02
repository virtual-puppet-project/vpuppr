class_name ToggleLabel
extends BaseMenuItem

onready var toggle_button: CheckButton = $MarginContainer/HBoxContainer/CheckButton

var toggle_button_value: bool = false
var toggle_button_disabled: bool = false
var toggle_button_text: String

var is_linked_to_other_toggles: bool
var linked_screen_name: String

###############################################################################
# Builtin functions                                                           #
###############################################################################

func _ready() -> void:
	toggle_button.pressed = toggle_button_value
	toggle_button.disabled = toggle_button_disabled

	if toggle_button_text:
		toggle_button.text = toggle_button_text

	toggle_button.connect("pressed", self, "_on_toggle_pressed")

###############################################################################
# Connections                                                                 #
###############################################################################

func _on_toggle_pressed() -> void:
	AppManager.gui_toggle_set(self.name, linked_screen_name)

###############################################################################
# Private functions                                                           #
###############################################################################

###############################################################################
# Public functions                                                            #
###############################################################################

func get_value() -> bool:
	return toggle_button.pressed
