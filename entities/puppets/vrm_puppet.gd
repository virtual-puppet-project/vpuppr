class_name VRMPuppet
extends GLBPuppet

const RenIK: GDScript = preload("res://addons/renik/renik.gd")

# var vrm_meta

var _animation_player: AnimationPlayer = null

var ik_targets := {}
var _ik_target_offsets := {}
# TODO refactor into class
var _blend_shape_mappings := {}
# TODO refactor into class
var _expression_mappings := {}

#-----------------------------------------------------------------------------#
# Builtin functions
#-----------------------------------------------------------------------------#

func _init() -> void:
	_logger = Logger.create("VRMPuppet")

func _ready() -> void:
	_logger.debug("Starting ready")
	
	if puppet_data == null:
		_logger.error("Puppet data was not set, bailing out early")
		return

	skeleton = _find_skeleton()
	if skeleton == null:
		_logger.error("Unable to find skeleton, bailing out early")
		return
	_animation_player = _find_animation_player()
	if _animation_player == null:
		_logger.error("Unable to find animation player, bailing out early")
		return

	var ik_armature_names := {
		head = "Head",
		left_hand = "LeftHand",
		right_hand = "RightHand",
		hips = "Hips",
		left_foot = "LeftFoot",
		right_foot = "RightFoot"
	}
	for variable_name in ik_armature_names:
		var bone_name: String = ik_armature_names[variable_name]
		_create_ik_armature(variable_name, bone_name)

	_populate_blend_shape_mappings()
	_populate_and_modify_expression_mappings()
	_setup_ik()

	_logger.debug("Finished ready")

#-----------------------------------------------------------------------------#
# Private functions
#-----------------------------------------------------------------------------#

func _find_animation_player() -> AnimationPlayer:
	return find_child("AnimationPlayer", true, false)

func _create_ik_armature(armature_name: String, bone_name: String) -> void:
	var bone_idx := skeleton.find_bone(bone_name)
	if bone_idx < 0:
		_logger.error("Unable to find bone {bone}".format({bone = bone_name}))
		return

	var tx := skeleton.get_bone_global_pose(bone_idx)
	tx.origin = self.to_global(tx.origin)

	var armature := Node3D.new()
	armature.name = armature_name
	armature.transform = tx

	ik_targets[armature_name] = armature

	var initial_tx = puppet_data.ik_targets.get(armature_name)
	if initial_tx == null:
		_logger.error("IKTargets3D did not have {target_name}".format({target_name = armature_name}))
		return
	if not initial_tx is Transform3D:
		_logger.error("IKTargets3D had incorrect type for {target_name}".format({target_name = armature_name}))
		return
	
	if initial_tx == Transform3D.IDENTITY:
		initial_tx = skeleton.get_bone_global_pose(skeleton.find_bone(bone_name))
		initial_tx.origin = self.to_global(initial_tx.origin)
		
	_ik_target_offsets[armature_name] = initial_tx

## Iterate through every child node of a [Skeleton3D] and, if that node is a
## [MeshInstance3D], register every blend shape present on the mesh.
func _populate_blend_shape_mappings() -> void:
	for child in skeleton.get_children():
		if not child is MeshInstance3D:
			_logger.debug("Child {child_name} was not a MeshInstance3D, skipping".format({child_name = child.name}))
			continue

		var mi := child as MeshInstance3D
		var mesh := mi.mesh
		if not mesh is ArrayMesh:
			_logger.error("{child_name}'s mesh was not an ArrayMesh, skipping".format({child_name = child.name}))
			continue

		var arr_mesh := mesh as ArrayMesh
		for idx in arr_mesh.get_blend_shape_count():
			var blend_shape_name := arr_mesh.get_blend_shape_name(idx)
			var blend_shape_property_path := "blend_shapes/{shape_name}".format({shape_name = blend_shape_name})
			var value := mi.get_blend_shape_value(idx)

			_blend_shape_mappings[blend_shape_name.to_lower()] = {
				child = child,
				property_path = blend_shape_property_path,
				value = value
			}

func _populate_and_modify_expression_mappings() -> void:
	var valid_track_types = [Animation.TYPE_ROTATION_3D, Animation.TYPE_BLEND_SHAPE]

	for animation_name in _animation_player.get_animation_list():
		var animation = _animation_player.get_animation(animation_name)
		if animation == null:
			_logger.error("Unable to get animation while setting up, this is a serious bug! Bailing out!")
			return

		var morphs := []

		for track_idx in animation.get_track_count():
			var track_name := String(animation.track_get_path(track_idx))
			if animation.track_get_key_count(track_idx) < 1:
				_logger.debug("{track_name} does not contain a key, skipping!".format({track_name = track_name}))
				continue
			var track_type := animation.track_get_type(track_idx)
			if not track_type in valid_track_types:
				_logger.debug("{track_name} is not handled, skipping!".format({track_name = track_name}))
				continue

			var track_name_split := track_name.split(":", true, 1)
			if track_name_split.size() != 2:
				_logger.error("Unable to split track {track_name}, this is slightly unexpected")
				continue
			var morph_name := track_name_split[1]

			match track_type:
				Animation.TYPE_ROTATION_3D:
					_logger.debug("rotation tracks not yet handled")
					continue
				Animation.TYPE_BLEND_SHAPE:
					morphs.append(morph_name)
				_:
					_logger.error("Trying to handle invalid track type {track_type}, this is a major".format({
						track_type = track_type
					}))
					continue

		_expression_mappings[animation_name.to_lower()] = morphs

func _setup_ik() -> Error:
	var ren_ik: RenIK3D = RenIK.new()
	ren_ik.name = "RenIK3D"
	
	ren_ik.armature_skeleton_path = skeleton.get_path()

	var armature_targets := Node3D.new()
	armature_targets.name = "ArmatureTargets"
	add_child(armature_targets)

	if ik_targets.head != null:
		armature_targets.add_child(ik_targets.head)
		ren_ik.armature_head_target = ik_targets.head.get_path()
	if ik_targets.left_hand != null:
		var target: Node3D = ik_targets.left_hand
		armature_targets.add_child(target)
		target.position.y = 0
		target.rotation_degrees.x = 164

		ik_targets.left_hand_starting_transform = target.transform

		ren_ik.armature_left_hand_target = ik_targets.left_hand.get_path()
	if ik_targets.right_hand != null:
		var target: Node3D= ik_targets.right_hand
		armature_targets.add_child(ik_targets.right_hand)
		target.position.y = 0
		target.rotation_degrees.x = 164

		ik_targets.right_hand_starting_transform = target.transform

		ren_ik.armature_right_hand_target = ik_targets.right_hand.get_path()
	if ik_targets.hips != null:
		# TODO stub
		armature_targets.add_child(ik_targets.hips)
		ren_ik.armature_hip_target = ik_targets.hips.get_path()
	if ik_targets.left_foot != null:
		# TODO stub
		armature_targets.add_child(ik_targets.left_foot)
		ren_ik.armature_left_foot_target = ik_targets.left_foot.get_path()
	if ik_targets.right_foot != null:
		# TODO stub
		armature_targets.add_child(ik_targets.right_foot)
		ren_ik.armature_right_foot_target = ik_targets.right_foot.get_path()
	
	add_child(ren_ik)
	ren_ik.live_preview = true
	
	return OK

#-----------------------------------------------------------------------------#
# Public functions
#-----------------------------------------------------------------------------#

func update_from_config(data: VRMPuppetData) -> void:
	transform.origin = data.position

func a_pose() -> Error:
	if skeleton == null:
		_logger.error("Skeleton was None while trying to A-pose, this is a bug!")
		return ERR_UNCONFIGURED

	const L_SHOULDER := "LeftShoulder"
	const R_SHOULDER := "RightShoulder"
	const L_UPPER_ARM := "LeftUpperArm"
	const R_UPPER_ARM := "RightUpperArm"

	for bone_name in [L_SHOULDER, R_SHOULDER, L_UPPER_ARM, R_UPPER_ARM]:
		var bone_idx := skeleton.find_bone(bone_name)
		if bone_idx < 0:
			_logger.error("Bone not found while trying to A-pose: {bone_name}".format({bone_name = bone_name}))
			continue

		var axis_angle := Vector3.ZERO
		var angle: float = 0.0

		match bone_name:
			L_SHOULDER:
				axis_angle = Vector3.LEFT
				angle = 0.34
			L_UPPER_ARM:
				axis_angle = Vector3.LEFT
				angle = 0.52
			R_SHOULDER:
				axis_angle = Vector3.RIGHT
				angle = 0.34
			R_UPPER_ARM:
				axis_angle = Vector3.RIGHT
				angle = 0.52
			_:
				_logger.error("This should never happen, this is a major bug!")
				return ERR_BUG
		
		skeleton.set_bone_pose_rotation(bone_idx, Quaternion(axis_angle, angle))

	return OK

func handle_ifacial_mocap(raw_data: PackedByteArray) -> void:
	var data := DataParser.ifacial_mocap(raw_data)

	ik_targets.head.call_deferred(
		"set_rotation_degrees",
		Vector3(data.rotation.x, data.rotation.y, data.rotation.z) - _ik_target_offsets.head.basis.get_euler(EULER_ORDER_XYZ)
	)
	ik_targets.head.call_deferred("set_position", _ik_target_offsets.head.origin + data.position)
	
	# TODO commented out for use later
	# ik_targets.left_hand.position = _ik_target_offsets.left_hand + data.position
	# ik_targets.right_hand.position = _ik_target_offsets.right_hand + data.position
	# ik_targets.hips.position = _ik_target_offsets.hips + data.position
	# ik_targets.left_foot.position = _ik_target_offsets.left_foot + data.position
	# ik_targets.right_foot.position = _ik_target_offsets.right_foot + data.position

	for shape in data.blend_shapes.keys():
		var mappings: Array = _expression_mappings.get(shape, [])
		if mappings.is_empty():
			continue
		
		for mapping in mappings:
			var blend_shape_mapping = _blend_shape_mappings.get(mapping, null)
			if blend_shape_mapping == null:
				continue
			
			blend_shape_mapping.child.set_indexed(blend_shape_mapping.property_path, data.blend_shapes[shape])

func handle_mediapipe(projection: Projection, blend_shapes: Array[MediaPipeCategory]) -> void:
	var tx := Transform3D(projection.inverse())
	
	print("rotation")
	ik_targets.head.call_deferred(
		"set_rotation",
		tx.basis.get_euler() - _ik_target_offsets.head.basis.get_euler()
	)
	_logger.debug("position")
	ik_targets.head.call_deferred(
		"set_position",
		_ik_target_offsets.head.origin + tx.origin
	)
	
	_logger.debug("blend shapes")
	for shape in blend_shapes:
		var mappings: Array = _expression_mappings.get(shape.category_name.to_lower(), [])
		if mappings.is_empty():
			continue
		
		for mapping in mappings:
			var blend_shape_mapping = _blend_shape_mappings.get(mapping, null)
			if blend_shape_mapping == null:
				continue
			
			blend_shape_mapping.child.set_indexed(blend_shape_mapping.property_path, shape.score)

func handle_vtube_studio(raw_data: PackedByteArray) -> void:
	var data := DataParser.vtube_studio(raw_data)
	
	ik_targets.head.call_deferred(
		"set_rotation_degrees",
		Vector3(data.rotation.y, data.rotation.x, data.rotation.z) - _ik_target_offsets.head.basis.get_euler(EULER_ORDER_YXZ)
	)
	ik_targets.head.call_deferred("set_position", _ik_target_offsets.head.origin + data.position)

	for shape in data.blend_shapes:
		var mappings: Array = _expression_mappings.get(shape.k, [])
		if mappings.is_empty():
			continue
		
		for mapping in mappings:
			var blend_shape_mapping = _blend_shape_mappings.get(mapping, null)
			if blend_shape_mapping == null:
				continue
			
			blend_shape_mapping.child.set_indexed(blend_shape_mapping.property_path, shape.v)

func handle_meow_face(raw_data: PackedByteArray) -> void:
	handle_vtube_studio(raw_data)

func handle_open_see_face(raw_data: PackedByteArray) -> void:
	pass
