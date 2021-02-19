class_name ModelPropertiesSelector
extends BaseSidebar

enum ElementType { INPUT, CHECK_BOX }

const INPUT_LABEL: Resource = preload("res://screens/gui/elements/InputLabel.tscn")

var initial_properties: Dictionary = {}

###############################################################################
# Builtin functions                                                           #
###############################################################################

###############################################################################
# Connections                                                                 #
###############################################################################

func _on_model_loaded(model_reference: BasicModel) -> void:
	._on_model_loaded(model_reference)

	yield(_generate_properties(), "completed")
	
	# Store initial properties
	for child in v_box_container.get_children():
		if child.get("check_box"):
			initial_properties[child.name] = child.check_box.pressed
		elif child.get("line_edit"):
			initial_properties[child.name] = child.line_edit.text
		

func _on_apply_button_pressed() -> void:
	_apply_properties()

func _on_reset_button_pressed() -> void:
	_reset_properties()

###############################################################################
# Private functions                                                           #
###############################################################################

func _generate_properties(p_initial_properties: Dictionary = {}) -> void:
	for child in v_box_container.get_children():
		child.free()

	yield(get_tree().create_timer(1.0), "timeout")

	var data_source = p_initial_properties
	
	if current_model:
		if p_initial_properties.empty():
			data_source = current_model
		_create_element(ElementType.INPUT, "translation_damp", "Translation Damp",
				data_source.translation_damp)

		_create_element(ElementType.INPUT, "rotation_damp", "Rotation Damp",
				data_source.rotation_damp)

		_create_element(ElementType.INPUT, "additional_bone_damp", "Additional Bone Damp",
				data_source.additional_bone_damp)

	# TODO add way to dynamically find the model display screen
	var main_screen = get_tree().root.get_node_or_null("MainScreen")
	if main_screen:
		if p_initial_properties.empty():
			data_source = main_screen.model_display_screen

		_create_element(ElementType.CHECK_BOX, "apply_translation", "Apply Translation",
				data_source.apply_translation)

		_create_element(ElementType.CHECK_BOX, "apply_rotation", "Apply Rotation",
				data_source.apply_rotation)

		_create_element(ElementType.CHECK_BOX, "interpolate_model", "Interpolate Model",
				data_source.interpolate_model)
		
		_create_element(ElementType.INPUT, "interpolation_rate", "Interpolation Rate",
				data_source.interpolation_rate)

func _apply_properties() -> void:
	var property_list: Dictionary = {}
	for child in v_box_container.get_children():
		if child.get("check_box"):
			property_list[child.name] = child.check_box.pressed
		elif child.get("line_edit"):
			var line_edit_value: String = child.line_edit.text
			if line_edit_value.is_valid_float():
				property_list[child.name] = child.line_edit.text
			else:
				push_error("Invalid value for " + child.name)
				return

	AppManager.emit_signal("properties_applied", property_list)

# TODO refactor this since most of the code is duplicated?
func _reset_properties() -> void:
	"""
	Almost exactly like _generate_properties except we pull values from our
	stored initial_properties dictionary
	"""
	for child in v_box_container.get_children():
		child.free()

	yield(get_tree().create_timer(1.0), "timeout")

	if current_model:
		_create_element(ElementType.INPUT, "translation_damp", "Translation Damp",
				initial_properties.translation_damp)

		_create_element(ElementType.INPUT, "rotation_damp", "Rotation Damp",
				initial_properties.rotation_damp)

		_create_element(ElementType.INPUT, "additional_bone_damp", "Additional Bone Damp",
				initial_properties.additional_bone_damp)

	# TODO add way to dynamically find the model display screen
	var main_screen = get_tree().root.get_node_or_null("MainScreen")
	if main_screen:
		_create_element(ElementType.CHECK_BOX, "apply_translation", "Apply Translation",
				initial_properties.apply_translation)

		_create_element(ElementType.CHECK_BOX, "apply_rotation", "Apply Rotation",
				initial_properties.apply_rotation)

		_create_element(ElementType.CHECK_BOX, "interpolate_model", "Interpolate Model",
				initial_properties.interpolate_model)
		
		_create_element(ElementType.INPUT, "interpolation_rate", "Interpolation Rate",
				initial_properties.interpolation_rate)

func _create_element(element_type: int, element_name: String, element_label_text: String, element_value) -> void:
	var result: Node
	match element_type:
		ElementType.INPUT:
			result = INPUT_LABEL.instance()
			result.line_edit_text = element_value
		ElementType.CHECK_BOX:
			result = CHECK_BOX_LABEL.instance()
			result.check_box_value = element_value
		_:
			push_error("Unhandled element type")

	result.name = element_name
	result.label_text = element_label_text
	
	v_box_container.add_child(result)

###############################################################################
# Public functions                                                            #
###############################################################################


