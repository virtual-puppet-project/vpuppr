class_name ColorPickerLabel
extends BaseMenuItem

const SHOW_TEXT: String = "Show"
const HIDE_TEXT: String = "Hide"

onready var show_hide_button: Button = $MarginContainer/HBoxContainer/VBoxContainer/ShowHideButton
onready var color_picker: ColorPicker = $MarginContainer/HBoxContainer/VBoxContainer/ColorPicker

var color_picker_color: Color

###############################################################################
# Builtin functions                                                           #
###############################################################################

func _ready() -> void:
	if color_picker_color:
		color_picker.color = color_picker_color
	
	show_hide_button.text = SHOW_TEXT
	
	show_hide_button.connect("pressed", self, "_on_show_hide_button_pressed")

###############################################################################
# Connections                                                                 #
###############################################################################

func _on_show_hide_button_pressed() -> void:
	if not color_picker.visible:
		color_picker.visible = true
		show_hide_button.text = HIDE_TEXT
	else:
		color_picker.visible = false
		show_hide_button.text = SHOW_TEXT

###############################################################################
# Private functions                                                           #
###############################################################################

###############################################################################
# Public functions                                                            #
###############################################################################

func get_value() -> Color:
	return color_picker.color
