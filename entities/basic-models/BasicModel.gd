class_name BasicModel
extends Spatial

const SKELETON_NODE = "Skeleton"
const HEAD_BONE = "head"

# Used to make the model lean with head movement
export(Array, String) var additional_bones_to_pose_names: Array
export var additional_bone_damp: float = 0.3

onready var skeleton: Skeleton = find_node(SKELETON_NODE)
onready var head_bone_id: int = skeleton.find_bone(HEAD_BONE)
var additional_bone_ids: Dictionary

###############################################################################
# Builtin functions                                                           #
###############################################################################

func _ready() -> void:
	for bone_name in additional_bones_to_pose_names:
		additional_bone_ids[bone_name] = skeleton.find_bone(bone_name)

###############################################################################
# Connections                                                                 #
###############################################################################

###############################################################################
# Private functions                                                           #
###############################################################################

###############################################################################
# Public functions                                                            #
###############################################################################

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
