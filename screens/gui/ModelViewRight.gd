extends BaseSidebar

var initial_properties: Dictionary = {}

###############################################################################
# Builtin functions                                                           #
###############################################################################

func _ready() -> void:
	$Control/MarginContainer/VBoxContainer/LoadModelButton.connect("pressed", self, "_on_load_model_button_pressed")
	
	if (main_screen.model_display_screen and main_screen.model_display_screen.model):
		_setup()

###############################################################################
# Connections                                                                 #
###############################################################################

func _on_apply_button_pressed() -> void:
	_apply_properties()

func _on_reset_button_pressed() -> void:
	_generate_properties(initial_properties)

func _on_load_model_button_pressed() -> void:
	var model_selection_popup: FileDialog = load("res://screens/gui/ModelSelectionPopup.tscn").instance()
	get_parent().add_child(model_selection_popup)
	
	yield(model_selection_popup, "file_selected")
	model_selection_popup.queue_free()

###############################################################################
# Private functions                                                           #
###############################################################################

func _generate_properties(p_initial_properties: Dictionary = {}) -> void:
	for child in v_box_container.get_children():
		child.free()

	# TODO test this with a vrm model
	# yield(get_tree().create_timer(1.0), "timeout")

	var data_source = p_initial_properties
	
	if current_model:
		if p_initial_properties.empty():
			data_source = current_model
		_create_element(ElementType.INPUT, "translation_damp", "Translation Damp",
				data_source.translation_damp, TYPE_REAL)

		_create_element(ElementType.INPUT, "rotation_damp", "Rotation Damp",
				data_source.rotation_damp, TYPE_REAL)

		_create_element(ElementType.INPUT, "additional_bone_damp", "Additional Bone Damp",
				data_source.additional_bone_damp, TYPE_REAL)

	if p_initial_properties.empty():
		data_source = main_screen.model_display_screen

	_create_element(ElementType.CHECK_BOX, "apply_translation", "Apply Translation",
			data_source.apply_translation)

	_create_element(ElementType.CHECK_BOX, "apply_rotation", "Apply Rotation",
			data_source.apply_rotation)

	_create_element(ElementType.CHECK_BOX, "interpolate_model", "Interpolate Model",
			data_source.interpolate_model)
	
	_create_element(ElementType.INPUT, "interpolation_rate", "Interpolation Rate",
			data_source.interpolation_rate, TYPE_REAL)

func _apply_properties() -> void:
	for c in v_box_container.get_children():
		# Null checks and value checks
		if c.get("line_edit"):
			if c.line_edit.text.empty():
				continue
			if c.line_edit_type == TYPE_REAL:
				if not c.line_edit.text.is_valid_float():
					continue
		match c.name:
			"translation_damp":
				current_model.translation_damp = c.get_value()
			"rotation_damp":
				current_model.rotation_damp = c.get_value()
			"additional_bone_damp":
				current_model.additional_bone_damp = c.get_value()
			"apply_translation":
				main_screen.model_display_screen.apply_translation = c.get_value()
			"apply_rotation":
				main_screen.model_display_screen.apply_rotation = c.get_value()
			"interpolate_model":
				main_screen.model_display_screen.interpolate_model = c.get_value()
			"interpolation_rate":
				main_screen.model_display_screen.interpolation_rate = c.get_value()

func _setup() -> void:
	current_model = main_screen.model_display_screen.model

	_generate_properties()
	
	# Store initial properties
	for child in v_box_container.get_children():
		if child.get("check_box"):
			initial_properties[child.name] = child.check_box.pressed
		elif child.get("line_edit"):
			initial_properties[child.name] = child.line_edit.text

###############################################################################
# Public functions                                                            #
###############################################################################
