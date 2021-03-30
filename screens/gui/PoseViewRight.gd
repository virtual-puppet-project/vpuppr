extends BaseSidebar

var initial_properties: Dictionary = {}

var model_parent: Spatial

var move_model_element: ToggleLabel
var spin_model_element: ToggleLabel
var zoom_model_element: ToggleLabel

var is_left_clicking: bool = false
var should_move_model: bool = false
var should_spin_model: bool = false
var should_zoom_model: bool = false

export var zoom_strength: float = 0.05
export var mouse_move_strength: float = 0.002

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
	
	if is_left_clicking:
		if event is InputEventMouseMotion:
			if should_move_model:
				model_parent.translate(Vector3(event.relative.x, -event.relative.y, 0.0) * mouse_move_strength)
			if should_spin_model:
				current_model.rotate_x(event.relative.y * mouse_move_strength)
				current_model.rotate_y(event.relative.x * mouse_move_strength)
	if should_zoom_model:
		if event.is_action("scroll_up"):
			model_parent.translate(Vector3(0.0, 0.0, zoom_strength))
		elif event.is_action("scroll_down"):
			model_parent.translate(Vector3(0.0, 0.0, -zoom_strength))

###############################################################################
# Connections                                                                 #
###############################################################################

func _on_apply_button_pressed() -> void:
	_apply_properties()

func _on_reset_button_pressed() -> void:
	_generate_properties(initial_properties)

func _on_reset_model_transform_button_pressed() -> void:
	model_parent.transform = main_screen.model_display_screen.model_parent_initial_transform
	current_model.transform = main_screen.model_display_screen.model_initial_transform

func _on_reset_model_pose_button_pressed() -> void:
	for i in current_model.initial_bone_poses.keys():
		current_model.skeleton.set_bone_pose(i, current_model.initial_bone_poses[i])

###############################################################################
# Private functions                                                           #
###############################################################################

func _generate_properties(p_initial_properties: Dictionary = Dictionary()) -> void:
	for child in v_box_container.get_children():
		child.free()

	# TODO store state and use it here
	var data_source = p_initial_properties
	
	_create_element(ElementType.LABEL, "model_controls", "Model Controls")
	_create_element(ElementType.TOGGLE, "move_model", "Move Model", false, true)
	move_model_element = v_box_container.get_node("move_model")
	_create_element(ElementType.TOGGLE, "spin_model", "Spin Model", false, true)
	spin_model_element = v_box_container.get_node("spin_model")
	_create_element(ElementType.TOGGLE, "zoom_model", "Zoom Model", false, false)
	zoom_model_element = v_box_container.get_node("zoom_model")

	var reset_model_transform_button: Button = Button.new()
	reset_model_transform_button.text = "Reset model transform"
	reset_model_transform_button.connect("pressed", self, "_on_reset_model_transform_button_pressed")
	v_box_container.add_child(reset_model_transform_button)

	var reset_model_pose_button: Button = Button.new()
	reset_model_pose_button.text = "Reset model pose"
	reset_model_pose_button.connect("pressed", self, "_on_reset_model_pose_button_pressed")
	v_box_container.add_child(reset_model_pose_button)

	# Courtesy null check
	if current_model:
		if p_initial_properties.empty():
			data_source = current_model

		# IK input
		_create_element(ElementType.LABEL, "ik_options", "IK Options")
		_create_element(ElementType.INPUT, "left_arm_root", "Left Arm Root", "",
				TYPE_STRING)
		_create_element(ElementType.INPUT, "left_arm_tip", "Left Arm Tip", "",
				TYPE_STRING)
		_create_element(ElementType.INPUT, "right_arm_root", "Right Arm Root", "",
				TYPE_STRING)
		_create_element(ElementType.INPUT, "right_arm_tip", "Right Arm Tip", "",
				TYPE_STRING)

func _apply_properties() -> void:
	var should_left_ik_start: int = 0
	var should_right_ik_start: int = 0
	for c in v_box_container.get_children():
		# Null checks and value checks
		if c.get("line_edit"):
			if c.line_edit.text.empty():
				continue
			if c.line_edit_type == TYPE_REAL:
				if not c.line_edit.text.is_valid_float():
					continue
		match c.name:
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
			"move_model":
				should_move_model = c.get_value()
			"spin_model":
				should_spin_model = c.get_value()
			"zoom_model":
				should_zoom_model = c.get_value()

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

func _setup() -> void:
	model_parent = main_screen.model_display_screen.model_parent
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


