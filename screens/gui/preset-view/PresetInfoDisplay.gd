extends MarginContainer

signal load_button_pressed()

onready var screenshot_display: TextureRect = $MarginContainer/VBoxContainer/ScreenshotDisplay
onready var preset_name: InputLabel = $MarginContainer/VBoxContainer/PresetName
onready var preset_description: InputLabel = $MarginContainer/VBoxContainer/PresetDescription
onready var preset_hotkey: InputLabel = $MarginContainer/VBoxContainer/PresetHotkey
onready var preset_notes: InputLabel = $MarginContainer/VBoxContainer/PresetNotes
onready var preset_set_as_default: CheckBoxLabel = $MarginContainer/VBoxContainer/PresetSetAsDefault

onready var save_button: Button = $MarginContainer/VBoxContainer/HBoxContainer/SaveButton
onready var load_button: Button = $MarginContainer/VBoxContainer/HBoxContainer/LoadButton

var screenshot_buffer_data: PoolByteArray
var preset_name_text: String
var preset_description_text: String
var preset_hotkey_text: String
var preset_notes_text: String
var preset_set_as_default_value: bool

###############################################################################
# Builtin functions                                                           #
###############################################################################

func _ready() -> void:
	if screenshot_buffer_data:
		var image: Image = Image.new()
		image.load_png_from_buffer(screenshot_buffer_data)
		var texture: ImageTexture = ImageTexture.new()
		texture.create_from_image(image)
		screenshot_display.texture = texture
	# TODO refactor this
	preset_name.label.text = "Name"
	preset_name.line_edit.text = preset_name_text
	preset_description.label.text = "Description"
	preset_description.line_edit.text = preset_description_text
	preset_hotkey.label.text = "Hotkey"
	preset_hotkey.line_edit.text = preset_hotkey_text
	preset_notes.label.text = "Notes"
	preset_notes.line_edit.text = preset_notes_text
	preset_set_as_default.label.text = "Set as default preset"
	preset_set_as_default.check_box.pressed = preset_set_as_default_value

###############################################################################
# Connections                                                                 #
###############################################################################

###############################################################################
# Private functions                                                           #
###############################################################################

###############################################################################
# Public functions                                                            #
###############################################################################

func save() -> Dictionary:
	var result: Dictionary = {}

	result["name"] = preset_name.get_value()
	result["description"] = preset_description.get_value()
	result["hotkey"] = preset_hotkey.get_value()
	result["notes"] = preset_notes.get_value()
	result["set_as_default"] = preset_set_as_default.get_value()

	return result
