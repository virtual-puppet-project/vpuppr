class_name VRMModel
extends PuppetTrait

const VRM_ANIMATION_PLAYER := "anim"

const CONFIG_VALUES := [
	"blink_threshold",
	"link_eye_blinks",
	"use_raw_eye_rotation"
]

var vrm_meta: Dictionary

var left_eye_id: int
var right_eye_id: int

#region Eye data

var blink_threshold: float
var link_eye_blinks: bool
var use_raw_eye_rotation: bool

class EyeClamps:
	var up: Vector3
	var down: Vector3
	var left: Vector3
	var right: Vector3

var left_eye: EyeClamps
var right_eye: EyeClamps

#endregion

#region Expressions

class MorphData:
	var mesh: MeshInstance
	var morph: String
	var values: Array

class ExpressionData:
	var morphs := {}

	func add_morph(morph_name: String, morph_data: MorphData) -> void:
		if not morphs.has(morph_name):
			morphs[morph_name] = []
		
			morphs[morph_name].append(morph_data)

	func get_expression(morph_name: String) -> MorphData:
		return morphs.get(morph_name)

var expression_data := ExpressionData.new()

var blink_l: MorphData
var blink_r: MorphData

# Used for toggling on/off expressions
var last_morph: MorphData

#endregion

#region Mouth shapes

var current_mouth_shape: MorphData

var a_shape: MorphData
var e_shape: MorphData
var i_shape: MorphData
var o_shape: MorphData
var u_shape: MorphData

#endregion

###############################################################################
# Builtin functions                                                           #
###############################################################################

func _ready() -> void:
	AM.ps.connect("model_config_data_changed", self, "_on_model_config_data_changed")
	AM.ps.connect("blend_shape", self, "_on_blend_shape")

	has_custom_update = true

	for i in CONFIG_VALUES:
		set(i, AM.cm.model_config.get_data(i))

	var anim_player: AnimationPlayer = find_node(VRM_ANIMATION_PLAYER)

	for animation_name in anim_player.get_animation_list():
		var animation: Animation = anim_player.get_animation(animation_name)

		for track_idx in animation.get_track_count():
			var track_name: String = animation.track_get_path(track_idx)
			var split_name: PoolStringArray = track_name.split(":")

			if split_name.size() != 2:
				AM.logger.info("Model has ultra nested meshes: %s" % track_name)
				continue

			var mesh = get_node_or_null(split_name[0])
			if not mesh:
				AM.logger.info("Unable to find mesh: %s" % split_name[0])
				continue

			var md := MorphData.new()
			md.mesh = mesh
			md.morph = split_name[1]

			for key_idx in animation.track_get_key_count(track_idx):
				md.values.append(animation.track_get_key_value(track_idx, key_idx))

			expression_data.add_morph(animation_name.to_lower(), md)

	anim_player.queue_free()

	_map_bones_and_eyes()

	_fix_additional_bones()

	blink_l = expression_data.get_expression("blink_l") # TODO this is kind of gross?
	blink_r = expression_data.get_expression("blink_r")

###############################################################################
# Connections                                                                 #
###############################################################################

func _on_model_config_data_changed(key: String, value) -> void:
	match key:
		"blink_threshold":
			blink_threshold = value
		"link_eye_blinks":
			link_eye_blinks = value
		"use_raw_eye_rotation":
			use_raw_eye_rotation = value

func _on_blend_shape(value: String) -> void:
	var ed = get(value)
	if ed == null:
		ed = expression_data.get_expression(value)
		if ed == null:
			return

	# Undo the last expression
	if last_morph:
		for idx in last_morph.morphs.size():
			_modify_blend_shape(last_morph.morphs[idx].mesh, last_morph.morphs[idx].morph,
				last_morph.morphs[idx].values[0])

	if ed == last_morph:
		last_morph = null
		return

	for idx in ed.morphs.size():
		_modify_blend_shape(ed.morphs[idx].mesh, ed.morphs[idx].morph,
				ed.morphs[idx].values[1])

	last_morph = ed

###############################################################################
# Private functions                                                           #
###############################################################################

func _setup_logger() -> void:
	logger = Logger.new("VRMModel")

func _map_bones_and_eyes() -> void:
	if head_bone_id < 0 and vrm_meta.humanoid_bone_mapping.has("head"):
		head_bone = vrm_meta.humanoid_bone_mapping["head"]
		head_bone_id = skeleton.find_bone(head_bone)

		AM.ps.broadcast_model_config_data_changed("head_bone", head_bone)

	var left_eye_name: String = vrm_meta.humanoid_bone_mapping.get("leftEye", "eye_L")
	left_eye_id = skeleton.find_bone(left_eye_name)
	if left_eye_id < 0:
		logger.error("No left eye found")

	var right_eye_name: String = vrm_meta.humanoid_bone_mapping.get("rightEye", "eye_R")
	right_eye_id = skeleton.find_bone(right_eye_name)
	if right_eye_id < 0:
		logger.error("No right eye found")

	if vrm_meta.humanoid_bone_mapping.has("neck"):
		var neck_bone_id: int = skeleton.find_bone(vrm_meta.humanoid_bone_mapping["neck"])
		if neck_bone_id >= 0:
			additional_bones.append(neck_bone_id)

	if vrm_meta.humanoid_bone_mapping.has("spine"):
		var spine_bone_id: int = skeleton.find_bone(vrm_meta.humanoid_bone_mapping["spine"])
		if spine_bone_id >= 0:
			additional_bones.append(spine_bone_id)

	var lookup := expression_data.get_expression("lookup")
	if lookup != null:
		var val = lookup.values.pop_back()
		if val:
			var rot: Quat = val["rotation"]
			match lookup.morph:
				left_eye_name:
					left_eye.up = rot.get_euler()
				right_eye_name:
					right_eye.up = rot.get_euler()
	
	var lookdown := expression_data.get_expression("lookdown")
	if lookdown != null:
		var val = lookdown.values.pop_back()
		if val:
			var rot: Quat = val["rotation"]
			match lookdown.morph:
				left_eye_name:
					left_eye.down = rot.get_euler()
				right_eye_name:
					right_eye.down = rot.get_euler()

	var lookleft := expression_data.get_expression("lookleft")
	if lookleft != null:
		var val = lookleft.values.pop_back()
		if val:
			var rot: Quat = val["rotation"]
			match lookleft.morph:
				left_eye_name:
					left_eye.left = rot.get_euler()
				right_eye_name:
					right_eye.left = rot.get_euler()

	var lookright := expression_data.get_expression("lookright")
	if lookright != null:
		var val = lookright.values.pop_back()
		if val:
			var rot: Quat = val["rotation"]
			match lookright.morph:
				left_eye_name:
					left_eye.right = rot.get_euler()
				right_eye_name:
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

func _fix_additional_bones() -> void:
	"""
	VRM models should not have 'root' assigned as tracked
	"""
	var bone_to_remove: int = -1
	for bone_idx in additional_bones:
		if skeleton.get_bone_name(bone_idx) == "root":
			bone_to_remove = bone_idx
			break
	if bone_to_remove >= 0:
		additional_bones.erase(bone_to_remove)

###############################################################################
# Public functions                                                            #
###############################################################################

func custom_update(data, interpolation_data: InterpolationData) -> void:
	# NOTE Eye mappings are intentionally reversed so that the model mirrors the data

	#region Blinking

	# TODO add way to lock blinking for a certain expression

	if link_eye_blinks:
		var average_eye_open = (data.left_eye_open + data.right_eye_open) / 2
		data.left_eye_open = average_eye_open
		data.right_eye_open = average_eye_open

	if data.left_eye_open >= blink_threshold:
		for x in expression_data.get_expression("blink_r"):
			_modify_blend_shape(x.mesh, x.morph, x.values[1] - interpolation_data.left_blink.interpolate(1.0))
	else:
		for x in expression_data.get_expression("blink_r"):
			_modify_blend_shape(x.mesh, x.morph, x.values[1])

	if data.right_eye_open >= blink_threshold:
		for x in expression_data.get_expression("blink_l"):
			_modify_blend_shape(x.mesh, x.morph, x.values[1] - interpolation_data.right_blink.interpolate(1.0))
	else:
		for x in expression_data.get_expression("blink_l"):
			_modify_blend_shape(x.mesh, x.morph, x.values[1])

	#endregion

	#region Gaze

	# TODO eyes show weird behavior when blinking
	var left_eye_rotation: Vector3 = interpolation_data.left_gaze.interpolate(gaze_strength)
	var right_eye_rotation: Vector3 = interpolation_data.right_gaze.interpolate(gaze_strength)
	var average_eye_y_rotation: float = (left_eye_rotation.x + right_eye_rotation.x) / 2.0
	left_eye_rotation.x = average_eye_y_rotation
	right_eye_rotation.x = average_eye_y_rotation

	# TODO make this toggleable from the ui
	var average_eye_x_rotation: float = (left_eye_rotation.y + right_eye_rotation.y) / 2.0
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

	#endregion

	#region Mouth tracking
		
	var mouth_open: float = interpolation_data.interpolate(InterpolationData.InterpolationDataType.MOUTH_OPEN, 2.0)

	var mouth_wide: float = interpolation_data.interpolate(InterpolationData.InterpolationDataType.MOUTH_WIDE, 2.0)

	var mouth_scale_x: int = 0
	var mouth_scale_y: int = 0
	
	if mouth_open < AM.cm.model_config.mouth_open_max * AM.cm.model_config.mouth_open_group_1:
		mouth_scale_x = 1
	elif mouth_open <= AM.cm.model_config.mouth_open_max * AM.cm.model_config.mouth_open_group_2:
		mouth_scale_x = 2
	else:
		mouth_scale_x = 3

	if mouth_wide < AM.cm.model_config.mouth_wide_max * AM.cm.model_config.mouth_wide_group_1:
		mouth_scale_y = 1
	elif mouth_wide <= AM.cm.model_config.mouth_wide_max * AM.cm.model_config.mouth_wide_group_2:
		mouth_scale_y = 2
	else:
		mouth_scale_y = 3

	var last_shape = current_mouth_shape

	match mouth_scale_x:
		1:
			match mouth_scale_y:
				1:
					current_mouth_shape = u_shape
				2:
					# current_mouth_shape = e
					pass
				3:
					current_mouth_shape = i_shape
		2:
			current_mouth_shape = e_shape
		3:
			match mouth_scale_y:
				1:
					current_mouth_shape = o_shape
				2:
					# current_mouth_shape = e
					pass
				3:
					current_mouth_shape = a_shape

	if current_mouth_shape != last_shape:
		for x in last_shape.morphs:
			_modify_blend_shape(x.mesh, x.morph, 0)

	for x in current_mouth_shape.morphs:
		_modify_blend_shape(x.mesh, x.morph, min(max(x.values[0], mouth_open), x.values[1]))

	#endregion

func a_pose() -> void:
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
