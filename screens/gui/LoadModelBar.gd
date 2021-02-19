extends MarginContainer

###############################################################################
# Builtin functions                                                           #
###############################################################################

func _ready() -> void:
	$Control/MarginContainer/HBoxContainer/LoadVRMModelButton.connect("pressed", self, "_on_load_vrm_model_button_pressed")
	$Control/MarginContainer/HBoxContainer/LoadBasicModelButton.connect("pressed", self, "_on_load_basic_model_button_pressed")

###############################################################################
# Connections                                                                 #
###############################################################################

func _on_load_vrm_model_button_pressed() -> void:
	var model_selection_popup: FileDialog = load("res://screens/gui/ModelSelectionPopup.tscn").instance()
	model_selection_popup.model_type = AppManager.ModelType.VRM
	get_parent().add_child(model_selection_popup)
	
	yield(model_selection_popup, "file_selected")
	model_selection_popup.queue_free()

func _on_load_basic_model_button_pressed() -> void:
	var model_selection_popup: FileDialog = load("res://screens/gui/ModelSelectionPopup.tscn").instance()
	model_selection_popup.model_type = AppManager.ModelType.GENERIC
	get_parent().add_child(model_selection_popup)
	
	yield(model_selection_popup, "file_selected")
	model_selection_popup.queue_free()

###############################################################################
# Private functions                                                           #
###############################################################################

###############################################################################
# Public functions                                                            #
###############################################################################


