# renik.cpp
# Copyright 2020 MMMaellon
# Copyright (c) 2014-present Godot Engine contributors (see AUTHORS.md).
# Copyright (c) 2007-2014 Juan Linietsky, Ariel Manzur.
#
# Permission is hereby granted, free of charge, to any person obtaining
# a copy of this software and associated documentation files (the
# "Software"), to deal in the Software without restriction, including
# without limitation the rights to use, copy, modify, merge, publish,
# distribute, sublicense, and/or sell copies of the Software, and to
# permit persons to whom the Software is furnished to do so, subject to
# the following conditions:
#
# The above copyright notice and this permission notice shall be
# included in all copies or substantial portions of the Software.
#
# THE SOFTWARE IS PROVIDED "AS IS", WITHOUT WARRANTY OF ANY KIND,
# EXPRESS OR IMPLIED, INCLUDING BUT NOT LIMITED TO THE WARRANTIES OF
# MERCHANTABILITY, FITNESS FOR A PARTICULAR PURPOSE AND NONINFRINGEMENT.
# IN NO EVENT SHALL THE AUTHORS OR COPYRIGHT HOLDERS BE LIABLE FOR ANY
# CLAIM, DAMAGES OR OTHER LIABILITY, WHETHER IN AN ACTION OF CONTRACT,
# TORT OR OTHERWISE, ARISING FROM, OUT OF OR IN CONNECTION WITH THE
# SOFTWARE OR THE USE OR OTHER DEALINGS IN THE SOFTWARE.

@tool
# class_name for convenience. Not required. The C++ version is just `RenIK`.
class_name RenIK3D
extends Node

const renik_chain_class = preload("./renik_chain.gd")
const renik_limb_class = preload("./renik_limb.gd")
const renik_helper = preload("./renik_helper.gd")

const DEFAULT_THRESHOLD: float = 0.0005
const DEFAULT_LOOP_LIMIT: int = 16

var spine_chain: renik_chain_class = renik_chain_class.new(Vector3(0, 15, -15), 0.5, 0.5, 1, 0)
var limb_arm_left: renik_limb_class = renik_limb_class.new(-0.27777*PI, -0.27777*PI, deg_to_rad(70.0), 0.5, 0.66666,
			deg_to_rad(20.0), deg_to_rad(45.0), 0.33,
			Vector3(deg_to_rad(15.0), 0, deg_to_rad(60.0)),
			Vector3(2.0, -1.5, -1.0))
var limb_arm_right: renik_limb_class = renik_limb_class.new(0.27777*PI, 0.27777*PI, deg_to_rad(-70.0), 0.5, 0.66666,
			deg_to_rad(-20.0), deg_to_rad(45.0), 0.33,
			Vector3(deg_to_rad(15.0), 0, deg_to_rad(-60.0)),
			Vector3(2.0, 1.5, 1.0))
var limb_leg_left: renik_limb_class = renik_limb_class.new(0, PI, 0, 0.25, 0.25, 0, deg_to_rad(45.0), 0.5,
			Vector3(0, 0, PI), Vector3())
var limb_leg_right: renik_limb_class = renik_limb_class.new(0, -PI, 0, 0.25, 0.25, 0, deg_to_rad(45.0), 0.5,
			Vector3(0, 0, -PI), Vector3())

func _init(): # IK DEFAULTS
	leg_pole_offset = leg_pole_offset
	arm_pole_offset = arm_pole_offset

var _is_ready = false
func _ready():
	_is_ready = true
	update_skeleton()
	ready_init()
	head_target_spatial = get_node_or_null(armature_head_target) as Node3D
	hand_left_target_spatial = get_node_or_null(armature_left_hand_target) as Node3D
	hand_right_target_spatial = get_node_or_null(armature_right_hand_target) as Node3D
	hip_target_spatial = get_node_or_null(armature_hip_target) as Node3D
	foot_left_target_spatial = get_node_or_null(armature_left_foot_target) as Node3D
	foot_right_target_spatial = get_node_or_null(armature_right_foot_target) as Node3D

func update_skeleton():
	if _is_ready:
		skeleton = get_node_or_null(armature_skeleton_path) as Skeleton3D
	if skeleton != null:
		limb_arm_left.leaf_id = skeleton.find_bone(armature_left_hand)
		limb_arm_left.lower_id = skeleton.find_bone(armature_left_lower_arm)
		limb_arm_left.upper_id = skeleton.find_bone(armature_left_upper_arm)
		limb_arm_right.leaf_id = skeleton.find_bone(armature_right_hand)
		limb_arm_right.lower_id = skeleton.find_bone(armature_right_lower_arm)
		limb_arm_right.upper_id = skeleton.find_bone(armature_right_upper_arm)
		spine_chain.leaf_bone = skeleton.find_bone(armature_head)
		spine_chain.root_bone = skeleton.find_bone(armature_hip)
		limb_leg_left.leaf_id = skeleton.find_bone(armature_left_foot)
		limb_leg_left.lower_id = skeleton.find_bone(armature_left_lower_leg)
		limb_leg_left.upper_id = skeleton.find_bone(armature_left_upper_leg)
		limb_leg_right.leaf_id = skeleton.find_bone(armature_right_foot)
		limb_leg_right.lower_id = skeleton.find_bone(armature_right_lower_leg)
		limb_leg_right.upper_id = skeleton.find_bone(armature_right_upper_leg)
		spine_chain.init_chain(skeleton)
		limb_arm_left.update(skeleton)
		limb_arm_right.update(skeleton)
		limb_leg_left.update(skeleton)
		limb_leg_right.update(skeleton)

@export var live_preview: bool

@export_group("Armature", "armature_")

var skeleton: Skeleton3D

@export_node_path("Skeleton3D") var armature_skeleton_path: NodePath:
	set(value):
		armature_skeleton_path = value
		update_skeleton()

@export var armature_head: String = "Head"

@export var armature_left_hand: String = "LeftHand"
@export var armature_left_lower_arm: String = "LeftLowerArm"
@export var armature_left_upper_arm: String = "LeftUpperArm"

@export var armature_right_hand: String = "RightHand"
@export var armature_right_lower_arm: String = "RightLowerArm"
@export var armature_right_upper_arm: String = "RightUpperArm"

@export var armature_hip: String = "Hips"

@export var armature_left_foot: String = "LeftFoot"
@export var armature_left_lower_leg: String = "LeftLowerLeg"
@export var armature_left_upper_leg: String = "LeftUpperLeg"

@export var armature_right_foot: String = "RightFoot"
@export var armature_right_lower_leg: String = "RightLowerLeg"
@export var armature_right_upper_leg: String = "RightUpperLeg"

const left_shoulder_enabled: bool = true # Seems to be broken if disabled
const right_shoulder_enabled: bool = true # Seems to be broken if disabled

@export_group("Targets")

var head_target_spatial: Node3D
@export_node_path("Node3D") var armature_head_target: NodePath:
	set(value):
		armature_head_target = value
		if _is_ready:
			head_target_spatial = get_node_or_null(armature_head_target) as Node3D

var hand_left_target_spatial: Node3D
@export_node_path("Node3D") var armature_left_hand_target: NodePath:
	set(value):
		armature_left_hand_target = value
		if _is_ready:
			hand_left_target_spatial = get_node_or_null(armature_left_hand_target) as Node3D

var hand_right_target_spatial: Node3D
@export_node_path("Node3D") var armature_right_hand_target: NodePath:
	set(value):
		armature_right_hand_target = value
		if _is_ready:
			hand_right_target_spatial = get_node_or_null(armature_right_hand_target) as Node3D

var hip_target_spatial: Node3D
@export_node_path("Node3D") var armature_hip_target: NodePath:
	set(value):
		armature_hip_target = value
		if _is_ready:
			hip_target_spatial = get_node_or_null(armature_hip_target) as Node3D

var foot_left_target_spatial: Node3D
@export_node_path("Node3D") var armature_left_foot_target: NodePath:
	set(value):
		armature_left_foot_target = value
		if _is_ready:
			foot_left_target_spatial = get_node_or_null(armature_left_foot_target) as Node3D

var foot_right_target_spatial: Node3D
@export_node_path("Node3D") var armature_right_foot_target: NodePath:
	set(value):
		armature_right_foot_target = value
		if _is_ready:
			foot_right_target_spatial = get_node_or_null(armature_right_foot_target) as Node3D

@export_group("Arm IK Settings", "arm_")

@export_range(-360,360,0.1,"radians") var arm_elbow_direction_offset: float:
	set(value):
		limb_arm_left.roll_offset = value
		limb_arm_right.roll_offset = -value
	get:
		return limb_arm_left.roll_offset

@export_range(0,1,0.001) var arm_upper_arm_twisting: float:
	set(value):
		limb_arm_left.upper_limb_twist = value
		limb_arm_right.upper_limb_twist = value
	get:
		return limb_arm_left.upper_limb_twist

@export_range(-360,360,0.1,"radians") var arm_upper_arm_twist_offset: float:
	set(value):
		limb_arm_left.upper_twist_offset = value
		limb_arm_right.upper_twist_offset = -value
	get:
		return limb_arm_left.upper_twist_offset

@export_range(0,1,0.001) var arm_forearm_twisting: float:
	set(value):
		limb_arm_left.lower_limb_twist = value
		limb_arm_right.lower_limb_twist = value
	get:
		return limb_arm_left.lower_limb_twist

@export_range(-360,360,0.1,"radians") var arm_forearm_twist_offset: float:
	set(value):
		limb_arm_left.lower_twist_offset = value
		limb_arm_right.lower_twist_offset = -value
	get:
		return limb_arm_left.lower_twist_offset

@export_range(-180,180,0.1,"radians") var arm_twist_inflection_point: float:
	set(value):
		limb_arm_left.twist_inflection_point_offset = value
		limb_arm_right.twist_inflection_point_offset = -value
	get:
		return limb_arm_left.twist_inflection_point_offset

@export_range(0,180,0.1,"radians") var arm_twist_overflow: float:
	set(value):
		limb_arm_left.twist_overflow = value
		limb_arm_right.twist_overflow = value
	get:
		return limb_arm_left.twist_overflow


@export_range(0,1,0.001) var arm_shoulder_influence: float = 0.25

#@export_range(-180,180,0.1,"radians")
@export var arm_pole_offset: Quaternion = Quaternion.from_euler(Vector3(deg_to_rad(15), 0, deg_to_rad(60))):
	set(value):
		arm_pole_offset = value
		limb_arm_left.pole_offset = value # Quaternion.from_euler(value)
		limb_arm_right.pole_offset = Quaternion(value.x, -value.y, -value.z, value.w) # Quaternion.from_euler(Vector3(value.x, -value.y, -value.z))

# WARNING: Was multiplied by 10, not 100
@export var arm_target_position_influence: Vector3:
	set(value):
		limb_arm_left.target_position_influence = value
		limb_arm_right.target_position_influence = Vector3(value.x, -value.y, -value.z)
	get:
		return limb_arm_left.target_position_influence

@export_range(0,1,0.001) var arm_target_rotation_influence: float:
	set(value):
		limb_arm_left.target_rotation_influence = value
		limb_arm_right.target_rotation_influence = value
	get:
		return limb_arm_left.target_rotation_influence

var left_shoulder_offset: Quaternion = Quaternion.IDENTITY
var right_shoulder_offset: Quaternion = Quaternion.IDENTITY
#@export_range(-180,180,0.1,"radians")
@export var arm_shoulder_offset: Quaternion:
	set(value):
		arm_shoulder_offset = value
		left_shoulder_offset = value # Quaternion.from_euler(value)
		right_shoulder_offset = Quaternion(value.x, -value.y, -value.z, value.w) # Quaternion.from_euler(Vector3(value.x, -value.y, -value.z))

var left_shoulder_pole_offset: Quaternion = Quaternion.from_euler(Vector3(0,0,deg_to_rad(78.0)))
var right_shoulder_pole_offset: Quaternion = Quaternion.from_euler(Vector3(0,0,deg_to_rad(-78.0)))
#@export_range(-180,180,0.1,"radians")
@export var arm_shoulder_pole_offset: Quaternion:
	set(value):
		arm_shoulder_pole_offset = value
		left_shoulder_pole_offset = value # Quaternion.from_euler(value)
		right_shoulder_pole_offset = Quaternion(value.x, -value.y, -value.z, value.w) # Quaternion.from_euler(Vector3(value.x, -value.y, -value.z))


@export_group("Leg IK Settings", "leg_")

@export_range(-360,360,0.1,"radians") var leg_knee_direction_offset: float:
	set(value):
		limb_leg_left.roll_offset = value
		limb_leg_right.roll_offset = -value
	get:
		return limb_leg_left.roll_offset

@export_range(0,1,0.001) var leg_thigh_twisting: float:
	set(value):
		limb_leg_left.upper_limb_twist = value
		limb_leg_right.upper_limb_twist = value
	get:
		return limb_leg_left.upper_limb_twist

@export_range(-360,360,0.1,"radians") var leg_thigh_twist_offset: float:
	set(value):
		limb_leg_left.upper_twist_offset = value
		limb_leg_right.upper_twist_offset = -value
	get:
		return limb_leg_left.upper_twist_offset

@export_range(0,1,0.001) var leg_lower_leg_twisting: float:
	set(value):
		limb_leg_left.lower_limb_twist = value
		limb_leg_right.lower_limb_twist = value
	get:
		return limb_leg_left.lower_limb_twist

@export_range(-360,360,0.1,"radians") var leg_lower_leg_twist_offset: float:
	set(value):
		limb_leg_left.lower_twist_offset = value
		limb_leg_right.lower_twist_offset = -value
	get:
		return limb_leg_left.lower_twist_offset

@export_range(-180,180,0.1,"radians") var leg_twist_inflection_point: float:
	set(value):
		limb_leg_left.twist_inflection_point_offset = value
		limb_leg_right.twist_inflection_point_offset = -value
	get:
		return limb_leg_left.twist_inflection_point_offset

@export_range(0,180,0.1,"radians") var leg_twist_overflow: float:
	set(value):
		limb_leg_left.twist_overflow = value
		limb_leg_right.twist_overflow = value
	get:
		return limb_leg_left.twist_overflow


@export_group("Leg IK Settings (Advanced)", "leg_")
#@export_range(-180,180,0.1,"radians") var leg_pole_offset: Vector3 = Vector3(0, 0, deg_to_rad(180)):
@export var leg_pole_offset: Quaternion = Quaternion.from_euler(Vector3(0, 0, deg_to_rad(180))):
	set(value):
		leg_pole_offset = value
		limb_leg_left.pole_offset = value # Quaternion.from_euler(value)
		limb_leg_right.pole_offset = Quaternion(value.x, -value.y, -value.z, value.w) # Quaternion.from_euler(Vector3(value.x, -value.y, -value.z))

# WARNING: Was multiplied by 10, not 100
@export var leg_target_position_influence: Vector3:
	set(value):
		limb_leg_left.target_position_influence = value
		limb_leg_right.target_position_influence = Vector3(value.x, -value.y, -value.z)
	get:
		return limb_leg_left.target_position_influence

@export_range(0,1,0.001) var leg_target_rotation_influence: float:
	set(value):
		limb_leg_left.target_rotation_influence = value
		limb_leg_right.target_rotation_influence = value
	get:
		return limb_leg_right.target_rotation_influence

@export_group("Torso IK Settings", "torso_")

@export var torso_spine_curve: Vector3:
	set(value):
		spine_chain.chain_curve_direction = value
	get:
		return spine_chain.chain_curve_direction

@export_range(0,1,0.001) var torso_upper_spine_stiffness: float:
	set(value):
		spine_chain.leaf_influence = value
	get:
		return spine_chain.leaf_influence

@export_range(0,1,0.001) var torso_lower_spine_stiffness: float:
	set(value):
		spine_chain.root_influence = value
	get:
		return spine_chain.root_influence

@export_range(0,1,0.001) var torso_spine_twist_start: float:
	set(value):
		spine_chain.twist_start = value
	get:
		return spine_chain.twist_start

@export_range(0,1,0.001) var torso_spine_twist: float:
	set(value):
		spine_chain.twist_influence = value
	get:
		return spine_chain.twist_influence

'''
func _validate_property(property):
	if (property.name == RENIK_PROPERTY_STRING_HEAD_BONE ||
			property.name == RENIK_PROPERTY_STRING_HIP_BONE ||
			property.name == RENIK_PROPERTY_STRING_HAND_LEFT_BONE ||
			property.name == RENIK_PROPERTY_STRING_LEFT_LOWER_ARM_BONE ||
			property.name == RENIK_PROPERTY_STRING_LEFT_UPPER_ARM_BONE ||
			property.name == RENIK_PROPERTY_STRING_HAND_RIGHT_BONE ||
			property.name == RENIK_PROPERTY_STRING_RIGHT_LOWER_ARM_BONE ||
			property.name == RENIK_PROPERTY_STRING_RIGHT_UPPER_ARM_BONE ||
			property.name == RENIK_PROPERTY_STRING_FOOT_LEFT_BONE ||
			property.name == RENIK_PROPERTY_STRING_LEFT_LOWER_LEG_BONE ||
			property.name == RENIK_PROPERTY_STRING_LEFT_UPPER_LEG_BONE ||
			property.name == RENIK_PROPERTY_STRING_FOOT_RIGHT_BONE ||
			property.name == RENIK_PROPERTY_STRING_RIGHT_LOWER_LEG_BONE ||
			property.name == RENIK_PROPERTY_STRING_RIGHT_UPPER_LEG_BONE):
		if skeleton:
			String names(",")
			for i in range(skeleton.bone_count):
				if (i > 0)
					names += ","
				names += skeleton.get_bone_name(i)

			property.hint = PROPERTY_HINT_ENUM
			property.hint_string = names
		else:
			property.hint = PROPERTY_HINT_NONE
			property.hint_string = ""



'''

func _process(_delta: float) -> void:
	update_ik()

#func _notification (p_what: int) -> void:
#	match p_what:
#		NOTIFICATION_INTERNAL_PROCESS:
#			if !Engine.is_editor_hint() || live_preview:
#				update_ik()


func ready_init ():
	# set the skeleton to the parent if we can
	#var parent: Node = get_parent()
	#armature_skeleton_path = skeleton(parent)
	if not armature_skeleton_path.is_empty(): # && parent:
		armature_skeleton_path = armature_skeleton_path

	armature_head_target = armature_head_target
	armature_hip_target = armature_hip_target
	armature_left_hand_target = armature_left_hand_target
	armature_right_hand_target = armature_right_hand_target
	armature_left_foot_target = armature_left_foot_target
	armature_right_foot_target = armature_right_foot_target

	if Engine.is_editor_hint():
		set_process_internal(true)
		set_physics_process_internal(true)



func enable_solve_ik_every_frame (automatically_update_ik: bool) -> void:
	set_process_internal(automatically_update_ik)


class SpineGlobalTransforms:
	var hipTransform: Transform3D
	var leftArmParentTransform: Transform3D
	var rightArmParentTransform: Transform3D
	var headTransform: Transform3D

	func clear():
		hipTransform = Transform3D()
		leftArmParentTransform = Transform3D()
		rightArmParentTransform = Transform3D()
		headTransform = Transform3D()


func update_ik () -> void:
	if not skeleton:
		return
	var skel_inverse: Transform3D = skeleton.global_transform.affine_inverse()
	var spine_global_transforms: SpineGlobalTransforms = SpineGlobalTransforms.new()
	if not perform_torso_ik(spine_global_transforms):
		return

	if hand_left_target_spatial:
		perform_hand_left_ik(spine_global_transforms.leftArmParentTransform, skel_inverse * hand_left_target_spatial.global_transform)

	if hand_right_target_spatial:
		perform_hand_right_ik(spine_global_transforms.rightArmParentTransform, skel_inverse * hand_right_target_spatial.global_transform)

	if foot_left_target_spatial:
		perform_foot_left_ik(spine_global_transforms.hipTransform, skel_inverse * foot_left_target_spatial.global_transform)
	#elif foot_placement:
	#	perform_foot_left_ik(spine_global_transforms.hipTransform, skel_inverse * placement.interpolated_left_foot)

	if foot_right_target_spatial:
		perform_foot_right_ik(spine_global_transforms.hipTransform, skel_inverse * foot_right_target_spatial.global_transform)
	#elif foot_placement:
	#	perform_foot_right_ik(spine_global_transforms.hipTransform, skel_inverse * placement.interpolated_right_foot)





func apply_ik_map_quat(ik_map: Dictionary, global_parent: Transform3D, apply_order: PackedInt32Array):
	if skeleton:
		for apply_i in apply_order:
			var local_quat: Quaternion = ik_map[apply_i]
			skeleton.set_bone_pose_rotation(apply_i, local_quat)


func apply_ik_map_basis(ik_map: Dictionary, global_parent: Transform3D, apply_order: PackedInt32Array):
	if skeleton:
		for apply_i in apply_order:
			var local_basis: Basis = ik_map[apply_i]
			skeleton.set_bone_pose_rotation(apply_i, local_basis.get_rotation_quaternion())


func get_global_parent_pose(child: int, ik_map: Dictionary, map_global_parent: Transform3D) -> Transform3D:
	var full_transform: Transform3D
	var parent_id: int = skeleton.get_bone_parent(child)
	while parent_id >= 0:
		if ik_map.has(parent_id):
			var super_parent: int = parent_id
			var sup_ik_quat: Quaternion = ik_map[super_parent]
			full_transform = skeleton.get_bone_rest(super_parent) * Transform3D(sup_ik_quat) * full_transform
			while skeleton.get_bone_parent(super_parent) >= 0:
				super_parent = skeleton.get_bone_parent(super_parent)
				if ik_map.has(super_parent):
					sup_ik_quat = ik_map[super_parent]
					full_transform = skeleton.get_bone_rest(super_parent) * Transform3D(sup_ik_quat) * full_transform
				else:
					full_transform = map_global_parent * full_transform
					break

			return full_transform

		parent_id = skeleton.get_bone_parent(parent_id)

	return Transform3D()


func perform_torso_ik (spine_transforms: SpineGlobalTransforms):
	if head_target_spatial && skeleton && spine_chain.is_valid():
		var skel_inverse: Transform3D = skeleton.global_transform.affine_inverse()
		var headGlobalTransform: Transform3D = skel_inverse * head_target_spatial.global_transform
		var hipTransform: Transform3D
		var hip: int = spine_chain.root_bone
		var head: int = spine_chain.leaf_bone
		if hip_target_spatial:
			hipTransform = hip_target_spatial.global_transform
		#else if hip_placement:
		#	hip_target_spatial = placement.interpolated_hip
		# FIXME: Why skeleton.get_bone_rest(hip).basis
		var hipGlobalTransform: Transform3D = skel_inverse * hipTransform * Transform3D(skeleton.get_bone_rest(hip).basis)
		var delta: Vector3 = hipGlobalTransform.origin + hipGlobalTransform.basis * (spine_chain.joints[0].relative_prev) - headGlobalTransform.origin
		var fullLength: float = spine_chain.total_length
		if delta.length() > fullLength:
			hipGlobalTransform.origin = (headGlobalTransform.origin + (delta.normalized() * fullLength) - hipGlobalTransform.basis * (spine_chain.joints[0].relative_prev))

		var ik_map: Dictionary = solve_ifabrik(
				spine_chain,
				hipGlobalTransform * Transform3D(skeleton.get_bone_rest(hip).basis.inverse()),
				headGlobalTransform, DEFAULT_THRESHOLD, DEFAULT_LOOP_LIMIT)
		#skeleton.set_bone_global_pose_override(
		#    hip, hipGlobalTransform, 1.0f, true)
		skeleton.set_bone_pose_rotation(hip, hipGlobalTransform.basis.get_rotation_quaternion())
		skeleton.set_bone_pose_position(hip, hipGlobalTransform.origin)

		apply_ik_map_quat(ik_map, hipGlobalTransform, bone_id_order_spine(spine_chain))

		# Keep Hip and Head as global poses tand then apply them as global pose
		# override
		var neckQuaternion: Quaternion = Quaternion.IDENTITY
		var parent_bone: int = skeleton.get_bone_parent(head)
		while parent_bone != -1:
			neckQuaternion = skeleton.get_bone_pose_rotation(parent_bone) * neckQuaternion
			parent_bone = skeleton.get_bone_parent(parent_bone)

		#skeleton.set_bone_global_pose_override(
		#    head, headGlobalTransform, 1.0f, true)
		skeleton.set_bone_pose_rotation(head, neckQuaternion.inverse() * headGlobalTransform.basis.get_rotation_quaternion())

		# Calculate and return the parent bone position for the arms
		var left_global_parent_pose: Transform3D = Transform3D()
		var right_global_parent_pose: Transform3D = Transform3D()
		if limb_arm_left != null:
			left_global_parent_pose = get_global_parent_pose(
					limb_arm_left.upper_id, ik_map, hipGlobalTransform)

		if limb_arm_right != null:
			right_global_parent_pose = get_global_parent_pose(
					limb_arm_right.upper_id, ik_map, hipGlobalTransform)

		spine_transforms.hipTransform = hipGlobalTransform
		spine_transforms.leftArmParentTransform = left_global_parent_pose
		spine_transforms.rightArmParentTransform = right_global_parent_pose
		spine_transforms.headTransform= headGlobalTransform
		return true

	spine_transforms.clear()
	return false


func perform_hand_left_ik (global_parent: Transform3D, target: Transform3D) -> void:
	if (hand_left_target_spatial && skeleton &&
			limb_arm_left.is_valid_in_skeleton(skeleton)):
		var root: Transform3D = global_parent #  skeleton.global_transform * global_parent
		var rootBone: int = skeleton.get_bone_parent(limb_arm_left.upper_id)
		if rootBone >= 0:
			if left_shoulder_enabled:
				# var shoulderParent: int = skeleton.get_bone_parent(rootBone)
				# if shoulderParent >= 0:
				# 	root = root * skeleton.get_bone_global_pose(shoulderParent)
				#
				root = root * skeleton.get_bone_rest(rootBone)
				var targetVector: Vector3 = root.affine_inverse() * (target.origin)
				var offsetQuat: Quaternion = left_shoulder_offset
				var poleOffset: Quaternion = left_shoulder_pole_offset
				var poleOffsetScaled: Quaternion = poleOffset.slerp(Quaternion(), 1 - arm_shoulder_influence)
				var quatAlignToTarget: Quaternion = poleOffsetScaled * renik_helper.align_vectors(
								Vector3(0, 1, 0), poleOffset.inverse() * (offsetQuat.inverse() * (targetVector))
								).slerp(Quaternion(), 1 - arm_shoulder_influence)
				var customPose: Transform3D = Transform3D(offsetQuat * quatAlignToTarget, Vector3())
				skeleton.set_bone_pose_rotation(rootBone, skeleton.get_bone_rest(rootBone).basis.get_rotation_quaternion() * offsetQuat * quatAlignToTarget)
				root = root * customPose

			# root = skeleton.global_transform *
			# skeleton.get_bone_global_pose(rootBone)

		apply_ik_map_basis(solve_trig_ik_redux(limb_arm_left, root, target), root, bone_id_order_limb(limb_arm_left))


func perform_hand_right_ik (global_parent: Transform3D, target: Transform3D) -> void:
	if (hand_right_target_spatial && skeleton &&
			limb_arm_right.is_valid_in_skeleton(skeleton)):
		var root: Transform3D = global_parent
		var rootBone: int = skeleton.get_bone_parent(limb_arm_right.upper_id)
		if rootBone >= 0:
			if right_shoulder_enabled:
				# var shoulderParent: int = skeleton.get_bone_parent(rootBone)
				# if shoulderParent >= 0:
				# 	root = root * skeleton.get_bone_global_pose(shoulderParent)
				#
				root = root * skeleton.get_bone_rest(rootBone)
				var targetVector: Vector3 = root.affine_inverse() * (target.origin)
				var offsetQuat: Quaternion = right_shoulder_offset
				var poleOffset: Quaternion = right_shoulder_pole_offset
				var poleOffsetScaled: Quaternion = poleOffset.slerp(Quaternion(), 1 - arm_shoulder_influence)
				var quatAlignToTarget: Quaternion = poleOffsetScaled * renik_helper.align_vectors(
								Vector3(0, 1, 0), poleOffset.inverse() * (offsetQuat.inverse() * (targetVector))
								).slerp(Quaternion(), 1 - arm_shoulder_influence)
				var customPose: Transform3D = Transform3D(offsetQuat * quatAlignToTarget, Vector3())
				skeleton.set_bone_pose_rotation(rootBone, skeleton.get_bone_rest(rootBone).basis.get_rotation_quaternion() * offsetQuat * quatAlignToTarget)
				root = root * customPose

			# root = skeleton.global_transform *
			# skeleton.get_bone_global_pose(rootBone)

		apply_ik_map_basis(solve_trig_ik_redux(limb_arm_right, root, target), root, bone_id_order_limb(limb_arm_right))


func perform_foot_left_ik (global_parent: Transform3D, target: Transform3D) -> void:
	if skeleton && limb_leg_left.is_valid_in_skeleton(skeleton):
		var root: Transform3D = global_parent
		apply_ik_map_basis(solve_trig_ik_redux(limb_leg_left, root, target), global_parent, bone_id_order_limb(limb_leg_left))


func perform_foot_right_ik (global_parent: Transform3D, target: Transform3D) -> void:
	if skeleton && limb_leg_right.is_valid_in_skeleton(skeleton):
		var root: Transform3D = global_parent
		# var root: Transform3D = skeleton.global_transform
		# var rootBone: int =
		# skeleton.get_bone_parent(limb_leg_right.upper_bone)
		# if (rootBone >= 0):
		#     root = root * skeleton.get_bone_global_pose(rootBone)
		#
		apply_ik_map_basis(solve_trig_ik_redux(limb_leg_right, root, target), global_parent, bone_id_order_limb(limb_leg_right))


# IK SOLVING

func bone_id_order_spine (chain: renik_chain_class) -> PackedInt32Array:
	var ret: PackedInt32Array
	for joint in spine_chain.joints:
		# the last one's rotation is defined by the leaf position not a
		# joint so we skip it
		# FIXME: It's not actually skipping the last.
		ret.push_back(joint.id)

	return ret


func bone_id_order_limb (limb: renik_limb_class) -> PackedInt32Array:
	var ret: PackedInt32Array
	ret.push_back(limb.upper_id)
	ret.append_array(limb.upper_extra_bone_ids)
	ret.push_back(limb.lower_id)
	ret.append_array(limb.lower_extra_bone_ids)
	ret.push_back(limb.leaf_id)
	return ret


func solve_trig_ik(limb: renik_limb_class, root: Transform3D, target: Transform3D) -> Dictionary:
	var map: Dictionary

	if limb.is_valid():
		# There's no way to find a valid upperId if any of the other Id's are invalid, so we only check upperId
		var upperVector: Vector3 = limb.lower.origin
		var lowerVector: Vector3 = limb.leaf.origin
		var upperRest: Quaternion = limb.upper.basis.get_rotation_quaternion()
		var lowerRest: Quaternion = limb.lower.basis.get_rotation_quaternion()
		var upper: Quaternion = upperRest.inverse()
		var lower: Quaternion = lowerRest.inverse()
		# The true root of the limb is the povar where: int the upper bone starts
		var trueRoot: Transform3D = root.translated_local(limb.upper.origin)
		var localTarget: Transform3D = trueRoot.affine_inverse() * target

		# First we offset the pole
		upper = upper * limb.pole_offset.normalized() # pole_offset is a euler because
												# that's more human readable
		upper = upper.normalized()
		lower = lower.normalized()
		# Then we line up the limb with our target
		var targetVector: Vector3 = limb.pole_offset.inverse() * (localTarget.origin)
		upper = upper * renik_helper.align_vectors(upperVector, targetVector)
		# Then we calculate how much we need to bend so we don't extend past the
		# target Law of Cosines
		var upperLength: float = upperVector.length()
		var lowerLength: float = lowerVector.length()
		var upperLength2: float = upperVector.length_squared()
		var lowerLength2: float = lowerVector.length_squared()
		var targetDistance: float = targetVector.length()
		var targetDistance2: float = targetVector.length_squared()
		var upperAngle: float = renik_helper.safe_acos((upperLength2 + targetDistance2 - lowerLength2) / (2 * upperLength * targetDistance))
		var lowerAngle: float = renik_helper.safe_acos((upperLength2 + lowerLength2 - targetDistance2) / (2 * upperLength * lowerLength)) - PI
		var bendAxis: Vector3 = renik_helper.get_perpendicular_vector(upperVector) # TODO figure out how to set this automatically to the right axis
		var upperBend: Quaternion = Quaternion(bendAxis, upperAngle)
		var lowerBend: Quaternion = Quaternion(bendAxis, lowerAngle)
		upper = upper * upperBend
		lower = lower * lowerBend
		# Then we roll the limb based on the target position
		var targetRestPosition: Vector3 = upperVector.normalized() * (upperLength + lowerLength)
		var rollVector: Vector3 = upperBend.inverse() * (upperVector).normalized()
		var positionalRollAmount: float = limb.target_position_influence.dot(targetRestPosition - targetVector)
		var positionRoll: Quaternion = Quaternion(rollVector, positionalRollAmount)
		upper = upper.normalized() * positionRoll
		# And the target rotation

		var leafRest: Quaternion = limb.leaf.basis.get_rotation_quaternion()
		var armCombined: Quaternion = (upperRest * upper * lowerRest * lower).normalized()
		var targetQuat: Quaternion = localTarget.basis.get_rotation_quaternion() * leafRest
		var leaf: Quaternion = ((armCombined * leafRest).inverse() * targetQuat).normalized()
		# if we had a plane along the roll vector we can project the leaf and lower
		# limb on it to see which direction we need to roll to reduce the angle
		# between the two
		var restVector: Vector3 = (armCombined) * (lowerVector).normalized()
		var leafVector: Vector3 = leaf * (restVector).normalized()
		var restRejection: Vector3 = renik_helper.vector_rejection(restVector.normalized(), rollVector)
		var leafRejection: Vector3 = renik_helper.vector_rejection(leafVector.normalized(), rollVector)
		var directionalRollAmount: float = renik_helper.safe_acos(restRejection.normalized().dot(leafRejection.normalized())) * limb.target_rotation_influence
		var directionality: Vector3 = restRejection.normalized().cross(leafRejection.normalized())
		var check: float = directionality.dot(targetVector.normalized())
		if check > 0:
			directionalRollAmount *= -1

		var directionalRoll: Quaternion = Quaternion(rollVector, directionalRollAmount)
		upper = upper * directionalRoll

		armCombined = (upperRest * upper * lowerRest * lower).normalized()
		leaf = ((armCombined * leafRest).inverse() * targetQuat).normalized()
		# And finally add the twisting
		#  old way: var lowerTwist: Quaternion = (align_vectors(lowerVector,
		#  leafRest * (leaf * (lowerVector))).inverse() * (leafRest *
		#  leaf)).slerp(Quaternion(), 1 - limb.lower_limb_twist).normalized()
		var twist: Vector3 = (leafRest * leaf).get_euler()
		var lowerTwist: Quaternion = Quaternion.from_euler((leafRest * leaf).get_euler() * lowerVector.normalized() * (limb.lower_limb_twist))
		lower = lower * lowerTwist
		leaf = (lowerTwist * leafRest).inverse() * leafRest * leaf

		var upperTwist: Quaternion = Quaternion.from_euler(twist * upperVector.normalized() * (limb.upper_limb_twist * limb.lower_limb_twist))
		upper = upper * upperTwist
		lower = (upperTwist * lowerRest).inverse() * lowerRest * lower

		# save data and return
		map[limb.upper_id] = upper
		map[limb.lower_id] = lower
		map[limb.leaf_id] = leaf

	return map


func trig_angles(side1: Vector3, side2: Vector3, side3: Vector3) -> Vector2:
	# Law of Cosines
	var length1Squared: float = side1.length_squared()
	var length2Squared: float = side2.length_squared()
	var length3Squared: float = side3.length_squared()
	var length1: float = sqrt(length1Squared) * 2
	var length2: float = sqrt(length2Squared)
	var length3: float = sqrt(length3Squared) # multiply by 2 here to save on having to multiply by 2 twice later
	var angle1: float = renik_helper.safe_acos(
			(length1Squared + length3Squared - length2Squared) / (length1 * length3))
	var angle2: float = PI - renik_helper.safe_acos((length1Squared + length2Squared - length3Squared) / (length1 * length2))
	return Vector2(angle1, angle2)


func solve_trig_ik_redux(limb: renik_limb_class, root: Transform3D, target: Transform3D) -> Dictionary:
	var map: Dictionary
	if limb.is_valid():
		# The true root of the limb is the point where the upper bone starts
		var trueRoot: Transform3D = root.translated_local(limb.upper.origin)
		var localTarget: Transform3D = trueRoot.affine_inverse() * target

		var full_upper: Transform3D = limb.upper
		#.translated_local(Vector3(0, limb.upper_extra_bones.origin.length(), 0))
		var full_lower: Transform3D = limb.lower
		#.translated_local(Vector3(0, limb.lower_extra_bones.origin.length(), 0))

		# The Triangle
		var upperVector: Vector3 = (limb.upper_extra_bones * limb.lower).origin
		var lowerVector: Vector3 = (limb.lower_extra_bones * limb.leaf).origin
		var targetVector: Vector3 = localTarget.origin
		var normalizedTargetVector: Vector3 = targetVector.normalized()
		var limbLength: float = upperVector.length() + lowerVector.length()
		if targetVector.length() > upperVector.length() + lowerVector.length():
			targetVector = normalizedTargetVector * limbLength

		var angles: Vector2 = trig_angles(upperVector, lowerVector, targetVector)

		# The local x-axis of the upper limb is axis along which the limb will bend
		# We take into account how the pole offset and alignment with the target
		# vector will affect this axis
		var startingPole: Vector3 = limb.pole_offset * (
				Vector3(0, 1, 0)) # the opposite of this vector is where the pole is
		var jointAxis: Vector3 = renik_helper.align_vectors(startingPole, targetVector) * (limb.pole_offset * (Vector3(1, 0, 0)))

		# #We then find how far away from the rest position the leaf is and use
		# that to change the rotational axis more.
		var leafRestVector: Vector3 = full_upper.basis * (full_lower * (limb.leaf.origin))
		var positionalOffset: float = limb.target_position_influence.dot(targetVector - leafRestVector)
		jointAxis = jointAxis.rotated(normalizedTargetVector, positionalOffset + limb.roll_offset)

		# Leaf Rotations... here we go...
		# Let's always try to avoid having the leaf intersect the lowerlimb
		# First we find the a vector that corresponds with the direction the leaf
		# and lower limbs are pointing local to the true root
		var localLeafVector: Vector3 = localTarget.basis * (Vector3(0, 1, 0)) # y axis of the target
		var localLowerVector: Vector3 = normalizedTargetVector.rotated(jointAxis, angles.x - angles.y).normalized()
		# We then take the vector rejections of the leaf and lower limb against the
		# target vector A rejection is the opposite of a projection. We use the
		# target vector because that's our axis of rotation for the whole limb. We
		# then turn the whole arm along the target vector based on how close the
		# rejections are We scale the amount we rotate with the rotation influence
		# setting and the angle between the leaf and lower vector so if the arm is
		# mostly straight, we rotate less
		var leafRejection: Vector3 = renik_helper.vector_rejection(localLeafVector, normalizedTargetVector)
		var lowerRejection: Vector3 = renik_helper.vector_rejection(localLowerVector, normalizedTargetVector)
		var jointRollAmount: float = (leafRejection.angle_to(lowerRejection)) * limb.target_rotation_influence
		jointRollAmount *= absf(localLeafVector.cross(localLowerVector).dot(normalizedTargetVector))
		if leafRejection.cross(lowerRejection).dot(normalizedTargetVector) > 0:
			jointRollAmount *= -1

		jointAxis = jointAxis.rotated(normalizedTargetVector, jointRollAmount)
		var totalRoll: float = jointRollAmount + positionalOffset + limb.roll_offset

		# Add a little twist
		# We align the leaf's y axis with the lower limb's y-axis and see how far
		# off the x-axis is from the joint axis to calculate the twist.
		var leafX: Vector3 = renik_helper.align_vectors(
						localLeafVector.rotated(normalizedTargetVector, jointRollAmount),
						localLowerVector.rotated(normalizedTargetVector, jointRollAmount)
						) * (localTarget.basis * (Vector3(1, 0, 0)))
		var rolledJointAxis: Vector3 = jointAxis.rotated(localLowerVector, -totalRoll)
		var lowerZ: Vector3 = rolledJointAxis.cross(localLowerVector)
		var twistAngle: float = leafX.angle_to(rolledJointAxis)
		if leafX.dot(lowerZ) > 0:
			twistAngle *= -1


		var inflectionPoint: float = (PI if twistAngle > 0 else -PI) - limb.twist_inflection_point_offset
		var overflowArea: float = limb.overflow_state * limb.twist_overflow
		var inflectionDistance: float = twistAngle - inflectionPoint

		if absf(inflectionDistance) < limb.twist_overflow:
			if limb.overflow_state == 0:
				limb.overflow_state = 1 if inflectionDistance < 0 else -1

		else:
			limb.overflow_state = 0


		inflectionPoint += overflowArea
		if twistAngle > 0 && twistAngle > inflectionPoint:
			twistAngle -= TAU # Change to complement angle
		elif twistAngle < 0 && twistAngle < inflectionPoint:
			twistAngle += TAU # Change to complement angle


		var lowerTwist: float = twistAngle * limb.lower_limb_twist
		var upperTwist: float = lowerTwist * limb.upper_limb_twist + limb.upper_twist_offset - totalRoll
		lowerTwist += limb.lower_twist_offset - 2 * limb.roll_offset - positionalOffset - jointRollAmount

		jointAxis = jointAxis.rotated(normalizedTargetVector, twistAngle * limb.target_rotation_influence)

		# Rebuild the rotations
		var upperJointVector: Vector3 = normalizedTargetVector.rotated(jointAxis, angles.x)
		var rolledLowerJointAxis: Vector3 = Vector3(1, 0, 0).rotated(Vector3(0, 1, 0), -limb.roll_offset)
		var lowerJointVector: Vector3 = Vector3(0, 1, 0).rotated(rolledLowerJointAxis, angles.y)
		var twistedJointAxis: Vector3 = jointAxis.rotated(upperJointVector, upperTwist)
		var upperBasis: Basis = Basis(twistedJointAxis, upperJointVector, twistedJointAxis.cross(upperJointVector))
		var lowerBasis: Basis = Basis(rolledLowerJointAxis, lowerJointVector, rolledLowerJointAxis.cross(lowerJointVector))
		lowerBasis = lowerBasis.transposed()
		lowerBasis = lowerBasis * Basis(Vector3(0, 1, 0), lowerTwist)
		lowerBasis = lowerBasis.rotated(Vector3(0, 1, 0), -upperTwist)

		var upperTransform: Basis = ((full_upper.basis.inverse() * upperBasis).orthonormalized())
		var lowerTransform: Basis = ((full_lower.basis.inverse() * lowerBasis).orthonormalized())
		var leafTransform: Basis = (limb.leaf.basis.inverse() * (upperBasis * lowerBasis).inverse() * localTarget.basis * limb.leaf.basis)
		map[limb.upper_id] = upperTransform
		for bone_id in limb.upper_extra_bone_ids:
			map[bone_id] = Basis()

		map[limb.lower_id] = lowerTransform # limb.upper_extra_bones.affine_inverse() * (full_lower.basis.inverse() * lowerBasis)
		for bone_id in limb.lower_extra_bone_ids:
			map[bone_id] = Basis()

		map[limb.leaf_id] = leafTransform

	return map


func solve_ifabrik(chain: renik_chain_class, root: Transform3D, target: Transform3D, threshold: float, loopLimit: int) -> Dictionary:
	var map: Dictionary
	if chain.is_valid(): # if the chain is valid there's at least one joint in the chain and there's one bone between it and the root
		var joints: Array[renik_chain_class.Joint] = chain.joints # just so I don't have to call it all the time
		var trueRoot: Transform3D = root.translated_local(joints[0].relative_prev)
		# how the change in the target would affect the chain if the chain was parented to the target instead of the root
		var targetDelta: Transform3D = target * chain.rest_leaf.affine_inverse()
		var trueRelativeTarget: Transform3D = trueRoot.affine_inverse() * target
		var alignToTarget: Quaternion = renik_helper.align_vectors(
				chain.rest_leaf.origin - joints[0].relative_prev,
				trueRelativeTarget.origin)

		var heightDiff: float = (chain.rest_leaf.origin - joints[0].relative_prev).length() - trueRelativeTarget.origin.length()
		heightDiff = maxf(0, heightDiff)
		# The angle root is rotated  to point at the target
		var prebentRoot: Transform3D = Transform3D(trueRoot.basis * Basis(alignToTarget), trueRoot.origin).translated_local(
				(chain.chain_curve_direction * chain.total_length * heightDiff) - joints[0].relative_prev)

		var globalJointPoints: PackedVector3Array

		# We generate the starting points
		# Here is where we take into account root and target influences and the
		# prebend vector
		var relativeJoint: Vector3 = joints[0].relative_prev
		for joint_i in range(1, len(joints)):
			relativeJoint = relativeJoint + joints[joint_i].relative_prev
			var prebentJoint: Vector3 = prebentRoot * (
					relativeJoint) # if you rotated the root around the true root so
									# that the whole chain was pointing to the leaf and
									# then you moved everything along the prebend vector
			var rootJoint: Vector3 = root * relativeJoint # if you moved the joint with the root
			var leafJoint: Vector3 = targetDelta * relativeJoint # if you moved the joint with the leaf
			prebentJoint = prebentJoint.lerp(rootJoint, joints[joint_i].root_influence)
			prebentJoint = prebentJoint.lerp(
					leafJoint, joints[joint_i].leaf_influence) # leaf influence dominates
			globalJointPoints.push_back(prebentJoint)


		# We then do regular FABRIK
		for i in range(loopLimit):
			var lastJoint: Vector3 = target.origin
			# Backward
			for j in range(len(joints) - 1, 0, -1):
				# we skip the first joint because we're not allowed to move that joint
				var delta: Vector3 = globalJointPoints[j - 1] - lastJoint
				delta = delta.normalized() * joints[j].next_distance
				globalJointPoints.set(j - 1, lastJoint + delta)
				lastJoint = globalJointPoints[j - 1]
			lastJoint = trueRoot.origin # the root joint

			# Forwards
			for j in range(1, len(joints)):
				# we skip the first joint because we're not allowed to move that joint
				var delta: Vector3 = globalJointPoints[j - 1] - lastJoint
				delta = delta.normalized() * joints[j].prev_distance
				globalJointPoints.set(j - 1, lastJoint + delta)
				lastJoint = globalJointPoints[j - 1]

			var error: float = (lastJoint - trueRoot.origin).length()
			if error < threshold:
				break

		# Add a little twist
		# We align the leaf's y axis with the rest_leaf's y-axis and see how far
		# off the x-axes are to calculate the twist.
		trueRelativeTarget = trueRelativeTarget.orthonormalized()
		var leafX: Vector3 = renik_helper.align_vectors(
						trueRelativeTarget.basis * (Vector3(0, 1, 0)),
						chain.rest_leaf.basis * (Vector3(0, 1, 0))
						).normalized() * (trueRelativeTarget.basis * (Vector3(1, 0, 0)))
		var restX: Vector3 = chain.rest_leaf.basis * (Vector3(1, 0, 0))
		var maxTwist: float = leafX.angle_to(restX)
		if leafX.cross(restX).dot(Vector3(0, 1, 0)) > 0:
			maxTwist *= -1

		# Convert everything to quaternions and store it in the map
		var parentRot: Quaternion = root.basis.get_rotation_quaternion()
		var parentPos: Vector3 = trueRoot.origin
		var prevTwist: Quaternion
		globalJointPoints.push_back(target.origin)
		for joint_i in range(len(joints)):
			# the last one's rotation is defined by the leaf position not a
			# joint so we skip it
			# FIXME: Not actually skipping the last.
			var pose: Quaternion = renik_helper.align_vectors(
					Vector3(0, 1, 0),
					Transform3D(parentRot * joints[joint_i].rotation, parentPos)
							.affine_inverse()
							 * (globalJointPoints[joint_i])) # offset by one because joints has one extra element
			var twist: Quaternion = Quaternion(Vector3(0, 1, 0), maxTwist * joints[joint_i].twist_influence)
			pose = prevTwist.inverse() * joints[joint_i].rotation * pose * twist
			prevTwist = twist
			map[joints[joint_i].id] = pose
			parentRot = parentRot * pose
			parentPos = globalJointPoints[joint_i]

	return map


func calculate_bone_chain (root: int, leaf: int) -> PackedInt32Array:
	var chain: PackedInt32Array
	var b: int = leaf
	chain.push_back(b)
	if skeleton:
		while b >= 0 && b != root:
			b = skeleton.get_bone_parent(b)
			chain.push_back(b)
		if b < 0:
			chain.clear()
			chain.push_back(leaf)
		else:
			chain.reverse()
	return chain
