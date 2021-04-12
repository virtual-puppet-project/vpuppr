extends BasicModel

# VRM guarantees neck and spine to exist
# These might not be named exactly 'neck' and 'spine', so this is best effort only
const NECK_BONE = "neck"
const SPINE_BONE = "spine"

onready var neck_bone_id: int = skeleton.find_bone(NECK_BONE)
onready var spine_bone_id: int = skeleton.find_bone(SPINE_BONE)

var eco_mode: bool = false

var stored_offsets: ModelDisplayScreen.StoredOffsets

var vrm_mappings: VRMMappings
var left_eye_id: int
var right_eye_id: int

var mapped_meshes: Dictionary

# Blinking
var blink_threshold: float = 0.3
var eco_mode_is_blinking: bool = false

# Mouth
var min_mouth_value: float = 0.0

###############################################################################
# Builtin functions                                                           #
###############################################################################

func _ready() -> void:
	translation_damp = 0.1
	rotation_damp = 0.01
	additional_bone_damp = 0.6

	stored_offsets = get_parent().get_parent().stored_offsets

	# Read vrm mappings
	has_custom_update = true
	if vrm_mappings.head != HEAD_BONE:
		head_bone_id = skeleton.find_bone(vrm_mappings.head)
	left_eye_id = skeleton.find_bone(vrm_mappings.left_eye)
	right_eye_id = skeleton.find_bone(vrm_mappings.right_eye)
	for mesh_name in vrm_mappings.meshes_used:
		mapped_meshes[mesh_name] = find_node(mesh_name) as MeshInstance

	if not neck_bone_id:
		AppManager.log_message("Neck bone not found. Is this a .vrm model?")
	if not spine_bone_id:
		AppManager.log_message("Spine bone not found. Is this a .vrm model?")
	
	additional_bones_to_pose_names.append(NECK_BONE)
	additional_bones_to_pose_names.append(SPINE_BONE)

	scan_mapped_bones()

###############################################################################
# Connections                                                                 #
###############################################################################

###############################################################################
# Private functions                                                           #
###############################################################################

static func _to_godot_quat(v: Quat) -> Quat:
	return Quat(v.x, -v.y, v.z, v.w)

func _modify_blend_shape(mesh_instance: MeshInstance, blend_shape: String, value: float) -> void:
	mesh_instance.set("blend_shapes/%s" % blend_shape, value)

###############################################################################
# Public functions                                                            #
###############################################################################

func custom_update(data: OpenSeeGD.OpenSeeData) -> void:
	# TODO i think this can be made more efficient
	if not eco_mode:
		# Left eye blinking
		if data.left_eye_open >= blink_threshold:
			for mesh_name in vrm_mappings.blink_l.get_meshes():
				for blend_name in vrm_mappings.blink_l.expression_data[mesh_name]:
					_modify_blend_shape(
						mapped_meshes[mesh_name],
						blend_name,
						1.0 - data.left_eye_open
					)
		else:
			for mesh_name in vrm_mappings.blink_l.get_meshes():
				for blend_name in vrm_mappings.blink_l.expression_data[mesh_name]:
					_modify_blend_shape(
						mapped_meshes[mesh_name],
						blend_name,
						1.0
					)

		# Right eye blinking
		if data.right_eye_open >= blink_threshold:
			for mesh_name in vrm_mappings.blink_r.get_meshes():
				for blend_name in vrm_mappings.blink_r.expression_data[mesh_name]:
					_modify_blend_shape(
						mapped_meshes[mesh_name],
						blend_name,
						1.0 - data.right_eye_open
					)
		else:
			for mesh_name in vrm_mappings.blink_r.get_meshes():
				for blend_name in vrm_mappings.blink_r.expression_data[mesh_name]:
					_modify_blend_shape(
						mapped_meshes[mesh_name],
						blend_name,
						1.0
					)

		# TODO eyes are a bit wonky
		# TODO left eye is biased towards corners
		# TODO right eye doesn't really look up or down
		# NOTE: We don't want the y-rotation when tracking gaze otherwise your eye will rotate in its socket
		# Left eye gaze
		var left_eye_transform: Transform = Transform()
		var left_eye_rotation: Vector3 = (stored_offsets.left_eye_gaze_offset - data.left_gaze.get_euler()) * 4
		left_eye_transform = left_eye_transform.rotated(Vector3.UP, left_eye_rotation.x)
		# if left_eye_rotation.z > 0:
		# 	left_eye_transform = left_eye_transform.rotated(Vector3.LEFT, -left_eye_rotation.z)
		# else:
		# 	left_eye_transform = left_eye_transform.rotated(Vector3.LEFT, left_eye_rotation.z)
		skeleton.set_bone_pose(left_eye_id, left_eye_transform)
		
		# Right eye gaze
		var right_eye_transform: Transform = Transform()
		var right_eye_rotation: Vector3 = (stored_offsets.right_eye_gaze_offset - data.right_gaze.get_euler()) * 4
		right_eye_transform = right_eye_transform.rotated(Vector3.UP, right_eye_rotation.x)
		# if right_eye_rotation.z > 0:
		# 	right_eye_transform = right_eye_transform.rotated(Vector3.LEFT, right_eye_rotation.z)
		# else:
		# 	right_eye_transform = right_eye_transform.rotated(Vector3.LEFT, -right_eye_rotation.z)
		skeleton.set_bone_pose(right_eye_id, right_eye_transform)

		# TODO im not sure what these are tracking?
		# Features eye left
		# var left_eye_transform: Transform = Transform()
		# print(data.features.eye_left)
		# left_eye_transform.rotated(Vector3.UP, data.features.eye_left * 1.5)
		# skeleton.set_bone_pose(left_eye_id, left_eye_transform)

		# # Features eye right
		# var right_eye_transform: Transform = Transform()
		# right_eye_transform.rotated(Vector3.UP, data.features.eye_right * 1.5)
		# skeleton.set_bone_pose(right_eye_id, right_eye_transform)
		
		# Mouth tracking
		for mesh_name in vrm_mappings.a.get_meshes():
			for blend_name in vrm_mappings.a.expression_data[mesh_name]:
				_modify_blend_shape(
					mapped_meshes[mesh_name],
					blend_name,
					max(min_mouth_value, data.features.mouth_open)
				)
	else:
		# TODO implement eco mode, should be more efficient than standard mode
		# Eco-mode blinking
		if(data.left_eye_open < blink_threshold and data.right_eye_open < blink_threshold):
			pass
		else:
			pass
