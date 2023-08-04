@tool
class_name VRMSpringBone
extends Resource

const VRMSpringBoneLogic = preload("./vrm_spring_bone_logic.gd")
const vrm_collider_group = preload("./vrm_collider_group.gd")
const vrm_collider = preload("./vrm_collider.gd")

# Annotation comment
@export var comment: String

# bone name of the root bone of the swaying object, within skeleton.
@export var joint_nodes: PackedStringArray

# The resilience of the swaying object (the power of returning to the initial pose).
@export var stiffness_force: PackedFloat64Array
# The strength of gravity.
@export var gravity_power: PackedFloat64Array
# The direction of gravity. Set (0, -1, 0) for simulating the gravity.
# Set (1, 0, 0) for simulating the wind.
@export var gravity_dir: PackedVector3Array
# The resistance (deceleration) of automatic animation.
@export var drag_force: PackedFloat64Array
# The radius of the sphere used for the collision detection with colliders.
@export var hit_radius: PackedFloat64Array

# The reference point of a swaying object can be set at any location except the origin.
# When implementing UI moving with warp, the parent node to move with warp can be
# specified if you don't want to make the object swaying with warp movement.",
# Exactly one of the following must be set.
@export var center_bone: String = ""
@export var center_node: NodePath = NodePath()

# Reference to the vrm_collidergroup for collisions with swaying objects.
@export var collider_groups: Array[vrm_collider_group]

# Props
var verlets: Array[VRMSpringBoneLogic]
var colliders: Array[vrm_collider.VrmRuntimeCollider]
var center = null
var skel: Skeleton3D = null

var has_warned: bool = false
var disable_colliders: bool = false
var gravity_multiplier: float = 1.0
var gravity_rotation: Quaternion = Quaternion.IDENTITY
var add_force: Vector3 = Vector3.ZERO


func setup(center_transform_inv: Transform3D, force: bool = false) -> void:
	if len(joint_nodes) < 2:
		if force and not has_warned:
			has_warned = true
			push_warning(str(resource_name) + ": Springbone chain has insufficient joints.")
		return
	if not self.joint_nodes.is_empty() && skel != null:
		if force || verlets.is_empty():
			if not verlets.is_empty():
				for verlet in verlets:
					verlet.reset(skel)
			verlets.clear()
			for id in range(len(joint_nodes) - 1):
				var verlet: VRMSpringBoneLogic = create_vertlet(id, center_transform_inv)
				verlets.append(verlet)


func create_vertlet(id: int, center_tr_inv: Transform3D) -> VRMSpringBoneLogic:
	var verlet: VRMSpringBoneLogic
	if id < len(joint_nodes) - 1:
		var bone_idx: int = skel.find_bone(joint_nodes[id])
		var pos: Vector3
		if joint_nodes[id + 1].is_empty():
			var delta: Vector3 = skel.get_bone_rest(bone_idx).origin
			pos = delta.normalized() * 0.07
		else:
			var first_child: int = skel.find_bone(joint_nodes[id + 1])
			var local_position: Vector3 = skel.get_bone_rest(first_child).origin
			var sca: Vector3 = skel.get_bone_rest(first_child).basis.get_scale()
			pos = Vector3(local_position.x * sca.x, local_position.y * sca.y, local_position.z * sca.z)
		verlet = VRMSpringBoneLogic.new(skel, bone_idx, center_tr_inv, pos, skel.get_bone_global_pose_no_override(id))
	return verlet


func ready(ready_skel: Skeleton3D, colliders_ref: Array[vrm_collider.VrmRuntimeCollider], center_transform_inv: Transform3D) -> void:
	if ready_skel != null:
		self.skel = ready_skel
	setup(center_transform_inv)
	colliders = colliders_ref.duplicate(false)


func update(delta: float, center_transform: Transform3D, center_transform_inv: Transform3D) -> void:
	if verlets.is_empty():
		if joint_nodes.is_empty():
			return
		setup(center_transform_inv)

	var tmp_colliders: Array[vrm_collider.VrmRuntimeCollider]
	if not disable_colliders:
		tmp_colliders = colliders

	for i in range(len(verlets)):
		var stiffness: float = stiffness_force[i] * delta
		var external: Vector3 = gravity_dir[i] * (gravity_power[i] * delta) * gravity_multiplier
		if !gravity_rotation.is_equal_approx(Quaternion.IDENTITY):
			external = gravity_rotation * external
		external += add_force * delta
		verlets[i].radius = hit_radius[i]
		verlets[i].update(skel, center_transform, center_transform_inv, stiffness, drag_force[i], external, tmp_colliders)
