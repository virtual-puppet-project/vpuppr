class_name BasicModel
extends Spatial

const SKELETON_NODE = "Skeleton"

# Used to make the model lean with head movement
export(Array, String) var additional_bones_to_pose_names: Array

var head_bone = "head"

var translation_damp: float = 0.3
var rotation_damp: float = 0.02
var additional_bone_damp: float = 0.3

# Gaze
var gaze_strength: float = 0.5

onready var skeleton: Skeleton = find_node(SKELETON_NODE)
onready var head_bone_id: int = skeleton.find_bone(head_bone)
# String : int
var additional_bone_ids: Dictionary

# int : Transform
var initial_bone_poses: Dictionary

var has_custom_update: bool = false

###############################################################################
# Builtin functions                                                           #
###############################################################################

func _ready() -> void:
	for i in ["head_bone", "translation_damp", "rotation_damp", "additional_bone_damp", "gaze_strength"]:
		AppManager.sb.connect(i, self, "_on_%s" % i)
		set(i, AppManager.cm.current_model_config.get(i))

	for i in range(skeleton.get_bone_count()):
		initial_bone_poses[i] = skeleton.get_bone_pose(i)

	AppManager.sb.broadcast_model_loaded(self)

###############################################################################
# Connections                                                                 #
###############################################################################

func _on_head_bone(value: String) -> void:
	head_bone = value

func _on_translation_damp(value: float) -> void:
	translation_damp = value

func _on_rotation_damp(value: float) -> void:
	rotation_damp = value

func _on_additional_bone_damp(value: float) -> void:
	additional_bone_damp = value

func _on_gaze_strength(value: float) -> void:
	gaze_strength = value

###############################################################################
# Private functions                                                           #
###############################################################################

func _modify_blend_shape(mesh_instance: MeshInstance, blend_shape: String, value: float) -> void:
	mesh_instance.set(blend_shape, value)

###############################################################################
# Public functions                                                            #
###############################################################################

func custom_update(_tracking_data: TrackingData, _interpolation_data: InterpolationData) -> void:
	push_error("Model custom update not implemented")

func get_mapped_bones() -> Dictionary: # String: bool
	"""
	Returns a dictionary of all bones in the skeleton with the bones that are
	tracking input tagged as true
	"""
	var bone_data: Dictionary = {}
	for i in range(skeleton.get_bone_count()):
		var bone_name = skeleton.get_bone_name(i)
		if additional_bones_to_pose_names.has(bone_name):
			bone_data[bone_name] = true
		else:
			bone_data[bone_name] = false

	return bone_data

func scan_mapped_bones() -> void:
	for bone_name in additional_bones_to_pose_names:
		var bone_id: int = skeleton.find_bone(bone_name)
		if bone_id >= 0:
			additional_bone_ids[bone_name] = bone_id

func reset_all_bone_poses() -> void:
	for bone_id in initial_bone_poses.keys():
		skeleton.set_bone_pose(bone_id, initial_bone_poses[bone_id])

func get_head_rest() -> Transform:
	return skeleton.get_bone_rest(head_bone_id)

func get_head_pose() -> Transform:
	return skeleton.get_bone_pose(head_bone_id)

func translate_head_pose_only(v: Vector3) -> void:
	var head_transform: Transform = Transform()
	head_transform = head_transform.translated(v)
	skeleton.set_bone_pose(head_bone_id, head_transform)

func rotate_head_pose_only(v: Vector3) -> void:
	var head_transform: Transform = Transform()
	head_transform = head_transform.rotated(Vector3.RIGHT, v.x)
	head_transform = head_transform.rotated(Vector3.UP, v.y)
	head_transform = head_transform.rotated(Vector3.BACK, v.z)
	skeleton.set_bone_pose(head_bone_id, head_transform)

func move_head(translation: Vector3, rotation: Vector3) -> void:
	if not is_head_bone_id_set():
		return
	
	var head_transform: Transform = Transform()
	head_transform = head_transform.translated(translation)
	head_transform = head_transform.rotated(Vector3.RIGHT, rotation.x)
	head_transform = head_transform.rotated(Vector3.UP, rotation.y)
	head_transform = head_transform.rotated(Vector3.BACK, rotation.z)
	skeleton.set_bone_pose(head_bone_id, head_transform)
	if additional_bones_to_pose_names:
		var additional_transform = Transform()
		additional_transform = additional_transform.translated(translation * additional_bone_damp)
		additional_transform = additional_transform.rotated(Vector3.RIGHT, rotation.x * additional_bone_damp)
		additional_transform = additional_transform.rotated(Vector3.UP, rotation.y * additional_bone_damp)
		additional_transform = additional_transform.rotated(Vector3.BACK, rotation.z * additional_bone_damp)

		for bone in additional_bones_to_pose_names:
			skeleton.set_bone_pose(additional_bone_ids[bone], additional_transform)

func is_head_bone_id_set() -> bool:
	return head_bone_id and head_bone_id > -1
