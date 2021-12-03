class_name VRMModel
extends BasicModel

var eco_mode: bool = false

var vrm_meta: Dictionary

var left_eye_id: int
var right_eye_id: int

var neck_bone_id: int
var spine_bone_id: int

# Blinking
var blink_threshold: float
var eco_mode_is_blinking: bool = false

class EyeClamps:
	var up: Vector3
	var down: Vector3
	var left: Vector3
	var right: Vector3

var left_eye: EyeClamps
var right_eye: EyeClamps

var use_raw_eye_rotation: bool = false

# Mouth
var min_mouth_value: float = 0.0

class ExpressionData:
	var morphs: Array # MorphData

class MorphData:
	var mesh: MeshInstance
	var morph: String
	var values: Array

var a: ExpressionData
var angry: ExpressionData
var blink: ExpressionData
var blink_l: ExpressionData
var blink_r: ExpressionData
var e: ExpressionData
var fun: ExpressionData
var i: ExpressionData
var joy: ExpressionData
# var lookdown := ExpressionData.new()
# var lookleft := ExpressionData.new()
# var lookright := ExpressionData.new()
# var lookup := ExpressionData.new()
var o: ExpressionData
var sorrow: ExpressionData
var u: ExpressionData

# TODO stopgap
var last_expression: ExpressionData

var all_expressions: Dictionary = {} # String: ExpressionData

###############################################################################
# Builtin functions                                                           #
###############################################################################

func _ready() -> void:
	has_custom_update = true
	# TODO this doesn't seem right, commented out for now
	# translation_damp = 0.1
	# rotation_damp = 0.01
	# additional_bone_damp = 0.6

	blink_threshold = AppManager.cm.current_model_config.blink_threshold
	AppManager.sb.connect("blink_threshold", self, "_on_blink_threshold")

	use_raw_eye_rotation = AppManager.cm.current_model_config.use_raw_eye_rotation
	AppManager.sb.connect("use_raw_eye_rotation", self, "_on_use_raw_eye_rotation")

	# TODO stopgap
	AppManager.sb.connect("blend_shapes", self, "_on_blend_shapes")

	# Map expressions
	var anim_player: AnimationPlayer = find_node("anim")

	for animation_name in anim_player.get_animation_list():
		var ed := ExpressionData.new()
		var animation: Animation = anim_player.get_animation(animation_name)
		for track_index in animation.get_track_count():
			var track_name: String = animation.track_get_path(track_index)
			var split_name: PoolStringArray = track_name.split(":")

			if split_name.size() != 2:
				AppManager.logger.info("Model has ultra nested meshes: %s" % track_name)
				continue
			
			var mesh = get_node_or_null((split_name[0]))
			if not mesh:
				AppManager.logger.info("Unable to find mesh: %s" % split_name[0])
				continue
			
			var md = MorphData.new()
			md.mesh = mesh
			md.morph = split_name[1]
			
			for key_index in animation.track_get_key_count(track_index):
				md.values.append(animation.track_get_key_value(track_index, key_index))

			ed.morphs.append(md)

		all_expressions[animation_name.to_lower()] = ed

	anim_player.queue_free()

	for key in all_expressions.keys():
		set(key, all_expressions[key])
	
	_map_eye_expressions(all_expressions)

	_map_bones()

	scan_mapped_bones()

###############################################################################
# Connections                                                                 #
###############################################################################

func _on_blink_threshold(value: float) -> void:
	blink_threshold = value

func _on_use_raw_eye_rotation(value: bool) -> void:
	use_raw_eye_rotation = value

# TODO go back to this after refactoring expression mapping
func _on_blend_shapes(value: String) -> void:
	var ed = get(value)
	if ed == null:
		ed = all_expressions.get(value)
		if ed == null:
			return

	# Undo the last expression
	if last_expression:
		for idx in last_expression.morphs.size():
			_modify_blend_shape(last_expression.morphs[idx].mesh, last_expression.morphs[idx].morph,
					last_expression.morphs[idx].values[0])

	if ed == last_expression:
		last_expression = null
		return

	for idx in ed.morphs.size():
		_modify_blend_shape(ed.morphs[idx].mesh, ed.morphs[idx].morph,
				ed.morphs[idx].values[1])

	last_expression = ed

###############################################################################
# Private functions                                                           #
###############################################################################

static func _to_godot_quat(v: Quat) -> Quat:
	return Quat(v.x, -v.y, v.z, v.w)

func _map_eye_expressions(data: Dictionary):
	left_eye = EyeClamps.new()
	right_eye = EyeClamps.new()

	var leftEyeMorph = "eye_L"
	if vrm_meta.humanoid_bone_mapping.has("leftEye"):
		leftEyeMorph = vrm_meta.humanoid_bone_mapping["leftEye"]
	
	var rightEyeMorph = "eye_R"
	if vrm_meta.humanoid_bone_mapping.has("rightEye"):
		rightEyeMorph = vrm_meta.humanoid_bone_mapping["rightEye"]

	for look_up_value in data["lookup"].morphs:
		if look_up_value:
			var val = look_up_value.values.pop_back()
			if val:
				var rot: Quat = val["rotation"]
				match look_up_value.morph:
					leftEyeMorph:
						var x = rot.get_euler()
						left_eye.up = x
					rightEyeMorph:
						right_eye.up = rot.get_euler()

	for look_down_value in data["lookdown"].morphs:
		if look_down_value:
			var val = look_down_value.values.pop_back()
			if val:
				var rot: Quat = val["rotation"]
				match look_down_value.morph:
					leftEyeMorph:
						left_eye.down = rot.get_euler()
					rightEyeMorph:
						right_eye.down = rot.get_euler()
	
	for look_left_value in data["lookleft"].morphs:
		if look_left_value:
			var val = look_left_value.values.pop_back()
			if val:
				var rot: Quat = val["rotation"]
				match look_left_value.morph:
					leftEyeMorph:
						left_eye.left = rot.get_euler()
					rightEyeMorph:
						right_eye.left = rot.get_euler()

	for look_right_value in data["lookright"].morphs:
		if look_right_value:
			var val = look_right_value.values.pop_back()
			if val:
				var rot: Quat = val["rotation"]
				match look_right_value.morph:
					leftEyeMorph:
						left_eye.right = rot.get_euler()
					rightEyeMorph:
						right_eye.right = rot.get_euler()

	# Some models don't have blendshapes for looking up/down/left/right
	# So let their eyes rotate 360 degrees
	if left_eye.down.x == 0:
		left_eye.down.x = -360.0
	if left_eye.up.x == 0:
		left_eye.up.x = 360.0
	if left_eye.right.y == 0:
		left_eye.right.y = -360.0
	if left_eye.left.y == 0:
		left_eye.left.y = 360.0

	if right_eye.down.x == 0:
		right_eye.down.x = -360.0
	if right_eye.up.x == 0:
		right_eye.up.x = 360.0
	if right_eye.right.y == 0:
		right_eye.right.y = -360.0
	if right_eye.left.y == 0:
		right_eye.left.y = 360.0

func _map_bones():
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

###############################################################################
# Public functions                                                            #
###############################################################################

func scan_mapped_bones() -> void:
	.scan_mapped_bones()
	for bone_name in additional_bones_to_pose_names:
		if bone_name.to_lower() == "root":
			additional_bones_to_pose_names.erase(bone_name)

func custom_update(data, interpolation_data) -> void:
	# NOTE: Eye mappings are intentionally reversed so that the model mirrors the data
	if not eco_mode:
		if (last_expression != joy and last_expression != sorrow):
			# Left eye blinking
			if data.left_eye_open >= blink_threshold:
				for i in blink_r.morphs:
					_modify_blend_shape(i.mesh, i.morph, i.values[1] - interpolation_data.interpolate(InterpolationData.InterpolationDataType.LEFT_EYE_BLINK, 1.0))
			else:
				for i in blink_r.morphs:
					_modify_blend_shape(i.mesh, i.morph, i.values[1])

			# Right eye blinking
			if data.right_eye_open >= blink_threshold:
				for i in blink_l.morphs:
					_modify_blend_shape(i.mesh, i.morph, i.values[1] - interpolation_data.interpolate(InterpolationData.InterpolationDataType.RIGHT_EYE_BLINK, 1.0))
			else:
				for i in blink_l.morphs:
					_modify_blend_shape(i.mesh, i.morph, i.values[1])
		else:
			# Unblink if the facial expression doesn't allow blinking
			for i in blink_r.morphs:
				_modify_blend_shape(i.mesh, i.morph, i.values[0])
			for i in blink_l.morphs:
				_modify_blend_shape(i.mesh, i.morph, i.values[0])

		# TODO eyes show weird behaviour when blinking
		# TODO make sure angle between eyes' x values are at least parallel
		# Make sure eyes are aligned on the y-axis
		var left_eye_rotation: Vector3 = interpolation_data.interpolate(InterpolationData.InterpolationDataType.LEFT_EYE_ROTATION, gaze_strength)
		var right_eye_rotation: Vector3 = interpolation_data.interpolate(InterpolationData.InterpolationDataType.RIGHT_EYE_ROTATION, gaze_strength)
		var average_eye_y_rotation: float = (left_eye_rotation.x + right_eye_rotation.x) / 2
		left_eye_rotation.x = average_eye_y_rotation
		right_eye_rotation.x = average_eye_y_rotation

		# TODO make this toggable from the ui
		var average_eye_x_rotation: float = (left_eye_rotation.y + right_eye_rotation.y) / 2
		left_eye_rotation.y = average_eye_x_rotation
		right_eye_rotation.y = average_eye_x_rotation

		# Left eye gaze
		if use_raw_eye_rotation:
			left_eye_rotation.x = left_eye_rotation.x
			left_eye_rotation.y = left_eye_rotation.y
		else:
			left_eye_rotation.x = clamp(left_eye_rotation.x, left_eye.down.x, left_eye.up.x)
			left_eye_rotation.y = clamp(left_eye_rotation.y, left_eye.right.y, left_eye.left.y)

		# Right eye gaze
		if use_raw_eye_rotation:
			right_eye_rotation.x = right_eye_rotation.x
			right_eye_rotation.y = right_eye_rotation.y
		else:
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
		
		# Mouth tracking
		for i in a.morphs:
			_modify_blend_shape(i.mesh, i.morph,
					min(max(i.values[0], interpolation_data.interpolate(InterpolationData.InterpolationDataType.MOUTH_MOVEMENT, 2.0)),
					i.values[1]))
	else:
		# TODO implement eco mode, should be more efficient than standard mode
		# Eco-mode blinking
		if(data.left_eye_open < blink_threshold and data.right_eye_open < blink_threshold):
			pass
		else:
			pass
