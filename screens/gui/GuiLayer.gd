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
	var model_selection: FileDialog = load("res://screens/gui/ModelSelection.tscn").instance()
	model_selection.model_type = "vrm"
	add_child(model_selection)
	
	yield(model_selection, "file_selected")
	model_selection.queue_free()

func _on_load_basic_model_button_pressed() -> void:
	var model_selection: FileDialog = load("res://screens/gui/ModelSelection.tscn").instance()
	model_selection.model_type = "basic"
	add_child(model_selection)
	
	yield(model_selection, "file_selected")
	model_selection.queue_free()

###############################################################################
# Private functions                                                           #
###############################################################################

###############################################################################
# Public functions                                                            #
###############################################################################


