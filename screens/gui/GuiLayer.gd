extends CanvasLayer

###############################################################################
# Builtin functions                                                           #
###############################################################################

func _ready() -> void:
	$ControlBar/HBoxContainer/LoadVRMModelButton.connect("pressed", self, "_on_load_vrm_model_button_pressed")
	$ControlBar/HBoxContainer/LoadBasicModelButton.connect("pressed", self, "_on_load_basic_model_button_pressed")

func _input(event: InputEvent) -> void:
	if event.is_action_pressed("toggle_gui"):
		for c in get_children():
			c.visible = not c.visible

###############################################################################
# Connections                                                                 #
###############################################################################

func _on_load_vrm_model_button_pressed() -> void:
	var model_selection_popup: FileDialog = load("res://screens/gui/ModelSelectionPopup.tscn").instance()
	model_selection_popup.model_type = AppManager.ModelType.VRM
	add_child(model_selection_popup)
	
	yield(model_selection_popup, "file_selected")
	model_selection_popup.queue_free()

func _on_load_basic_model_button_pressed() -> void:
	var model_selection_popup: FileDialog = load("res://screens/gui/ModelSelectionPopup.tscn").instance()
	model_selection_popup.model_type = AppManager.ModelType.GENERIC
	add_child(model_selection_popup)
	
	yield(model_selection_popup, "file_selected")
	model_selection_popup.queue_free()

###############################################################################
# Private functions                                                           #
###############################################################################

###############################################################################
# Public functions                                                            #
###############################################################################


