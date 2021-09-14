class_name VRMModel
extends BasicModel

var eco_mode: bool = false

var stored_offsets: ModelDisplayScreen.StoredOffsets

var vrm_meta: Dictionary

var vrm_mappings: VRMMappings
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

class EyeClamps:
	var up: Vector3
	var down: Vector3
	var left: Vector3
	var right: Vector3

var left_eye: EyeClamps
var right_eye: EyeClamps

# Mouth
var min_mouth_value: float = 0.0

class ExpressionData:
	var morphs: Array # MorphData

class MorphData:
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
var look_h := ExpressionData.new()
var look_v := ExpressionData.new()
var o := ExpressionData.new()
var sorrow := ExpressionData.new()
var u := ExpressionData.new()

# Perfect Sync Shapes
var browInnerUp := ExpressionData.new()
var browDownLeft := ExpressionData.new()
var browDownRight := ExpressionData.new()
var browOuterUpLeft := ExpressionData.new()
var browOuterUpRight := ExpressionData.new()
var eyeLookUpLeft := ExpressionData.new()
var eyeLookUpRight := ExpressionData.new()
var eyeLookDownLeft := ExpressionData.new()
var eyeLookDownRight := ExpressionData.new()
var eyeLookInLeft := ExpressionData.new()
var eyeLookInRight := ExpressionData.new()
var eyeLookOutLeft := ExpressionData.new()
var eyeLookOutRight := ExpressionData.new()
var eyeBlinkLeft := ExpressionData.new()
var eyeBlinkRight := ExpressionData.new()
var eyeSquintRight := ExpressionData.new()
var eyeSquintLeft := ExpressionData.new()
var eyeWideLeft := ExpressionData.new()
var eyeWideRight := ExpressionData.new()
var cheekPuff := ExpressionData.new()
var cheekSquintLeft := ExpressionData.new()
var cheekSquintRight := ExpressionData.new()
var noseSneerLeft := ExpressionData.new()
var noseSneerRight := ExpressionData.new()
var jawOpen := ExpressionData.new()
var jawForward := ExpressionData.new()
var jawLeft := ExpressionData.new()
var jawRight := ExpressionData.new()
var mouthFunnel := ExpressionData.new()
var mouthPucker := ExpressionData.new()
var mouthLeft := ExpressionData.new()
var mouthRight := ExpressionData.new()
var mouthRollUpper := ExpressionData.new()
var mouthRollLower := ExpressionData.new()
var mouthShrugUpper := ExpressionData.new()
var mouthShrugLower := ExpressionData.new()
var mouthClose := ExpressionData.new()
var mouthSmileLeft := ExpressionData.new()
var mouthSmileRight := ExpressionData.new()
var mouthFrownLeft := ExpressionData.new()
var mouthFrownRight := ExpressionData.new()
var mouthDimpleLeft := ExpressionData.new()
var mouthDimpleRight := ExpressionData.new()
var mouthUpperUpLeft := ExpressionData.new()
var mouthUpperUpRight := ExpressionData.new()
var mouthLowerDownLeft := ExpressionData.new()
var mouthLowerDownRight := ExpressionData.new()
var mouthPressLeft := ExpressionData.new()
var mouthPressRight := ExpressionData.new()
var mouthStretchLeft := ExpressionData.new()
var mouthStretchRight := ExpressionData.new()
var tongueOut := ExpressionData.new()

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

	var expression_data: Dictionary = {}
	for animation_name in anim_player.get_animation_list():
		expression_data[animation_name] = ExpressionData.new()
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
			
			var md = MorphData.new()
			md.mesh = mesh
			md.morph = split_name[1]
			
			for key_index in animation.track_get_key_count(track_index):
				md.values.append(animation.track_get_key_value(track_index, key_index))

			expression_data[animation_name].morphs.append(md)

	a = expression_data["A"]
	angry = expression_data["ANGRY"]
	blink = expression_data["BLINK"]
	blink_l = expression_data["BLINK_L"]
	blink_r = expression_data["BLINK_R"]
	e = expression_data["E"]
	fun = expression_data["FUN"]
	i = expression_data["I"]
	joy = expression_data["JOY"]
	o = expression_data["O"]
	sorrow = expression_data["SORROW"]
	u = expression_data["U"]

	look_h = ExpressionData.new()
	
	left_eye = EyeClamps.new()
	right_eye = EyeClamps.new()

	for look_up_value in expression_data["LOOKUP"].morphs:
		if look_up_value:
			var val = look_up_value.values.pop_back()
			if val:
				var rot: Quat = val["rotation"]
				match look_up_value.morph:
					"eye_L":
						left_eye.up = rot.get_euler()
					"eye_R":
						right_eye.up = rot.get_euler()

	for look_down_value in expression_data["LOOKDOWN"].morphs:
		if look_down_value:
			var val = look_down_value.values.pop_back()
			if val:
				var rot: Quat = val["rotation"]
				match look_down_value.morph:
					"eye_L":
						left_eye.down = rot.get_euler()
					"eye_R":
						right_eye.down = rot.get_euler()
	
	for look_left_value in expression_data["LOOKLEFT"].morphs:
		if look_left_value:
			var val = look_left_value.values.pop_back()
			if val:
				var rot: Quat = val["rotation"]
				match look_left_value.morph:
					"eye_L":
						left_eye.left = rot.get_euler()
					"eye_R":
						right_eye.left = rot.get_euler()

	for look_right_value in expression_data["LOOKRIGHT"].morphs:
		if look_right_value:
			var val = look_right_value.values.pop_back()
			if val:
				var rot: Quat = val["rotation"]
				match look_right_value.morph:
					"eye_L":
						left_eye.right = rot.get_euler()
					"eye_R":
						right_eye.right = rot.get_euler()

	anim_player.queue_free()

	# Map bones
	if vrm_meta.humanoid_bone_mapping.has("head"):
		head_bone = vrm_meta.humanoid_bone_mapping["head"]
		head_bone_id = skeleton.find_bone(head_bone)

		AppManager.sb.broadcast_head_bone(head_bone)

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

func custom_update(data, interpolation_data) -> void:
	# NOTE: Eye mappings are intentionally reversed so that the model mirrors the data
	if not eco_mode:
		# Left eye blinking
		if data.left_eye_open >= blink_threshold:
			_modify_blend_shape(blink_r.morphs[0].mesh, blink_r.morphs[0].morph, blink_r.morphs[0].values[1] - data.left_eye_open)
		else:
			_modify_blend_shape(blink_r.morphs[0].mesh, blink_r.morphs[0].morph, blink_r.morphs[0].values[1])

		# Right eye blinking
		if data.right_eye_open >= blink_threshold:
			_modify_blend_shape(blink_l.morphs[0].mesh, blink_l.morphs[0].morph, blink_l.morphs[0].values[1] - data.right_eye_open)
		else:
			_modify_blend_shape(blink_l.morphs[0].mesh, blink_l.morphs[0].morph, blink_l.morphs[0].values[1])

		# TODO eyes show weird behaviour when blinking
		# TODO make sure angle between eyes' x values are at least parallel
		# Make sure eyes are aligned on the y-axis
		var left_eye_rotation: Vector3 = interpolation_data.interpolate(InterpolationData.InterpolationDataType.LEFT_EYE_ROTATION, gaze_strength)
		var right_eye_rotation: Vector3 = interpolation_data.interpolate(InterpolationData.InterpolationDataType.RIGHT_EYE_ROTATION, gaze_strength)
		var average_eye_y_rotation: float = (left_eye_rotation.x + right_eye_rotation.x) / 2
		left_eye_rotation.x = average_eye_y_rotation
		right_eye_rotation.x = average_eye_y_rotation
		
#		var average_eye_x_rotation: float = (left_eye_rotation.y + right_eye_rotation.y) / 2
#		left_eye_rotation.y = average_eye_x_rotation
#		right_eye_rotation.y = average_eye_x_rotation

		# Left eye gaze
		left_eye_rotation.x = clamp(left_eye_rotation.x, left_eye.down.x, left_eye.up.x)
		left_eye_rotation.y = clamp(left_eye_rotation.y, left_eye.right.y, left_eye.left.y)

		# Right eye gaze
		right_eye_rotation.x = clamp(right_eye_rotation.x, right_eye.down.x, right_eye.up.x)
		right_eye_rotation.y = clamp(right_eye_rotation.y, right_eye.right.y, right_eye.left.y)
		
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
		
		# TODO Debug only
		if Input.is_key_pressed(KEY_0):
			print(left_eye_rotation)
		
		if Input.is_key_pressed(KEY_1):
			print(str(self.eye_tracking_damp))
		
		# Mouth tracking
		_modify_blend_shape(a.morphs[0].mesh, a.morphs[0].morph,
				min(max(a.morphs[0].values[0], data.features.mouth_open * 2.0),
				a.morphs[0].values[1]))
	else:
		# TODO implement eco mode, should be more efficient than standard mode
		# Eco-mode blinking
		if(data.left_eye_open < blink_threshold and data.right_eye_open < blink_threshold):
			pass
		else:
			pass
