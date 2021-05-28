class_name PoseView
extends BaseView

# Left
var should_modify_bone: bool = false
var bone_to_modify: String

# Right
var model_parent: Spatial
var move_model_element: ToggleLabel
var spin_model_element: ToggleLabel
var zoom_model_element: ToggleLabel
var should_move_model: bool = false
var should_spin_model: bool = false
var should_zoom_model: bool = false

# Shared
var is_left_clicking: bool = false

var mouse_move_strength: float = 0.002
var scroll_strength: float = 0.05

###############################################################################
# Builtin functions                                                           #
###############################################################################

func _ready() -> void:
	_setup()

func _unhandled_input(event: InputEvent) -> void:
	if event.is_action_pressed("left_click"):
		is_left_clicking = true
	elif event.is_action_released("left_click"):
		is_left_clicking = false

	if should_modify_bone:
		if (is_left_clicking and event is InputEventMouseMotion):
			var transform: Transform = current_model.skeleton.get_bone_pose(
					current_model.skeleton.find_bone(bone_to_modify))
			transform = transform.rotated(Vector3.UP, event.relative.x * mouse_move_strength)
			transform = transform.rotated(Vector3.RIGHT, event.relative.y * mouse_move_strength)

			current_model.skeleton.set_bone_pose(
					current_model.skeleton.find_bone(bone_to_modify), transform)

		if event.is_action("scroll_up"):
			var transform: Transform = current_model.skeleton.get_bone_pose(
					current_model.skeleton.find_bone(bone_to_modify))
			transform = transform.rotated(Vector3.FORWARD, scroll_strength)

			current_model.skeleton.set_bone_pose(
					current_model.skeleton.find_bone(bone_to_modify), transform)
		elif event.is_action("scroll_down"):
			var transform: Transform = current_model.skeleton.get_bone_pose(
					current_model.skeleton.find_bone(bone_to_modify))
			transform = transform.rotated(Vector3.FORWARD, -scroll_strength)

			current_model.skeleton.set_bone_pose(
					current_model.skeleton.find_bone(bone_to_modify), transform)
	
	if is_left_clicking:
		if event is InputEventMouseMotion:
			if should_move_model:
				model_parent.translate(Vector3(event.relative.x, -event.relative.y, 0.0) * mouse_move_strength)
			if should_spin_model:
				current_model.rotate_x(event.relative.y * mouse_move_strength)
				current_model.rotate_y(event.relative.x * mouse_move_strength)
	if should_zoom_model:
		if event.is_action("scroll_up"):
			model_parent.translate(Vector3(0.0, 0.0, scroll_strength))
		elif event.is_action("scroll_down"):
			model_parent.translate(Vector3(0.0, 0.0, -scroll_strength))

###############################################################################
# Connections                                                                 #
###############################################################################

func _on_apply_button_pressed() -> void:
	_apply_properties_left()
	_apply_properties_right()

func _on_reset_button_pressed() -> void:
	_generate_properties_left()
	_generate_properties_right()

func _on_reset_model_transform_button_pressed() -> void:
	model_parent.transform = main_screen.model_display_screen.model_parent_initial_transform
	current_model.transform = main_screen.model_display_screen.model_initial_transform

func _on_reset_model_pose_button_pressed() -> void:
	for i in current_model.initial_bone_poses.keys():
		current_model.skeleton.set_bone_pose(i, current_model.initial_bone_poses[i])

###############################################################################
# Private functions                                                           #
###############################################################################

###
# Left
###

func _setup_left(config: Dictionary) -> void:
	if not config.empty():
		for key in config["left"].keys():
			current_model.skeleton.set_bone_pose(
				current_model.skeleton.find_bone(key),
				JSONUtil.dictionary_to_transform(config["left"][key])
			)
		
		_generate_properties_left()
		_apply_properties_left()
	else:
		_generate_properties_left()

func _generate_properties_left() -> void:
	left_container.clear_children()

	left_container.add_to_inner(_create_element(ElementType.LABEL, "pose_controls",
			"Pose Controls"))
	
	var bone_values: Dictionary = current_model.get_mapped_bones()
	for bone_name in bone_values.keys():
		left_container.add_to_inner(_create_element(ElementType.TOGGLE, bone_name,
				bone_name, false, true))

func _apply_properties_left() -> void:
	var toggle_dirty: bool = false
	for c in left_container.get_inner_children():
		if c is CenteredLabel:
			continue
		if c.get_value():
			toggle_dirty = true
			bone_to_modify = c.name
	
	if toggle_dirty:
		should_modify_bone = true
	else:
		should_modify_bone = false

###
# Right
###

func _setup_right(config: Dictionary) -> void:
	model_parent = main_screen.model_display_screen.model_parent

	if not config.empty():
		for key in config["right"].keys():
			match key:
				"model":
					current_model.transform = JSONUtil.dictionary_to_transform(config["right"][key])
				"model_parent":
					model_parent.transform = JSONUtil.dictionary_to_transform(config["right"][key])
				_:
					AppManager.log_message("Bad key found in %s: %s" % [self.name, key], true)
		_generate_properties_right()
		_apply_properties_right()
	else:
		_generate_properties_right()

func _generate_properties_right() -> void:
	right_container.clear_children()

	right_container.add_to_inner(_create_element(ElementType.LABEL, "model_controls",
			"Model Controls"))
	move_model_element = _create_element(ElementType.TOGGLE, "move_model",
			"Move Model", false, true)
	right_container.add_to_inner(move_model_element)
	spin_model_element = _create_element(ElementType.TOGGLE, "spin_model",
			"Spin Model", false, true)
	right_container.add_to_inner(spin_model_element)
	zoom_model_element = _create_element(ElementType.TOGGLE, "zoom_model",
			"Zoom Model", false, false)
	right_container.add_to_inner(zoom_model_element)

	var reset_model_transform_button: Button = Button.new()
	reset_model_transform_button.text = "Reset model transform"
	reset_model_transform_button.connect("pressed", self, "_on_reset_model_transform_button_pressed")
	right_container.add_to_inner(reset_model_transform_button)

	var reset_model_pose_button: Button = Button.new()
	reset_model_pose_button.text = "Reset model pose"
	reset_model_pose_button.connect("pressed", self, "_on_reset_model_pose_button_pressed")
	right_container.add_to_inner(reset_model_pose_button)

	# IK input
	right_container.add_to_inner(_create_element(ElementType.LABEL, "ik_options",
			"IK Options"))
	right_container.add_to_inner(_create_element(ElementType.INPUT, "left_arm_root",
			"Left Arm Root", "", TYPE_STRING))
	right_container.add_to_inner(_create_element(ElementType.INPUT, "left_arm_tip",
			"Left Arm Tip", "", TYPE_STRING))
	right_container.add_to_inner(_create_element(ElementType.INPUT, "right_arm_root",
			"Right Arm Root", "", TYPE_STRING))
	right_container.add_to_inner(_create_element(ElementType.INPUT, "right_arm_tip",
			"Right Arm Tip", "", TYPE_STRING))

func _apply_properties_right() -> void:
	var should_left_ik_start: int = 0
	var should_right_ik_start: int = 0
	for c in right_container.get_inner_children():
		if c is InputLabel:
			if c.line_edit.text.empty():
				continue
			elif (c.line_edit_type == TYPE_REAL and not c.line_edit.text.is_valid_float()):
				continue
		
		match c.name:
			"move_model":
				should_move_model = c.get_value()
			"spin_model":
				should_spin_model = c.get_value()
			"zoom":
				should_zoom_model = c.get_value()
			"left_arm_root":
				main_screen.model_display_screen.left_skeleton_ik.root_bone = c.get_value()
				should_left_ik_start += 1
			"left_arm_tip":
				main_screen.model_display_screen.left_skeleton_ik.tip_bone = c.get_value()
				should_left_ik_start += 1
			"right_arm_root":
				main_screen.model_display_screen.right_skeleton_ik.root_bone = c.get_value()
				should_right_ik_start += 1
			"right_arm_tip":
				main_screen.model_display_screen.right_skeleton_ik.tip_bone = c.get_value()
				should_right_ik_start += 1

	# TODO this isn't great
	# Apply IK
	if should_left_ik_start == 2:
		main_screen.model_display_screen.left_skeleton_ik.target_node = main_screen.model_display_screen.left_ik_cube.get_path()
		main_screen.model_display_screen.left_skeleton_ik.start(true)
		
		var left_bone_transform: Transform = main_screen.model_display_screen.model_skeleton.get_bone_global_pose(main_screen.model_display_screen.model_skeleton.find_bone(main_screen.model_display_screen.left_skeleton_ik.root_bone))
		main_screen.model_display_screen.model_skeleton.clear_bones_global_pose_override()
		var left_transform: Transform = Transform()
		left_transform = left_transform.rotated(Vector3.RIGHT, left_bone_transform.basis.get_euler().normalized().x)
		left_transform = left_transform.rotated(Vector3.UP, left_bone_transform.basis.get_euler().normalized().y)
		left_transform = left_transform.rotated(Vector3.BACK, left_bone_transform.basis.get_euler().normalized().z)
		main_screen.model_display_screen.model_skeleton.set_bone_pose(main_screen.model_display_screen.model_skeleton.find_bone(main_screen.model_display_screen.left_skeleton_ik.root_bone), left_transform)
	if should_right_ik_start == 2:
		main_screen.model_display_screen.right_skeleton_ik.target_node = main_screen.model_display_screen.right_ik_cube.get_path()
		main_screen.model_display_screen.right_skeleton_ik.start(true)

		var right_bone_transform: Transform = main_screen.model_display_screen.model_skeleton.get_bone_global_pose(main_screen.model_display_screen.model_skeleton.find_bone(main_screen.model_display_screen.right_skeleton_ik.root_bone))
		main_screen.model_display_screen.model_skeleton.clear_bones_global_pose_override()
		var right_transform: Transform = Transform()
		right_transform = right_transform.rotated(Vector3.RIGHT, right_bone_transform.basis.get_euler().normalized().x)
		right_transform = right_transform.rotated(Vector3.UP, right_bone_transform.basis.get_euler().normalized().y)
		right_transform = right_transform.rotated(Vector3.BACK, right_bone_transform.basis.get_euler().normalized().z)
		main_screen.model_display_screen.model_skeleton.set_bone_pose(main_screen.model_display_screen.model_skeleton.find_bone(main_screen.model_display_screen.right_skeleton_ik.root_bone), right_transform)

###############################################################################
# Public functions                                                            #
###############################################################################

func save() -> Dictionary:
	var result: Dictionary = {}

	# Left
	result["left"] = {}
	for i in current_model.skeleton.get_bone_count():
		result["left"][current_model.skeleton.get_bone_name(i)] = JSONUtil.transform_to_dictionary(
			current_model.skeleton.get_bone_pose(i)
		)

	# Right
	result["right"] = {}
	result["right"]["model"] = JSONUtil.transform_to_dictionary(current_model.transform)
	result["right"]["model_parent"] = JSONUtil.transform_to_dictionary(
			main_screen.model_display_screen.model_parent.transform)

	return result
