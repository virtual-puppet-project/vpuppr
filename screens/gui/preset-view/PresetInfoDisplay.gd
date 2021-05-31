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

###############################################################################
# Builtin functions                                                           #
###############################################################################

func _ready() -> void:
	save_button.connect("pressed", self, "_on_save")

###############################################################################
# Connections                                                                 #
###############################################################################

func _on_save() -> void:
	pass

###############################################################################
# Private functions                                                           #
###############################################################################

###############################################################################
# Public functions                                                            #
###############################################################################
