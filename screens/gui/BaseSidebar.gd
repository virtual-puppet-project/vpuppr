class_name BaseSidebar
extends MarginContainer

const CHECK_BOX_LABEL: Resource = preload("res://screens/gui/elements/CheckBoxLabel.tscn")

onready var v_box_container: VBoxContainer = $Control/MarginContainer/VBoxContainer/ScrollContainer/VBoxContainer

var current_model: BasicModel

###############################################################################
# Builtin functions                                                           #
###############################################################################

func _ready() -> void:
	AppManager.connect("model_loaded", self, "_on_model_loaded")
	
	$Control/MarginContainer/VBoxContainer/HBoxContainer/MarginContainer/ApplyButton.connect("pressed", self, "_on_apply_button_pressed")
	$Control/MarginContainer/VBoxContainer/HBoxContainer/MarginContainer2/ResetButton.connect("pressed", self, "_on_reset_button_pressed")

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


