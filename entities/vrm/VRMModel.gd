extends BasicModel

var eco_mode: bool = false

var stored_offsets: ModelDisplayScreen.StoredOffsets

var vrm_mappings: VRMMappings
var left_eye_id: int
var right_eye_id: int

var neck_bone_id: int
var spine_bone_id: int

var mapped_meshes: Dictionary

# Blinking
var blink_threshold: float = 0.3
var eco_mode_is_blinking: bool = false

# Gaze
var gaze_strength: float = 0.5

# Mouth
var min_mouth_value: float = 0.0

###############################################################################
# Builtin functions                                                           #
###############################################################################

func _ready() -> void:
	translation_damp = 0.1
	rotation_damp = 0.01
	additional_bone_damp = 0.6

	# TODO this is gross
	stored_offsets = get_parent().get_parent().stored_offsets

	# Read vrm mappings
	has_custom_update = true
	if vrm_mappings.head != head_bone:
		head_bone = vrm_mappings.head
		head_bone_id = skeleton.find_bone(head_bone)

	left_eye_id = skeleton.find_bone(vrm_mappings.left_eye)
	right_eye_id = skeleton.find_bone(vrm_mappings.right_eye)
	for mesh_name in vrm_mappings.meshes_used:
		mapped_meshes[mesh_name] = find_node(mesh_name) as MeshInstance

	if vrm_mappings.neck:
		neck_bone_id = skeleton.find_bone(vrm_mappings.neck)
	if vrm_mappings.spine:
		spine_bone_id = skeleton.find_bone(vrm_mappings.spine)

	# Automatically A pose
	if vrm_mappings.left_shoulder:
		skeleton.set_bone_pose(skeleton.find_bone(vrm_mappings.left_shoulder),
				Transform(Quat(0, 0, 0.1, 0.85)))
	if vrm_mappings.right_shoulder:
		skeleton.set_bone_pose(skeleton.find_bone(vrm_mappings.right_shoulder),
				Transform(Quat(0, 0, -0.1, 0.85)))

	if vrm_mappings.left_upper_arm:
		skeleton.set_bone_pose(skeleton.find_bone(vrm_mappings.left_upper_arm),
				Transform(Quat(0, 0, 0.4, 0.85)))
	if vrm_mappings.right_upper_arm:
		skeleton.set_bone_pose(skeleton.find_bone(vrm_mappings.right_upper_arm),
				Transform(Quat(0, 0, -0.4, 0.85)))

	if not neck_bone_id:
		AppManager.log_message("Neck bone not found. Is this a .vrm model?")
	if not spine_bone_id:
		AppManager.log_message("Spine bone not found. Is this a .vrm model?")
	
	additional_bones_to_pose_names.append(vrm_mappings.neck)
	additional_bones_to_pose_names.append(vrm_mappings.spine)

	scan_mapped_bones()

###############################################################################
# Connections                                                                 #
###############################################################################

###############################################################################
# Private functions                                                           #
###############################################################################

static func _to_godot_quat(v: Quat) -> Quat:
	return Quat(v.x, -v.y, v.z, v.w)

###############################################################################
# Public functions                                                            #
###############################################################################

func scan_mapped_bones() -> void:
	.scan_mapped_bones()
	for bone_name in additional_bones_to_pose_names:
		if bone_name.to_lower() == "root":
			additional_bones_to_pose_names.erase(bone_name)

func set_expression_weight(expression_name: String, expression_weight: float) -> void:
	for mesh_name in vrm_mappings[expression_name].get_meshes():
		for blend_name in vrm_mappings[expression_name].expression_data[mesh_name]:
			_modify_blend_shape(mapped_meshes[mesh_name], blend_name, expression_weight)

func get_expression_weight(expression_name: String) -> float:
	var mesh_name: String = vrm_mappings[expression_name].get_meshes()[0]
	var blend_name: String = vrm_mappings[expression_name].expression_data[mesh_name]
	
	return mapped_meshes[mesh_name].get("blend_shapes/%s" % blend_name)

func custom_update(data: OpenSeeGD.OpenSeeData, interpolation_data: InterpolationData) -> void:
	# NOTE: Eye mappings are intentionally reversed so that the model mirrors the data
	if not eco_mode:
		# Left eye blinking
		if data.left_eye_open >= blink_threshold:
			set_expression_weight("blink_r", 1.0 - data.left_eye_open)
		else:
			set_expression_weight("blink_r", 1.0)

		# Right eye blinking
		if data.right_eye_open >= blink_threshold:
			set_expression_weight("blink_l", 1.0 - data.left_eye_open)
		else:
			set_expression_weight("blink_l", 1.0)

		# TODO eyes show weird behaviour when blinking
		# TODO make sure angle between eyes' x values are at least parallel
		# Make sure eyes are aligned on the y-axis
		var left_eye_rotation: Vector3 = interpolation_data.interpolate(InterpolationData.InterpolationDataType.LEFT_EYE_ROTATION, gaze_strength)
		var right_eye_rotation: Vector3 = interpolation_data.interpolate(InterpolationData.InterpolationDataType.RIGHT_EYE_ROTATION, gaze_strength)
		var average_eye_y_rotation: float = (left_eye_rotation.x + right_eye_rotation.x) / 2
		left_eye_rotation.x = average_eye_y_rotation
		right_eye_rotation.x = average_eye_y_rotation

		# Left eye gaze
		var left_eye_transform: Transform = Transform()
		left_eye_transform = left_eye_transform.rotated(Vector3.RIGHT, -left_eye_rotation.x)
		left_eye_transform = left_eye_transform.rotated(Vector3.UP, left_eye_rotation.y)
		
		# Right eye gaze
		var right_eye_transform: Transform = Transform()
		right_eye_transform = right_eye_transform.rotated(Vector3.RIGHT, -right_eye_rotation.x)
		right_eye_transform = right_eye_transform.rotated(Vector3.UP, right_eye_rotation.y)
		
		skeleton.set_bone_pose(right_eye_id, left_eye_transform)
		skeleton.set_bone_pose(left_eye_id, right_eye_transform)
		
		# Mouth tracking
		set_expression_weight("a", min(max(min_mouth_value, data.features.mouth_open * 2.0), 1.0))
	else:
		# TODO implement eco mode, should be more efficient than standard mode
		# Eco-mode blinking
		if(data.left_eye_open < blink_threshold and data.right_eye_open < blink_threshold):
			pass
		else:
			pass
