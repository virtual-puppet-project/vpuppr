extends BaseSidebar

var initial_properties: Dictionary = {}

var is_left_clicking: bool = false

var should_modify_bone: bool = false
var bone_to_modify: String

export var mouse_move_strength: float = 0.002
export var scroll_strength: float = 0.05

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
			var transform: Transform = main_screen.model_display_screen.model_skeleton.get_bone_pose(main_screen.model_display_screen.model_skeleton.find_bone(bone_to_modify))
			transform = transform.rotated(Vector3.UP, event.relative.x * mouse_move_strength)
			transform = transform.rotated(Vector3.RIGHT, event.relative.y * mouse_move_strength)

			main_screen.model_display_screen.model_skeleton.set_bone_pose(main_screen.model_display_screen.model_skeleton.find_bone(bone_to_modify), transform)

		if event.is_action("scroll_up"):
			var transform: Transform = main_screen.model_display_screen.model_skeleton.get_bone_pose(main_screen.model_display_screen.model_skeleton.find_bone(bone_to_modify))
			transform = transform.rotated(Vector3.FORWARD, scroll_strength)

			main_screen.model_display_screen.model_skeleton.set_bone_pose(main_screen.model_display_screen.model_skeleton.find_bone(bone_to_modify), transform)
		elif event.is_action("scroll_down"):
			var transform: Transform = main_screen.model_display_screen.model_skeleton.get_bone_pose(main_screen.model_display_screen.model_skeleton.find_bone(bone_to_modify))
			transform = transform.rotated(Vector3.FORWARD, -scroll_strength)

			main_screen.model_display_screen.model_skeleton.set_bone_pose(main_screen.model_display_screen.model_skeleton.find_bone(bone_to_modify), transform)

###############################################################################
# Connections                                                                 #
###############################################################################

func _on_apply_button_pressed() -> void:
	_apply_properties()

func _on_reset_button_pressed() -> void:
	_generate_properties(initial_properties)

###############################################################################
# Private functions                                                           #
###############################################################################

func _generate_properties(p_initial_properties: Dictionary = Dictionary()) -> void:
	for child in v_box_container.get_children():
		child.free()

	var bone_values = current_model.get_mapped_bones()
	for bone_name in bone_values.keys():
		_create_element(ElementType.TOGGLE, bone_name, bone_name, false, true)

func _apply_properties() -> void:
	var toggle_dirty: bool = false
	for c in v_box_container.get_children():
		# TODO add type check just in case we add other element types
		if (c as ToggleLabel).get_value():
			toggle_dirty = true
			bone_to_modify = c.name
	
	if toggle_dirty:
		should_modify_bone = true
	else:
		should_modify_bone = false

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


