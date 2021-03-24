class_name BaseSidebar
extends Control

const CHECK_BOX_LABEL: Resource = preload("res://screens/gui/elements/CheckBoxLabel.tscn")

onready var v_box_container: VBoxContainer = $Control/MarginContainer/VBoxContainer/ScrollContainer/VBoxContainer

onready var main_screen: MainScreen = get_tree().root.get_node_or_null("MainScreen")
var current_model: BasicModel

###############################################################################
# Builtin functions                                                           #
###############################################################################

func _ready() -> void:
	AppManager.connect("model_loaded", self, "_on_model_loaded")

	AppManager.connect("properties_applied", self, "_on_apply_button_pressed")
	AppManager.connect("properties_reset", self, "_on_reset_button_pressed")

	if (main_screen.model_display_screen and main_screen.model_display_screen.model):
		# TODO will be called twice when program starts since UI
		# and model are loaded at the same time
		_on_model_loaded(main_screen.model_display_screen.model)

###############################################################################
# Connections                                                                 #
###############################################################################

func _on_model_loaded(model_reference: BasicModel) -> void:
	current_model = model_reference

func _on_apply_button_pressed() -> void:
	push_error("Not yet implemented")

func _on_reset_button_pressed() -> void:
	push_error("Not yet implemented")

###############################################################################
# Private functions                                                           #
###############################################################################

###############################################################################
# Public functions                                                            #
###############################################################################
