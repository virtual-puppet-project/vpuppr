class_name ModelView
extends BaseView

const MODEL_SELECTION_POPUP: Resource = preload("res://screens/gui/model-view/ModelSelectionPopup.tscn")

var initial_properties: Dictionary = {}

var initial_bone_state: Array = []
var mapped_bones: Array = []

###############################################################################
# Builtin functions                                                           #
###############################################################################

func _ready() -> void:
	_setup()

###############################################################################
# Connections                                                                 #
###############################################################################

func _on_apply_button_pressed() -> void:
	_trigger_bone_remap()

func _on_reset_button_pressed() -> void:
	_reset_bone_values()

func _on_load_model_button_pressed() -> void:
	var model_selection_popup: FileDialog = MODEL_SELECTION_POPUP.instance()
	get_parent().add_child(model_selection_popup)
	
	yield(model_selection_popup, "file_selected")
	model_selection_popup.queue_free()

func _set_model_default_button_pressed() -> void:
	AppManager.set_model_default()

func _on_default_model_set() -> void:
	var default_button: Button = right_container.outer.get_node_or_null("set_model_default_button")
	if default_button:
		default_button.disabled = true

###############################################################################
# Private functions                                                           #
###############################################################################

###
# Left
###

func _setup_left(config: Dictionary) -> void:
	if not config.empty():
		mapped_bones = config["left"]["mapped_bones"].duplicate()
		current_model.additional_bones_to_pose_names = mapped_bones
		current_model.scan_mapped_bones()
	else:
		mapped_bones = current_model.additional_bones_to_pose_names

	initial_bone_state = current_model.additional_bones_to_pose_names

	_generate_bone_list()

func _generate_bone_list() -> void:
	left_container.clear_children()

	left_container.add_to_inner(_create_element(ElementType.LABEL, "bone_list", "Bone list"))

	# TODO a complete list of bones in the model is only accessible from this function
	# That doesn't seem like it makes sense
	var bone_values: Dictionary = current_model.get_mapped_bones()
	for bone_name in bone_values.keys():
		var check_box_label = CHECK_BOX_LABEL.instance()
		check_box_label.check_box_text = "Mapping"
		check_box_label.label_text = bone_name
		check_box_label.check_box_value = bone_values[bone_name]
		left_container.add_to_inner(check_box_label)

func _trigger_bone_remap() -> void:
	mapped_bones = _get_mapped_bones(left_container.get_inner_children())

	current_model.additional_bones_to_pose_names = mapped_bones
	current_model.scan_mapped_bones()

func _reset_bone_values() -> void:
	current_model.additional_bones_to_pose_names = initial_bone_state
	current_model.reset_all_bone_poses()
	_generate_bone_list()

static func _get_mapped_bones(bone_list: Array) -> Array:
	var result: Array = []

	for b in bone_list:
		if (b is CheckBoxLabel and b.get_value()):
			result.append(b.label_text)
	
	return result

###
# Right
###

func _setup_right(config: Dictionary) -> void:
	if not config.empty():
		for key in config["right"].keys():
			initial_properties[key] = config["right"][key]
		_generate_properties(initial_properties)
		_apply_properties()
	else:
		_generate_properties()

		# Store initial properties
		for c in right_container.get_inner_children():
			if c is CheckBoxLabel:
				initial_properties[c.name] = c.get_value()
			elif c is InputLabel:
				initial_properties[c.name] = c.get_value()

	if not right_container.outer.get_node_or_null("set_model_default_button"):
		var set_model_default_button: Button = Button.new()
		set_model_default_button.name = "set_model_default_button"
		set_model_default_button.text = "Set as default"
		set_model_default_button.size_flags_vertical = SIZE_EXPAND_FILL
		set_model_default_button.size_flags_vertical = SIZE_EXPAND_FILL
		set_model_default_button.size_flags_stretch_ratio = 0.1
		set_model_default_button.focus_mode = FOCUS_NONE
		set_model_default_button.connect("pressed", self, "_set_model_default_button_pressed")
		right_container.add_to_outer(set_model_default_button)

	var tempButton: Button = right_container.outer.get_node_or_null("set_model_default_button")
	# Toggle button disabled property if model is or is not default
	if AppManager.is_current_model_default():
		tempButton.disabled = true
	else:
		tempButton.disabled = false

	if not right_container.outer.get_node_or_null("load_model_button"):
		var load_model_button: Button = Button.new()
		load_model_button.name = "load_model_button"
		load_model_button.text = "Load model"
		load_model_button.size_flags_vertical = SIZE_EXPAND_FILL
		load_model_button.size_flags_stretch_ratio = 0.1
		load_model_button.focus_mode = FOCUS_NONE
		load_model_button.connect("pressed", self, "_on_load_model_button_pressed")
		right_container.add_to_outer(load_model_button)

func _generate_properties(p_initial_properties: Dictionary = {}) -> void:
	right_container.clear_children()
	
	# No type annotation because we make use of duck typing
	var data_source = p_initial_properties

	# Bone damps
	if p_initial_properties.empty():
		data_source = current_model
	right_container.add_to_inner(_create_element(ElementType.LABEL,
			"bone_movement_damps", "Bone Movement Damps"))
	right_container.add_to_inner(_create_element(ElementType.INPUT,
			"translation_damp", "Translation Damp", data_source.translation_damp,
			TYPE_REAL))
	right_container.add_to_inner(_create_element(ElementType.INPUT,
			"rotation_damp", "Rotation Damp", data_source.rotation_damp, TYPE_REAL))
	right_container.add_to_inner(_create_element(ElementType.INPUT,
			"additional_bone_damp", "Additional Bone Damp",
			data_source.additional_bone_damp, TYPE_REAL))

	# Tracking options
	if p_initial_properties.empty():
		data_source = main_screen.model_display_screen
	right_container.add_to_inner(_create_element(ElementType.LABEL, "tracking_options",
			"Tracking Options"))
	
	var head_bone_name: String = ""
	if current_model.is_head_bone_id_set():
		head_bone_name = current_model.HEAD_BONE
	right_container.add_to_inner(_create_element(ElementType.INPUT, "head_bone",
			"Head Bone", head_bone_name, TYPE_STRING))

	right_container.add_to_inner(_create_element(ElementType.CHECK_BOX, "apply_translation",
			"Apply Translation", data_source.apply_translation))
	right_container.add_to_inner(_create_element(ElementType.CHECK_BOX, "apply_rotation",
			"Apply Rotation", data_source.apply_rotation))

	right_container.add_to_inner(_create_element(ElementType.LABEL, "interpolation_options",
			"Interpolation Options"))
	right_container.add_to_inner(_create_element(ElementType.CHECK_BOX, "interpolate_model",
			"Interpolate Model", data_source.interpolate_model))

	right_container.add_to_inner(_create_element(ElementType.INPUT, "interpolation_rate",
			"Interpolation Rate", data_source.interpolation_rate, TYPE_REAL))

func _apply_properties() -> void:
	# Interpolation data must be handled in a specific order since we don't
	# check for interpolation anymore
	main_screen.model_display_screen.interpolate_model = right_container.inner.get_node("interpolate_model").get_value()
	if not main_screen.model_display_screen.interpolate_model:
		main_screen.model_display_screen.interpolation_rate = 1.0
	else:
		main_screen.model_display_screen.interpolation_rate = right_container.inner.get_node("interpolation_rate").get_value()

	for c in right_container.get_inner_children():
		# Null check and value check
		if c is InputLabel:
			if c.line_edit.text.empty():
				continue
			elif (c.line_edit_type == TYPE_REAL and not c.line_edit.text.is_valid_float()):
				continue

		match c.name:
			"translation_damp":
				current_model.translation_damp = c.get_value()
			"rotation_damp":
				current_model.rotation_damp = c.get_value()
			"additional_bone_damp":
				current_model.additional_bone_damp = c.get_value()
			"head_bone":
				current_model.head_bone_id = current_model.skeleton.find_bone(c.get_value())
			"apply_translation":
				main_screen.model_display_screen.apply_translation = c.get_value()
			"apply_rotation":
				main_screen.model_display_screen.apply_rotation = c.get_value()

###############################################################################
# Public functions                                                            #
###############################################################################

func save() -> Dictionary:
	var result: Dictionary = {}

	# Left container
	result["left"] = {}
	result["left"]["mapped_bones"] = mapped_bones

	# Right container
	result["right"] = {}
	for c in right_container.get_inner_children():
		if c is InputLabel:
			if c.line_edit.text.empty():
				continue
			elif (c.line_edit_type == TYPE_REAL and not c.line_edit.text.is_valid_float()):
				continue

		if c is CenteredLabel:
			continue

		result["right"][c.name] = c.get_value()

	return result
