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
	# AppManager.update_config(self.name, _save())

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
		_create_element(ElementType.LABEL, "bone_movement_damps", "Bone Movement Damps")
		_create_element(ElementType.INPUT, "translation_damp", "Translation Damp",
				data_source.translation_damp, TYPE_REAL)

		_create_element(ElementType.INPUT, "rotation_damp", "Rotation Damp",
				data_source.rotation_damp, TYPE_REAL)

		_create_element(ElementType.INPUT, "additional_bone_damp", "Additional Bone Damp",
				data_source.additional_bone_damp, TYPE_REAL)

	if p_initial_properties.empty():
		data_source = main_screen.model_display_screen

	_create_element(ElementType.LABEL, "tracking_options", "Tracking Options")
	_create_element(ElementType.CHECK_BOX, "apply_translation", "Apply Translation",
			data_source.apply_translation)

	_create_element(ElementType.CHECK_BOX, "apply_rotation", "Apply Rotation",
			data_source.apply_rotation)

	_create_element(ElementType.LABEL, "interpolation_options", "Interpolation Options")
	_create_element(ElementType.CHECK_BOX, "interpolate_model", "Interpolate Model",
			data_source.interpolate_model)
	
	_create_element(ElementType.INPUT, "interpolation_rate", "Interpolation Rate",
			data_source.interpolation_rate, TYPE_REAL)

func _apply_properties() -> void:
	# Interpolation data must be handled in a specific order since we don't check for interpolation anymore
	main_screen.model_display_screen.interpolate_model = v_box_container.get_node("interpolate_model").get_value()
	if not main_screen.model_display_screen.interpolate_model:
		main_screen.model_display_screen.interpolation_rate = 1.0
	else:
		main_screen.model_display_screen.interpolation_rate = v_box_container.get_node("interpolation_rate").get_value()

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

func _setup() -> void:
	current_model = main_screen.model_display_screen.model

	var loaded_config: Dictionary = AppManager.get_sidebar_config_safe(self.name)
	if not loaded_config.empty():
		for key in loaded_config.keys():
			initial_properties[key] = loaded_config[key]
		_generate_properties(initial_properties)
		_apply_properties()
	else:
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

func save() -> Dictionary:
	var result: Dictionary = {}

	for c in v_box_container.get_children():
		# Null checks and value checks
		if c.get("line_edit"):
			if c.line_edit.text.empty():
				continue
			if c.line_edit_type == TYPE_REAL:
				if not c.line_edit.text.is_valid_float():
					continue
		if c is CenteredLabel:
			continue
		
		result[c.name] = c.get_value()

	return result
