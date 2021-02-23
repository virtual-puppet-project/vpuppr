extends Resource

# Annotation comment
export var comment: String

# The resilience of the swaying object (the power of returning to the initial pose).
export (float, 0, 4) var stiffness_force: float = 1.0

# The strength of gravity.
export (float, 0, 2) var gravity_power: float = 0.0

# The direction of gravity. Set (0, -1, 0) for simulating the gravity.
# Set (1, 0, 0) for simulating the wind.
export var gravity_dir: Vector3 = Vector3(0.0, -1.0, 0.0)

# The resistance (deceleration) of automatic animation.
export (float, 0, 1) var drag_force: float = 0.4

# Bone name references are only valid within a given Skeleton.
export var skeleton: NodePath

# The reference point of a swaying object can be set at any location except the origin.
# When implementing UI moving with warp, the parent node to move with warp can be
# specified if you don't want to make the object swaying with warp movement.",
# Exactly one of the following must be set.
export var center_bone: String = ""
export var center_node: NodePath

# The radius of the sphere used for the collision detection with colliders.
export (float, 0.0, 0.5) var hit_radius: float = 0.02

# bone name of the root bone of the swaying object, within skeleton.
export (Array, String) var root_bones : Array # DO NOT INITIALIZE HERE

# Reference to the vrm_collidergroup for collisions with swaying objects.
export var collider_groups : Array # DO NOT INITIALIZE HERE

# Props
var verlets: Array = []
var colliders: Array = []
var center = null

func setup(skeleton: Skeleton, force: bool = false) -> void:
	if self.root_bones != null && skeleton != null:
		if force || verlets.empty():
			if not verlets.empty():
				for verlet in verlets:
					verlet.reset()
			verlets.clear()
			for go in root_bones:
				if go != null:
					setup_recursive(skeleton, skeleton.find_bone(go), center)
	return

func setup_recursive(skeleton: Skeleton, id: int, center_tr) -> void:
	if skeleton.get_bone_children(id).empty():
		var delta: Vector3 = skeleton.get_bone_rest(id).origin
		var child_position: Vector3 = delta.normalized() * 0.07
		verlets.append(VRMSpringBoneLogic.new(skeleton, id, center_tr, child_position, skeleton.get_bone_global_pose(id)))
	else:
		var first_child: int = skeleton.get_bone_children(id)[0]
		var local_position: Vector3 = skeleton.get_bone_rest(first_child).origin
		var sca: Vector3 = skeleton.get_bone_rest(first_child).basis.get_scale()
		var pos: Vector3 = Vector3(local_position.x * sca.x, local_position.y * sca.y, local_position.z * sca.z)
		verlets.append(VRMSpringBoneLogic.new(skeleton, id, center_tr, pos, skeleton.get_bone_global_pose(id)))
	for child in skeleton.get_bone_children(id):
		setup_recursive(skeleton, child, center_tr)
	return

# Called when the node enters the scene tree for the first time.
func _ready(skel: Skeleton):
	setup(skel)
	for collider_group in collider_groups:
		colliders.append_array(collider_group.colliders)
	return

# Called every frame. 'delta' is the elapsed time since the previous frame.
func _process(delta, skel: Skeleton):
	if verlets.empty():
		if root_bones == null:
			return
		setup(skel)
	
	var stiffness = stiffness_force * delta
	var external = gravity_dir * (gravity_power * delta)
	
	for verlet in verlets:
		verlet.radius = hit_radius
		verlet.update(center, stiffness, drag_force, external, colliders)
	return





# Individual spring bone entries.
class VRMSpringBoneLogic:
	var skeleton: Skeleton
	var bone_idx: int
	
	var radius: float
	var length: float
	
	var bone_axis: Vector3
	var current_tail: Vector3 
	var prev_tail: Vector3
	
	var initial_transform: Transform
	
	func get_transform() -> Transform:
		return skeleton.global_transform * skeleton.get_bone_global_pose(bone_idx)
	func get_rotation() -> Quat:
		return get_transform().basis.get_rotation_quat()
	
	func get_local_transform() -> Transform:
		return skeleton.get_bone_global_pose(bone_idx)
	func get_local_rotation() -> Quat:
		return get_local_transform().basis.get_rotation_quat()
	
	func reset(transform: Transform) -> void:
		skeleton.set_bone_global_pose_override(bone_idx, initial_transform, 1.0)
		return
	
	func _init(skel: Skeleton, idx: int, center, local_child_position: Vector3, default_pose: Transform) -> void:
		initial_transform = default_pose
		skeleton = skel
		bone_idx = idx
		var world_child_position: Vector3 = VRMTopLevel.VRMUtil.transform_point(get_transform(), local_child_position)
		if center != null:
			current_tail = VRMTopLevel.VRMUtil.inv_transform_point(center, world_child_position)
		else:
			current_tail = world_child_position
		prev_tail = current_tail
		bone_axis = local_child_position.normalized()
		length = local_child_position.length()
		return
	
	func update(center, stiffness_force: float, drag_force: float, external: Vector3, colliders: Array) -> void:
		var tmp_current_tail: Vector3
		var tmp_prev_tail: Vector3
		if center != null:
			tmp_current_tail = VRMTopLevel.VRMUtil.transform_point(center, current_tail)
			tmp_prev_tail = VRMTopLevel.VRMUtil.transform_point(center, prev_tail)
		else:
			tmp_current_tail = current_tail
			tmp_prev_tail = prev_tail
		
		# Integration of velocity verlet
		var next_tail: Vector3 = tmp_current_tail + (tmp_current_tail - tmp_prev_tail) * (1.0 - drag_force) + get_rotation().xform(bone_axis) * stiffness_force + external
		
		# Limiting bone length
		next_tail = get_transform().origin + (next_tail - get_transform().origin).normalized() * length
		
		# Collision movement
		next_tail = collision(colliders, next_tail)
		
		# Recording current tails for next process
		if center != null:
			prev_tail = VRMTopLevel.VRMUtil.inv_transform_point(center, current_tail)
			current_tail = VRMTopLevel.VRMUtil.inv_transform_point(center, next_tail)
		else:
			prev_tail = current_tail
			current_tail = next_tail
		
		# Apply rotation
		var ft = VRMTopLevel.VRMUtil.from_to_rotation(get_rotation().xform(bone_axis), next_tail - get_transform().origin)
		if ft != null:
			ft = skeleton.global_transform.basis.get_rotation_quat().inverse() * ft
			var qt: Quat = ft * get_rotation()
			var tr: Transform = get_local_transform()
			tr.basis = Basis(qt.normalized())
			skeleton.set_bone_global_pose_override(bone_idx, tr, 1.0)
		
		return
	
	func collision(colliders: Array, _next_tail: Vector3) -> Vector3:
		var out: Vector3 = _next_tail
		for collider in colliders:
			var r = radius + collider.get_radius()
			var diff: Vector3 = out - collider.get_position()
			if (diff.x * diff.x + diff.y * diff.y + diff.z * diff.z) <= r * r:
				# Hit, move to orientation of normal
				var normal: Vector3 = (out - collider.get_position()).normalized()
				var pos_from_collider = collider.get_position() + normal * (radius + collider.get_radius())
				# Limiting bone length
				out = get_transform().origin + (pos_from_collider - get_transform().origin).normalized() * length
		return out
