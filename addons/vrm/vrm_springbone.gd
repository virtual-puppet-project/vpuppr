tool
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
var skel: Skeleton = null
var skel_polyfill: Object = null

func setup(force: bool = false) -> void:
	if typeof(self.root_bones) != TYPE_NIL && ! self.root_bones.empty() && skeleton != null:
		if force || verlets.empty():
			if not verlets.empty():
				for verlet in verlets:
					verlet.reset(skel_polyfill)
			verlets.clear()
			for go in root_bones:
				if go != null:
					setup_recursive(skel.find_bone(go), center)
	return

func setup_recursive(id: int, center_tr) -> void:
	if skel_polyfill.get_bone_children(id).empty():
		var delta: Vector3 = skel.get_bone_rest(id).origin
		var child_position: Vector3 = delta.normalized() * 0.07
		verlets.append(VRMSpringBoneLogic.new(skel, skel_polyfill, id, center_tr, child_position, skel_polyfill.get_bone_global_pose_without_override(id, true)))
	else:
		var first_child: int = skel_polyfill.get_bone_children(id)[0]
		var local_position: Vector3 = skel.get_bone_rest(first_child).origin
		var sca: Vector3 = skel.get_bone_rest(first_child).basis.get_scale()
		var pos: Vector3 = Vector3(local_position.x * sca.x, local_position.y * sca.y, local_position.z * sca.z)
		verlets.append(VRMSpringBoneLogic.new(skel, skel_polyfill, id, center_tr, pos, skel_polyfill.get_bone_global_pose_without_override(id, true)))
	for child in skel_polyfill.get_bone_children(id):
		setup_recursive(child, center_tr)
	return

# Called when the node enters the scene tree for the first time.
func _ready(skel: Skeleton, skel_polyfill: Object, colliders_ref: Array):
	if skel != null:
		self.skel = skel
		self.skel_polyfill = skel_polyfill
	setup()
	colliders = colliders_ref.duplicate(true)
	return

# Called every frame. 'delta' is the elapsed time since the previous frame.
func _process(delta):
	if verlets.empty():
		if typeof(root_bones) == TYPE_NIL || root_bones.empty():
			return
		setup()
	
	var stiffness = stiffness_force * delta
	var external = gravity_dir * (gravity_power * delta)
	
	for verlet in verlets:
		verlet.radius = hit_radius
		verlet.update(skel, skel_polyfill, center, stiffness, drag_force, external, colliders)
	return





# Individual spring bone entries.
class VRMSpringBoneLogic:
	var force_update: bool = true
	var bone_idx: int
	
	var radius: float
	var length: float
	
	var bone_axis: Vector3
	var current_tail: Vector3 
	var prev_tail: Vector3
	
	var initial_transform: Transform

	func get_transform(skel: Skeleton, skel_polyfill: Object) -> Transform:
		return skel.global_transform * skel_polyfill.get_bone_global_pose_without_override(bone_idx)
	func get_rotation(skel: Skeleton, skel_polyfill: Object) -> Quat:
		return get_transform(skel, skel_polyfill).basis.get_rotation_quat()

	func get_local_transform(skel_polyfill: Object) -> Transform:
		return skel_polyfill.get_bone_global_pose_without_override(bone_idx)
	func get_local_rotation(skel_polyfill: Object) -> Quat:
		return get_local_transform(skel_polyfill).basis.get_rotation_quat()
	
	func reset(skel_polyfill: Object) -> void:
		skel_polyfill.set_bone_global_pose_override(bone_idx, initial_transform, 1.0)
		return
	
	func _init(skel: Skeleton, skel_polyfill: Object, idx: int, center, local_child_position: Vector3, default_pose: Transform):
		initial_transform = default_pose
		bone_idx = idx
		var world_child_position: Vector3 = VRMTopLevel.VRMUtil.transform_point(get_transform(skel, skel_polyfill), local_child_position)
		if typeof(center) != TYPE_NIL:
			current_tail = VRMTopLevel.VRMUtil.inv_transform_point(center, world_child_position)
		else:
			current_tail = world_child_position
		prev_tail = current_tail
		bone_axis = local_child_position.normalized()
		length = local_child_position.length()
		return
	
	func update(skel: Skeleton, skel_polyfill: Object, center, stiffness_force: float, drag_force: float, external: Vector3, colliders: Array) -> void:
		var tmp_current_tail: Vector3
		var tmp_prev_tail: Vector3
		if typeof(center) != TYPE_NIL:
			tmp_current_tail = VRMTopLevel.VRMUtil.transform_point(center, current_tail)
			tmp_prev_tail = VRMTopLevel.VRMUtil.transform_point(center, prev_tail)
		else:
			tmp_current_tail = current_tail
			tmp_prev_tail = prev_tail
		
		# Integration of velocity verlet
		var next_tail: Vector3 = tmp_current_tail + (tmp_current_tail - tmp_prev_tail) * (1.0 - drag_force) + (get_rotation(skel, skel_polyfill) * (bone_axis)) * stiffness_force + external
		
		# Limiting bone length
		var origin: Vector3 = get_transform(skel, skel_polyfill).origin
		next_tail = origin + (next_tail - origin).normalized() * length
		
		# Collision movement
		next_tail = collision(skel, skel_polyfill, colliders, next_tail)
		
		# Recording current tails for next process
		if typeof(center) != TYPE_NIL:
			prev_tail = VRMTopLevel.VRMUtil.inv_transform_point(center, current_tail)
			current_tail = VRMTopLevel.VRMUtil.inv_transform_point(center, next_tail)
		else:
			prev_tail = current_tail
			current_tail = next_tail
		
		# Apply rotation
		var ft = VRMTopLevel.VRMUtil.from_to_rotation((get_rotation(skel, skel_polyfill) * (bone_axis)), next_tail - get_transform(skel, skel_polyfill).origin)
		if typeof(ft) != TYPE_NIL:
			ft = skel.global_transform.basis.get_rotation_quat().inverse() * ft
			var qt: Quat = ft * get_rotation(skel, skel_polyfill)
			var tr: Transform = get_local_transform(skel_polyfill)
			tr.basis = Basis(qt.normalized())
			skel_polyfill.set_bone_global_pose_override(bone_idx, tr, 1.0)
		
		return
	
	func collision(skel: Skeleton, skel_polyfill: Object, colliders: Array, _next_tail: Vector3) -> Vector3:
		var out: Vector3 = _next_tail
		for collider in colliders:
			var r = radius + collider.get_radius()
			var diff: Vector3 = out - collider.get_position()
			if (diff.x * diff.x + diff.y * diff.y + diff.z * diff.z) <= r * r:
				# Hit, move to orientation of normal
				var normal: Vector3 = (out - collider.get_position()).normalized()
				var pos_from_collider = collider.get_position() + normal * (radius + collider.get_radius())
				# Limiting bone length
				var origin: Vector3 = get_transform(skel, skel_polyfill).origin
				out = origin + (pos_from_collider - origin).normalized() * length
		return out
