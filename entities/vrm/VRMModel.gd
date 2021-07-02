extends BasicModel

var eco_mode: bool = false

var stored_offsets: ModelDisplayScreen.StoredOffsets

var vrm_meta: Resource

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
	has_custom_update = true
	translation_damp = 0.1
	rotation_damp = 0.01
	additional_bone_damp = 0.6

	# TODO this is gross
	stored_offsets = get_parent().get_parent().stored_offsets

	# Map expressions
	vrm_mappings = VRMMappings.new()
	var anim_player: AnimationPlayer = find_node("anim")
	for a in anim_player.get_animation_list():
		
		pass

	for mesh_name in vrm_mappings.meshes_used:
		mapped_meshes[mesh_name] = find_node(mesh_name) as MeshInstance

	# Map bones
	if vrm_meta.humanoid_bone_mapping.has("head"):
		head_bone = vrm_meta.humanoid_bone_mapping["head"]
		head_bone_id = skeleton.find_bone(head_bone)

	if vrm_meta.humanoid_bone_mapping.has("leftEye"):
		left_eye_id = skeleton.find_bone(vrm_meta.humanoid_bone_mapping["leftEye"])
	if vrm_meta.humanoid_bone_mapping.has("rightEye"):
		right_eye_id = skeleton.find_bone(vrm_meta.humanoid_bone_mapping["rightEye"])

	if vrm_meta.humanoid_bone_mapping.has("neck"):
		neck_bone_id = skeleton.find_bone(vrm_meta.humanoid_bone_mapping["neck"])
		additional_bones_to_pose_names.append(vrm_meta.humanoid_bone_mapping["neck"])

	if vrm_meta.humanoid_bone_mapping.has("spine"):
		spine_bone_id = skeleton.find_bone(vrm_meta.humanoid_bone_mapping["spine"])
		additional_bones_to_pose_names.append(vrm_meta.humanoid_bone_mapping["spine"])

	if vrm_meta.humanoid_bone_mapping.has("leftShoulder"):
		skeleton.set_bone_pose(skeleton.find_bone(vrm_meta.humanoid_bone_mapping["leftShoulder"]),
				Transform(Quat(0, 0, 0.1, 0.85)))
	if vrm_meta.humanoid_bone_mapping.has("rightShoulder"):
		skeleton.set_bone_pose(skeleton.find_bone(vrm_meta.humanoid_bone_mapping["rightShoulder"]),
				Transform(Quat(0, 0, -0.1, 0.85)))

	if vrm_meta.humanoid_bone_mapping.has("leftUpperArm"):
		skeleton.set_bone_pose(skeleton.find_bone(vrm_meta.humanoid_bone_mapping["leftUpperArm"]),
				Transform(Quat(0, 0, 0.4, 0.85)))
	if vrm_meta.humanoid_bone_mapping.has("rightUpperArm"):
		skeleton.set_bone_pose(skeleton.find_bone(vrm_meta.humanoid_bone_mapping["rightUpperArm"]),
				Transform(Quat(0, 0, -0.4, 0.85)))

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
