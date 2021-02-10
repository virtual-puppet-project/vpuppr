extends Spatial

const SKELETON_NODE = "Skeleton"
const HEAD_BONE = "head"
const NECK_BONE = "neck"
const SPINE_BONE = "spine"

onready var skeleton: Skeleton = find_node(SKELETON_NODE)
onready var head_bone_id: int = skeleton.find_bone(HEAD_BONE)
onready var neck_bone_id: int = skeleton.find_bone(NECK_BONE)
onready var spine_bone_id: int = skeleton.find_bone(SPINE_BONE)

export var additional_bone_damp: float = 0.6

###############################################################################
# Builtin functions                                                           #
###############################################################################

func _ready() -> void:
	pass

###############################################################################
# Connections                                                                 #
###############################################################################

###############################################################################
# Private functions                                                           #
###############################################################################

###############################################################################
# Public functions                                                            #
###############################################################################

func move_head(translation: Vector3, rotation: Vector3) -> void:
	var head_transform: Transform = Transform()
	head_transform = head_transform.translated(translation)
	head_transform = head_transform.rotated(Vector3.RIGHT, rotation.x)
	head_transform = head_transform.rotated(Vector3.UP, rotation.y)
	head_transform = head_transform.rotated(Vector3.BACK, rotation.z)
	skeleton.set_bone_pose(head_bone_id, head_transform)

	var additional_transform = Transform()
	additional_transform = additional_transform.translated(translation * additional_bone_damp)
	additional_transform = additional_transform.rotated(Vector3.RIGHT, rotation.x * additional_bone_damp)
	additional_transform = additional_transform.rotated(Vector3.UP, rotation.y * additional_bone_damp)
	additional_transform = additional_transform.rotated(Vector3.BACK, rotation.z * additional_bone_damp)
	skeleton.set_bone_pose(neck_bone_id, additional_transform)
	skeleton.set_bone_pose(spine_bone_id, additional_transform)
