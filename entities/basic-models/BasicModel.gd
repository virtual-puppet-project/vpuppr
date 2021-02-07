class_name BasicModel
extends Spatial

enum ExpressionTypes { DEFAULT, HAPPY, ANGRY, SAD, SHOCKED, BASHFUL }

export var head_name: String = "head"
# Used to make the model lean with head movement
export(Array, String) var additional_bones_to_pose_names: Array
export var additional_bone_damp: float = 0.3
export var path_to_skeleton: String
export var initial_animation: String

var skeleton: Skeleton
var head_bone_id: int
var additional_bone_ids: Dictionary

###############################################################################
# Builtin functions                                                           #
###############################################################################

func _ready() -> void:
	skeleton = get_node(path_to_skeleton)

	head_bone_id = skeleton.find_bone(head_name)
	for bone_name in additional_bones_to_pose_names:
		additional_bone_ids[bone_name] = skeleton.find_bone(bone_name)
		
	$AnimationPlayer.play(initial_animation)

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

func change_expression_to(expression_type: int) -> void:
	pass
