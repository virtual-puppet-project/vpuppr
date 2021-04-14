class_name BasicModel
extends Spatial

const SKELETON_NODE = "Skeleton"
const HEAD_BONE = "head"

# Used to make the model lean with head movement
export(Array, String) var additional_bones_to_pose_names: Array

var translation_damp: float = 0.3
var rotation_damp: float = 0.02
var additional_bone_damp: float = 0.3

onready var skeleton: Skeleton = find_node(SKELETON_NODE)
onready var head_bone_id: int = skeleton.find_bone(HEAD_BONE)
# String : int
var additional_bone_ids: Dictionary

# int : Transform
var initial_bone_poses: Dictionary

var has_custom_update: bool = false

###############################################################################
# Builtin functions                                                           #
###############################################################################

func _ready() -> void:
	for i in range(skeleton.get_bone_count()):
		initial_bone_poses[i] = skeleton.get_bone_pose(i)

	scan_mapped_bones()

	AppManager.emit_signal("model_loaded")

###############################################################################
# Connections                                                                 #
###############################################################################

###############################################################################
# Private functions                                                           #
###############################################################################

###############################################################################
# Public functions                                                            #
###############################################################################

func custom_update(_open_see_data: OpenSeeGD.OpenSeeData, _interpolation_data: InterpolationData) -> void:
	push_error("Model custom update not implemented")

func get_mapped_bones() -> Dictionary:
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
		additional_bone_ids[bone_name] = skeleton.find_bone(bone_name)

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

func move_eyes() -> void:
	pass
