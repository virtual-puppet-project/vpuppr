extends BasicModel

var eco_mode: bool = false

var stored_offsets: ModelDisplayScreen.StoredOffsets

var vrm_meta: Resource

var vrm_mappings: VRMMappings
var expression_data: Dictionary # [ExpressionData]
var left_eye_id: int
var right_eye_id: int

var neck_bone_id: int
var spine_bone_id: int

var mapped_meshes: Dictionary

var facial_expressions
var mouth_shapes
var blinking
var eye_movement

# Blinking
var blink_threshold: float = 0.3
var eco_mode_is_blinking: bool = false

# Gaze
var gaze_strength: float = 0.5

# Mouth
var min_mouth_value: float = 0.0

class ExpressionData:
	var mesh: MeshInstance
	var morph: String
	var values: Array

var a := ExpressionData.new()
var angry := ExpressionData.new()
var blink := ExpressionData.new()
var blink_l := ExpressionData.new()
var blink_r := ExpressionData.new()
var e := ExpressionData.new()
var fun := ExpressionData.new()
var i := ExpressionData.new()
var joy := ExpressionData.new()
var lookdown := ExpressionData.new()
var lookleft := ExpressionData.new()
var lookright := ExpressionData.new()
var lookup := ExpressionData.new()
var o := ExpressionData.new()
var sorrow := ExpressionData.new()
var u := ExpressionData.new()

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
	var anim_player: AnimationPlayer = find_node("anim")

	expression_data = {}
	for animation_name in anim_player.get_animation_list():
		expression_data[animation_name] = []
		var animation: Animation = anim_player.get_animation(animation_name)
		for track_index in animation.get_track_count():
			var track_name: String = animation.track_get_path(track_index)
			var split_name: PoolStringArray = track_name.split(":")

			if split_name.size() != 2:
				AppManager.log_message("Model has ultra nested meshes: %s" % track_name)
				continue
			
			var mesh = get_node_or_null((split_name[0]))
			if not mesh:
				AppManager.log_message("Unable to find mesh: %s" % split_name[0])
				continue
			
			var ed = ExpressionData.new()
			ed.mesh = mesh
			ed.morph = split_name[1]
			
			for key_index in animation.track_get_key_count(track_index):
				ed.values.append(animation.track_get_key_value(track_index, key_index))

			expression_data[animation_name].append(ed)

	anim_player.queue_free()

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

func custom_update(data: OpenSeeGD.OpenSeeData, interpolation_data: InterpolationData) -> void:
	# NOTE: Eye mappings are intentionally reversed so that the model mirrors the data
	if not eco_mode:
		# Left eye blinking
		var blink_right = expression_data["BLINK_R"][0]
		if data.left_eye_open >= blink_threshold:
			_modify_blend_shape(blink_right.mesh, blink_right.morph, blink_right.values[1] - data.left_eye_open)
		else:
			_modify_blend_shape(blink_right.mesh, blink_right.morph, blink_right.values[1])

		# Right eye blinking
		var blink_left = expression_data["BLINK_L"][0]
		if data.right_eye_open >= blink_threshold:
			_modify_blend_shape(blink_left.mesh, blink_left.morph, blink_left.values[1] - data.right_eye_open)
		else:
			_modify_blend_shape(blink_left.mesh, blink_left.morph, blink_left.values[1])

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
#		var average_eye_x_rotation: float = (left_eye_rotation.y + right_eye_rotation.y) / 2
#		var average_eye_y_rotation: float = (left_eye_rotation.x + right_eye_rotation.x) / 2
#		if Input.is_key_pressed(KEY_0):
#			AppManager.log_message(str(average_eye_x_rotation))
#		if Input.is_key_pressed(KEY_1):
#			AppManager.log_message(str(average_eye_y_rotation))
#		if average_eye_x_rotation >= average_eye_y_rotation:
#			if average_eye_x_rotation >= 0:
#				set_eye_movement("LOOKLEFT", min(average_eye_x_rotation * 2, 0.99999))
#			else:
#				set_eye_movement("LOOKRIGHT", min(abs(average_eye_x_rotation * 2), 0.99999))
#		else:
#			if average_eye_y_rotation >= 0:
#				set_eye_movement("LOOKUP", min(average_eye_y_rotation * 2, 0.99999))
#			else:
#				set_eye_movement("LOOKDOWN", min(abs(average_eye_y_rotation) * 2, 0.99999))
		
		# Mouth tracking
		# set_expression_weight("a", min(max(min_mouth_value, data.features.mouth_open * 2.0), 1.0))
		# set_mouth_shape("A", min(max(min_mouth_value, data.features.mouth_open * 2.0), 1.0))
		_modify_blend_shape(expression_data["A"][0].mesh, expression_data["A"][0].morph,
				min(max(expression_data["A"][0].values[0], data.features.mouth_open * 2.0), 1.0))
	else:
		# TODO implement eco mode, should be more efficient than standard mode
		# Eco-mode blinking
		if(data.left_eye_open < blink_threshold and data.right_eye_open < blink_threshold):
			pass
		else:
			pass
