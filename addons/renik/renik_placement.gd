# renik_placement.cpp
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
# class_name for convenience. Not required.
class_name RenIKPlacement3D
extends Node3D
const renik_helper = preload("./renik_helper.gd")
const renik_gait_class = preload("./renik_placement_gait.gd")

# -2 is falling, -1 is transitioning to standing, 0 is stand state, 1
# is transitioning to stepping, 2 is stepping
const FALLING: int = 0
const STANDING_TRANSITION: int = -1
const STANDING: int = 1
const STEPPING_TRANSITION: int = -2
const STEPPING: int = 2
const BACKSTEPPING_TRANSITION: int = -3
const BACKSTEPPING: int = 3
const LAYING_TRANSITION: int = -4
const LAYING: int = 4
const STRAFING_TRANSITION: int = -5
const STRAFING: int = 5
const OTHER_TRANSITION: int = -6
const OTHER: int = 6

const LOOP_GROUND_IN: int = 0
const LOOP_LIFT: int = 1
const LOOP_APEX_IN: int = 2
const LOOP_APEX_OUT: int = 3
const LOOP_DROP: int = 4
const LOOP_GROUND_OUT: int = 5

@export var forward_gait: renik_gait_class:
	set(value):
		forward_gait = value
		set_default_gaits()

@export var backward_gait: renik_gait_class:
	set(value):
		backward_gait = value
		set_default_gaits()

@export var sideways_gait: renik_gait_class:
	set(value):
		sideways_gait = value
		set_default_gaits()

func set_default_gaits():
	if forward_gait == null:
		forward_gait = renik_gait_class.new(
				1, 0.5 # speed min speed max
				,
				5, 10, 5, 10, 5, 5, 5, 5,
				0 # ground time min then base and scalar for lift time, apex in time,
					# apex out time, and drop time
				,
				PI / 2, PI / 4,
				PI / 3 # tip toe distance scalar, speed scalar, and angle max
				,
				0.0, 0.4, 0.70,
				PI /
						2 # lift vertical, vertical scalar, horizontal scalar, and angle
				,
				0.0, 0.1, PI / 8 # apex vertical, vertical scalar, angle
				,
				0.0, 0.05, 0.25, PI / -8 # drop vertical, vertical scalar, angle
				,
				0.05, 0.4, 0.85) # contact ease, ease scalar, and scaling ease
		forward_gait.resource_name = "ForwardGait"
	if backward_gait == null:
		backward_gait = renik_gait_class.new(
				0.5, 0.75, 5, 5, 5, 10, 5, 10, 5, 5, 5, 0, 0, 0, 0.025, 0.1, 0.33,
				PI / -8, 0.1, 0.1, PI / 8, 0.0, 0.1, 0.25, PI / 8,
				0.1, 0.4, 0.85)
		backward_gait.resource_name = "BackwardGait"
	if sideways_gait == null:
		sideways_gait = renik_gait_class.new(
				0.75, 0.75, 10, 5, 5, 10, 5, 10, 5, 5, 5, 0, 0, 0, 0.05, 0.05, 0.2,
				0.0, 0.01, 0.1, PI / 8, 0.01, 0.05, 0.25, 0.0, 0.1, 0.4, 0.85)
		sideways_gait.resource_name = "SidewaysGait"

# Calculated using bones.
var spine_length: float = 1
var left_leg_length: float = 1
var right_leg_length: float = 1
var hip_offset: Vector3

@export var left_foot_length: float = 0.125
@export var right_foot_length: float = 0.125
# Hip Placement Adjustments
@export var crouch_ratio: float = 0.4 # Crouching means bending over at the hip while
							# keeping the spine straight
@export var hunch_ratio: float = 0.6 # Hunching means bending over by arching the spine

@export var hip_follow_head_influence: float = 0.25

# Foot Placement Adjustments - Only takes effect when there are no foot
# targets These are values when at the slowest walk speed
@export var floor_offset: float = 0.05
@export var raycast_allowance: float = 0.15 # how far past the max length of the limb
								# we'll still consider close enough
@export var min_threshold: float = 0.025
@export var max_threshold: float = 0.05 # when all scaling stops and the legs just move faster
@export var min_transition_speed: float = 0.04
@export var rotation_threshold: float = PI / 4.0
@export var balance_threshold: float = 0.03
# distance between hips and head that we'll call the center of balance. 0 is at head
@export var center_of_balance_position: float = 0.5

@export var dangle_ratio: float = 0.9
@export var dangle_stiffness: float = 3
@export var dangle_angle: float = PI / 8
@export var dangle_follow_head: float = 0.5
@export var left_hip_offset: Vector3
@export var right_hip_offset: Vector3

# Everything scales logarithmically
@export var strafe_angle_limit: float = cos(deg_to_rad(30.0))
@export var step_pace: float = 0.015

var prev_hip: Transform3D # relative to world
var prev_left_foot: Transform3D # relative to world
var prev_right_foot: Transform3D # relative to world

var target_hip: Transform3D # relative to world
var target_left_foot: Transform3D # relative to world
var target_right_foot: Transform3D # relative to world

var target_foot_is_valid: bool = false
var target_hip_is_valid: bool = false

# Saracen: these are used between the physics updates to provide smooth local
# interpolation of leg movement.
var interpolated_hip: Transform3D
var interpolated_left_foot: Transform3D
var interpolated_right_foot: Transform3D


func _notification (p_what: int) -> void:
	match p_what:
		NOTIFICATION_INTERNAL_PROCESS:
			if !Engine.is_editor_hint() || live_preview:
				interpolate_transforms(Engine.get_physics_interpolation_fraction())

		NOTIFICATION_INTERNAL_PHYSICS_PROCESS:
			if !Engine.is_editor_hint() || live_preview:
				update_placement(get_physics_process_delta_time())


var _is_ready = false
func _ready():
	_is_ready = true
	update_skeleton()
	set_default_gaits()
	head_target_spatial = get_node_or_null(armature_head_target) as Node3D
	hip_target_spatial = get_node_or_null(armature_hip_target) as Node3D
	foot_left_target_spatial = get_node_or_null(armature_left_foot_target) as Node3D
	foot_right_target_spatial = get_node_or_null(armature_right_foot_target) as Node3D
	set_process_internal(true)
	set_physics_process_internal(true)

func update_skeleton():
	if _is_ready:
		skeleton = get_node_or_null(armature_skeleton_path) as Skeleton3D
	if skeleton != null:
		left_foot_id = skeleton.find_bone(armature_left_foot)
		right_foot_id = skeleton.find_bone(armature_right_foot)
		calculate_leg_lengths()
		calculate_hip_offset()

@export var live_preview: bool

@export_group("Armature", "armature_")

var skeleton: Skeleton3D
var left_foot_id: int
var right_foot_id: int

@export_node_path("Skeleton3D") var armature_skeleton_path: NodePath:
	set(value):
		armature_skeleton_path = value
		update_skeleton()

@export var armature_head: String = "Head"

@export var armature_hip: String = "Hips"

@export var armature_left_foot: String = "LeftFoot"
@export var armature_left_lower_leg: String = "LeftLowerLeg"
@export var armature_left_upper_leg: String = "LeftUpperLeg"

@export var armature_right_foot: String = "RightFoot"
@export var armature_right_lower_leg: String = "RightLowerLeg"
@export var armature_right_upper_leg: String = "RightUpperLeg"

@export var enable_left_foot_placement: bool = true
@export var enable_right_foot_placement: bool = true
@export var enable_hip_placement: bool = false

@export_group("Targets")

var head_target_spatial: Node3D
@export_node_path("Node3D") var armature_head_target: NodePath:
	set(value):
		armature_head_target = value
		if _is_ready:
			head_target_spatial = get_node_or_null(armature_head_target) as Node3D

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


const foot_basis_offset: Basis = Basis(Vector3(-1, 0, 0), Vector3(0, 0, 1), Vector3(0, 1, 0))

var fall_override: bool = false
var prone_override: bool = false
var walk_state: int = 0
var walk_transition_progress: float = 0
var step_progress: float = 0
var prevHead: Vector3
var collision_mask: int = 1 # the first bit is on but all others are off
var collide_with_areas: bool = false
var collide_with_bodies: bool = true

# Standing
var left_stand: Transform3D
var right_stand: Transform3D
var left_stand_local: Transform3D # local to ground
var right_stand_local: Transform3D # local to ground
var left_ground: Node3D = null
var right_ground: Node3D = null
var prev_left_ground: Node3D = null
var prev_right_ground: Node3D = null

# Stepping
var left_step: Transform3D
var right_step: Transform3D
var left_grounded_stop: Vector3
var right_grounded_stop: Vector3
const standing_transition_duration: float = 0.25
const stepping_transition_duration: float = 0.2
const laying_transition_duration: float = 0.25
var left_loop_state: int = 0
var right_loop_state: int = 0
var loop_scaling: float = 0


func save_previous_transforms () -> void:
	if target_hip_is_valid:
		prev_hip = target_hip
	if target_foot_is_valid:
		prev_left_foot = target_left_foot
		prev_right_foot = target_right_foot


func interpolate_transforms (p_fraction: float) -> void:
	if enable_hip_placement and target_hip_is_valid:
		interpolated_hip = prev_hip.interpolate_with(target_hip, p_fraction)
		if hip_target_spatial != null:
			hip_target_spatial.global_transform = interpolated_hip
	if enable_left_foot_placement and target_foot_is_valid:
		interpolated_left_foot = prev_left_foot.interpolate_with(target_left_foot, p_fraction)
		if foot_left_target_spatial != null:
			foot_left_target_spatial.global_transform = interpolated_left_foot
	if enable_left_foot_placement and target_foot_is_valid:
		interpolated_right_foot = prev_right_foot.interpolate_with(target_right_foot, p_fraction)
		if foot_right_target_spatial != null:
			foot_right_target_spatial.global_transform = interpolated_right_foot


func update_placement (delta: float) -> void:
	# Saracen: save the transforms from the last update for use with
	# interpolation
	save_previous_transforms()
	target_foot_is_valid = false
	target_hip_is_valid = false

	# Based on head position and delta time, we calc our speed and distance from
	# the ground and place the feet accordingly
	if ((enable_left_foot_placement or enable_right_foot_placement) && head_target_spatial && head_target_spatial.is_inside_tree()):
		target_foot_is_valid = true
		foot_place(delta, head_target_spatial.global_transform,
				head_target_spatial.get_world_3d(), false)
		

	if enable_hip_placement && head_target_spatial:
		target_hip_is_valid = true
		# calc twist from hands here
		var twist: float = 0
		var target_left_xform: Transform3D = target_left_foot
		var target_right_xform: Transform3D = target_right_foot
		if not enable_left_foot_placement:
			if foot_left_target_spatial:
				target_left_xform = foot_left_target_spatial.global_transform
			else:
				target_left_xform = skeleton.get_bone_global_pose(left_foot_id)
		if not enable_right_foot_placement:
			if foot_right_target_spatial:
				target_right_xform = foot_right_target_spatial.global_transform
			else:
				target_right_xform = skeleton.get_bone_global_pose(right_foot_id)
		hip_place(delta, head_target_spatial.global_transform,
				target_left_xform, target_right_xform, twist, false)





func hip_place(p_delta: float, p_head: Transform3D,
		p_left_foot: Transform3D, p_right_foot: Transform3D,
		p_twist: float, p_instant: bool) -> void:
	var left_middle: Vector3 = (p_left_foot.translated_local(Vector3(0, 0, left_foot_length / 2))).origin
	var right_middle: Vector3 = (p_right_foot.translated_local(Vector3(0, 0, right_foot_length / 2))).origin
	var left_distance: float = left_middle.distance_squared_to(p_head.origin)
	var right_distance: float = right_middle.distance_squared_to(p_head.origin)
	var foot_median: Vector3 = left_middle.lerp(right_middle, 0.5)
	var foot: Vector3 = left_middle if left_distance > right_distance else right_middle
	var foot_direction: Vector3 = (foot - p_head.origin).project(foot_median - p_head.origin)
	target_hip.basis = Basis(renik_helper.align_vectors(Vector3(0, -1, 0), foot_direction))
	var head_forward: Vector3 = Vector3.BACK*(p_head.basis.inverse())
	var feet_forward: Vector3 = Vector3.BACK*(p_left_foot.interpolate_with(p_right_foot, 0.5)).basis
	var hip_forward: Vector3 = feet_forward.lerp(head_forward, 0.5)

	var hip_y: Vector3 = -foot_direction.normalized()
	var hip_z: Vector3 = renik_helper.vector_rejection(hip_forward.normalized(), hip_y).normalized()
	var hip_x: Vector3 = hip_y.cross(hip_z).normalized()
	target_hip.basis = Basis(hip_x, hip_y, hip_z).orthonormalized()

	var crouch_distance: float = p_head.origin.distance_to(foot) * crouch_ratio
	var extra_hip_distance: float = hip_offset.length() - crouch_distance
	var follow_hip_direction: Vector3 = (p_head.basis * (hip_offset)) * target_hip.basis
	var effective_hip_direction: Vector3 = hip_offset.lerp(follow_hip_direction, hip_follow_head_influence).normalized()
	target_hip.origin = p_head.origin
	target_hip = target_hip.translated_local(crouch_distance * effective_hip_direction.normalized())
	if extra_hip_distance > 0:
		target_hip = target_hip.translated_local(Vector3(0, 0, -extra_hip_distance * (1 / hunch_ratio)))
	if p_instant:
		prev_hip = target_hip


# Fill-in for crappy Godot API that returns a dictionary
class RaycastResult:
	extends RefCounted

	var position: Vector3
	var normal: Vector3
	var collider: Node3D

	func _init(dic: Dictionary):
		if dic.is_empty():
			collider = null
		else:
			position = dic["position"]
			normal = dic["normal"]
			collider = dic["collider"] as Node3D


# foot_place requires raycasting unless a raycast result is provided.
# Raycasting needs to happen inside of a physics update

func foot_place(p_delta: float, p_head: Transform3D, p_world_3d: World3D, p_instant: bool) -> void:
	if p_world_3d == null:
		push_error("No World3D")
		return

	var dss: PhysicsDirectSpaceState3D = PhysicsServer3D.space_get_direct_state(p_world_3d.space)
	if not dss:
		push_error("Failed to get space")
		return

	var startOffset: float = ((spine_length) * -center_of_balance_position) / sqrt(2)
	var leftStart: Vector3 = p_head.translated_local(Vector3(0, startOffset, startOffset) + left_hip_offset).origin
	var rightStart: Vector3 = p_head.translated_local(Vector3(0, startOffset, startOffset) + right_hip_offset).origin
	var leftStop: Vector3 = p_head.origin + Vector3(0,
					(-spine_length - left_leg_length - floor_offset) * (1 + raycast_allowance) + left_hip_offset.y,
					0) + p_head.basis * (left_hip_offset)
	var rightStop: Vector3 = p_head.origin + Vector3(0,
					(-spine_length - right_leg_length - floor_offset) * (1 + raycast_allowance) + right_hip_offset.y,
					0) + p_head.basis * (right_hip_offset)

	var ray_query_parameters := PhysicsRayQueryParameters3D.new()
	ray_query_parameters.from = leftStart
	ray_query_parameters.to = leftStop
	ray_query_parameters.collision_mask = collision_mask
	ray_query_parameters.collide_with_areas = collide_with_areas
	ray_query_parameters.collide_with_bodies = collide_with_bodies
	var left_raycast_dict: Dictionary = dss.intersect_ray(ray_query_parameters)
	var left_raycast := RaycastResult.new(left_raycast_dict)
	ray_query_parameters.from = rightStart
	ray_query_parameters.to = rightStop
	var right_raycast_dict: Dictionary = dss.intersect_ray(ray_query_parameters)
	var right_raycast := RaycastResult.new(right_raycast_dict)
	ray_query_parameters.from = p_head.origin
	ray_query_parameters.to = p_head.origin - Vector3(0, spine_length + floor_offset, 0)
	var laying_raycast_dict: Dictionary = dss.intersect_ray(ray_query_parameters)
	var laying_raycast := RaycastResult.new(laying_raycast_dict)

	var left_offset: Vector3 = (leftStart - leftStop).normalized() * floor_offset * left_leg_length
	var right_offset: Vector3 = (rightStart - rightStop).normalized() * floor_offset * right_leg_length
	var laying_offset: Vector3 = Vector3(0, floor_offset * (left_leg_length + right_leg_length) / 2, 0)
	left_raycast.position += left_offset
	right_raycast.position += right_offset
	laying_raycast.position += laying_offset
	foot_place_raycasts(p_delta, p_head, left_raycast, right_raycast, laying_raycast, p_instant)


func dangle_foot(p_head: Transform3D, p_distance: float,
		p_leg_length: float, p_hip_offset: Vector3) -> Transform3D:
	var foot: Transform3D
	var upright_head: Basis = renik_helper.align_vectors(Vector3(0, 1, 0), Vector3.UP*p_head.basis).slerp(
		Quaternion(), 1 - dangle_follow_head)
	var dangle_vector: Vector3 = Vector3(0, spine_length + p_leg_length, 0) - p_hip_offset
	var dangle_basis: Basis = p_head.basis * upright_head
	foot.basis = dangle_basis * Basis(Vector3(1, 0, 0), dangle_angle)
	foot.origin = p_head.origin + dangle_basis * (-dangle_vector)
	return foot


func initialize_loop(p_velocity: Vector3, p_left_ground: Vector3,
		p_right_ground: Vector3, p_left_grounded: bool,
		p_right_grounded: bool) -> void:
	if p_left_grounded && p_right_grounded:
		var foot_diff: Vector3 = target_left_foot.origin - target_right_foot.origin
		var dot: float = foot_diff.dot(p_velocity)
		if dot == 0:
			var left_dist: float = target_left_foot.origin.distance_squared_to(p_left_ground)
			var right_dist: float = target_right_foot.origin.distance_squared_to(p_right_ground)
			if left_dist < right_dist:
				# left foot more off balance
				step_progress = 0
			else:
				# right foot more off balance
				step_progress = 0.5

		elif dot > 0:
			# left foot in front
			step_progress = 0
		else:
			# right foot in front
			step_progress = 0.5

	elif p_left_grounded:
		step_progress = 0
	else:
		step_progress = 0.5



# Returns Vector2(r_state: int, r_loop_state_progress: float)
func get_loop_state(p_loop_state_scaling: float, p_loop_progress: float, p_gait: renik_gait_class) -> Vector2:
	var r_loop_state_progress: float
	var state: int = -1
	var ground_time: float = p_gait.ground_time - p_gait.ground_time * p_loop_state_scaling
	var lift_time: float = p_gait.lift_time_base + p_gait.lift_time_scalar * p_loop_state_scaling
	var apex_in_time: float = p_gait.apex_in_time_base + p_gait.apex_in_time_scalar * p_loop_state_scaling
	var apex_out_time: float = p_gait.apex_out_time_base + p_gait.apex_out_time_scalar * p_loop_state_scaling
	var drop_time: float = p_gait.drop_time_base + p_gait.drop_time_scalar * p_loop_state_scaling
	var total_time: float = ground_time + lift_time + apex_in_time + apex_out_time + drop_time + ground_time

	var progress_time: float = p_loop_progress * total_time

	if progress_time < ground_time:
		state = LOOP_GROUND_IN
		r_loop_state_progress = (progress_time) / ground_time
	elif progress_time < ground_time + lift_time:
		state = LOOP_LIFT
		r_loop_state_progress = (progress_time - ground_time) / lift_time
	elif progress_time < ground_time + lift_time + apex_in_time:
		state = LOOP_APEX_IN
		r_loop_state_progress = (progress_time - ground_time - lift_time) / apex_in_time
	elif (progress_time < ground_time + lift_time + apex_in_time + apex_out_time):
		state = LOOP_APEX_OUT
		r_loop_state_progress = (progress_time - ground_time - lift_time - apex_in_time) / apex_out_time
	elif (progress_time < ground_time + lift_time + apex_in_time + apex_out_time + drop_time):
		state = LOOP_DROP
		r_loop_state_progress = (progress_time - ground_time - lift_time - apex_in_time - apex_out_time) / drop_time
	else:
		state = LOOP_GROUND_OUT
		r_loop_state_progress = (progress_time - ground_time - lift_time - apex_in_time - apex_out_time - drop_time) / ground_time

	return Vector2(state, r_loop_state_progress)


class LoopFootParams:
	var r_step: Transform3D
	var r_stand: Transform3D
	var r_stand_local: Transform3D
	var p_prev_ground: Node3D
	var r_loop_state: int
	var r_grounded_stop: Vector3


func loop_foot(params: LoopFootParams,
		p_ground: Node3D, p_head: Transform3D,
		p_leg_length: float, p_foot_length: float,
		p_velocity: Vector3, p_loop_scaling: float,
		p_step_progress: float, p_ground_pos: Vector3,
		p_ground_normal: Vector3, p_gait: renik_gait_class, is_left: bool=false) -> void:
	var upright_foot: Quaternion = renik_helper.align_vectors(
			Vector3(0, 1, 0), p_ground_normal * p_head.basis)
	if (p_ground_normal.dot(Vector3.UP*p_head.basis) < cos(rotation_threshold) &&
			p_ground_normal.dot(Vector3(0, 1, 0)) < cos(rotation_threshold)):
		upright_foot = Quaternion()

	var ground_velocity: Vector3 = renik_helper.vector_rejection(p_velocity, p_ground_normal)
	if ground_velocity.length() > max_threshold * step_pace:
		ground_velocity = ground_velocity.normalized() * max_threshold * step_pace

	var loop_state_progress: float = 0
	var state_and_progress: Vector2 = get_loop_state(p_loop_scaling, p_step_progress, p_gait)
	params.r_loop_state = int(state_and_progress.x)
	loop_state_progress = state_and_progress.y
	var head_distance: float = p_head.origin.distance_to(p_ground_pos)
	var ease_scaling: float = p_loop_scaling * p_loop_scaling * p_loop_scaling * p_loop_scaling # ease the growth a little
	var vertical_scaling: float = head_distance * ease_scaling
	var horizontal_scaling: float = p_leg_length * ease_scaling
	var grounded_foot: Transform3D = Transform3D(p_head.basis * Basis(upright_foot), p_ground_pos)
	var lifted_foot: Transform3D = Transform3D(
			grounded_foot.basis * Basis(Vector3(1, 0, 0),
					ease_scaling * p_gait.lift_angle),
			p_ground_pos +
					p_ground_normal * vertical_scaling * p_gait.lift_vertical_scalar +
					p_ground_normal * head_distance * p_gait.lift_vertical -
					ground_velocity.normalized() * horizontal_scaling *
							p_gait.lift_horizontal_scalar)
	var apex_foot: Transform3D = Transform3D(
			grounded_foot.basis * Basis(Vector3(1, 0, 0),
					ease_scaling * p_gait.apex_angle),
			p_ground_pos +
					p_ground_normal * vertical_scaling * p_gait.apex_vertical_scalar +
					p_ground_normal * head_distance * p_gait.apex_vertical)
	var drop_foot: Transform3D = Transform3D(
			grounded_foot.basis * Basis(Vector3(1, 0, 0),
					ease_scaling * p_gait.drop_angle),
			p_ground_pos +
					p_ground_normal * vertical_scaling * p_gait.drop_vertical_scalar +
					p_ground_normal * head_distance * p_gait.drop_vertical_scalar +
					ground_velocity.normalized() * horizontal_scaling *
							p_gait.drop_horizontal_scalar)

	match params.r_loop_state:
		LOOP_GROUND_IN, LOOP_GROUND_OUT:
			# stick to where it landed
			if p_ground != null && p_ground == params.p_prev_ground:
				params.r_stand = stand_foot(grounded_foot, params.r_stand_local, p_ground)
			elif p_ground != null:
				params.p_prev_ground = p_ground
				params.r_stand = grounded_foot
				var ground_global: Transform3D = p_ground.global_transform
				ground_global.basis = ground_global.basis.orthonormalized()
				params.r_stand_local = ground_global.affine_inverse() * params.r_stand
			else:
				params.r_stand = grounded_foot

			params.r_step = params.r_stand

			var step_distance: float = params.r_step.origin.distance_to(p_ground_pos) / p_leg_length
			var lean_offset: Transform3D
			var tip_toe_angle: float = (step_distance * p_gait.tip_toe_distance_scalar +
					horizontal_scaling * p_gait.tip_toe_speed_scalar)
			tip_toe_angle = minf(p_gait.tip_toe_angle_max, tip_toe_angle)
			lean_offset.origin = Vector3(0, p_foot_length * sin(tip_toe_angle), 0)
			lean_offset.basis = lean_offset.basis.rotated(Vector3(1, 0, 0), tip_toe_angle)
			params.r_step *= lean_offset
			params.r_grounded_stop = params.r_step.origin

		LOOP_LIFT:
			var step_distance: float = params.r_step.origin.distance_to(p_ground_pos) / p_leg_length
			var lean_offset: Transform3D
			var tip_toe_angle: float = (step_distance * p_gait.tip_toe_distance_scalar +
					horizontal_scaling * p_gait.tip_toe_speed_scalar)
			tip_toe_angle = p_gait.tip_toe_angle_max if tip_toe_angle > p_gait.tip_toe_angle_max else tip_toe_angle

			params.r_step.basis = (grounded_foot.basis * Basis(Vector3(1, 0, 0), tip_toe_angle)).slerp(
				lifted_foot.basis, loop_state_progress)
			params.r_step.origin = params.r_grounded_stop.cubic_interpolate(
					lifted_foot.origin,
					params.r_grounded_stop - ground_velocity * horizontal_scaling,
					lifted_foot.origin + p_ground_normal * vertical_scaling,
					loop_state_progress)

		LOOP_APEX_IN:
			params.r_step.basis = lifted_foot.basis.slerp(apex_foot.basis, loop_state_progress)
			params.r_step.origin = lifted_foot.origin.cubic_interpolate(
					apex_foot.origin, lifted_foot.origin - p_ground_normal * vertical_scaling,
					apex_foot.origin + ground_velocity * p_leg_length, loop_state_progress)

		LOOP_APEX_OUT:
			params.r_step.basis = apex_foot.basis.slerp(drop_foot.basis, loop_state_progress)
			params.r_step.origin = apex_foot.origin.cubic_interpolate(
					drop_foot.origin,
					apex_foot.origin - ground_velocity * horizontal_scaling,
					drop_foot.origin - p_ground_normal * vertical_scaling,
					loop_state_progress)

		LOOP_DROP:
			params.r_step.basis = drop_foot.basis.slerp(grounded_foot.basis, loop_state_progress)
			params.r_step.origin = drop_foot.origin.cubic_interpolate(
					grounded_foot.origin,
					drop_foot.origin + p_ground_normal * vertical_scaling,
					grounded_foot.origin - ground_velocity * horizontal_scaling,
					loop_state_progress)

	if params.r_loop_state != LOOP_GROUND_IN && params.r_loop_state != LOOP_GROUND_OUT:
		# update standing positions to ensure a smooth transition to standing
		params.r_stand.origin = p_ground_pos
		params.r_stand.basis = grounded_foot.basis
		if p_ground != null:
			var ground_global: Transform3D = p_ground.global_transform
			ground_global.basis = ground_global.basis.orthonormalized()
			params.r_stand_local = ground_global.affine_inverse() * params.r_stand

		if walk_state != LOOP_LIFT:
			params.r_grounded_stop = params.r_step.origin
		else:
			var contact_easing: float = p_gait.contact_point_ease + p_gait.contact_point_ease_scalar * p_loop_scaling
			contact_easing = minf(contact_easing, 1.0)
			params.r_grounded_stop = params.r_grounded_stop.lerp(p_ground_pos, contact_easing)


var loop_foot_params := LoopFootParams.new()

func loop(p_head: Transform3D, p_velocity: Vector3,
		p_left_ground_pos: Vector3, p_left_normal: Vector3,
		p_right_ground_pos: Vector3, p_right_normal: Vector3,
		p_left_grounded: bool, p_right_grounded: bool, p_gait: renik_gait_class) -> void:
	var stride_speed: float = step_pace * p_velocity.length() / ((left_leg_length + right_leg_length) / 2)
	stride_speed = log(1 + stride_speed)
	stride_speed = clampf(stride_speed, min_threshold, max_threshold)
	var new_loop_scaling: float = (stride_speed - min_threshold) / (max_threshold - min_threshold) if max_threshold > min_threshold else 0.0
	loop_scaling = (loop_scaling * p_gait.scaling_ease + new_loop_scaling * (1 - p_gait.scaling_ease))
	step_progress = fmod((step_progress + stride_speed * (p_gait.speed_scalar_min * (1.0 - loop_scaling) + p_gait.speed_scalar_max * loop_scaling)), 1.0)

	if p_left_grounded:
		loop_foot_params.r_step = left_step
		loop_foot_params.r_stand = left_stand
		loop_foot_params.r_stand_local = left_stand_local
		loop_foot_params.p_prev_ground = prev_left_ground
		loop_foot_params.r_loop_state = left_loop_state
		loop_foot_params.r_grounded_stop = left_grounded_stop
		loop_foot(loop_foot_params, left_ground, p_head,
				left_leg_length, left_foot_length, p_velocity, loop_scaling,
				step_progress, p_left_ground_pos, p_left_normal, p_gait, true)
		left_step = loop_foot_params.r_step
		left_stand = loop_foot_params.r_stand
		left_stand_local = loop_foot_params.r_stand_local
		prev_left_ground = loop_foot_params.p_prev_ground
		left_loop_state = loop_foot_params.r_loop_state
		left_grounded_stop = loop_foot_params.r_grounded_stop
	else:
		var left_dangle: Transform3D = dangle_foot(p_head,
						(spine_length + left_leg_length) * dangle_ratio,
						left_leg_length, left_hip_offset)
		left_step.basis = left_step.basis.slerp(left_dangle.basis, 1.0 - (1.0 / dangle_stiffness))
		left_step.origin = renik_helper.log_clamp(left_step.origin, left_dangle.origin, 1.0 / dangle_stiffness)

	if p_right_grounded:
		loop_foot_params.r_step = right_step
		loop_foot_params.r_stand = right_stand
		loop_foot_params.r_stand_local = right_stand_local
		loop_foot_params.p_prev_ground = prev_right_ground
		loop_foot_params.r_loop_state = right_loop_state
		loop_foot_params.r_grounded_stop = right_grounded_stop
		loop_foot(loop_foot_params, right_ground, p_head,
				right_leg_length, right_foot_length, p_velocity, loop_scaling,
				fmod((step_progress + 0.5), 1.0), p_right_ground_pos,
				p_right_normal, p_gait)
		right_step = loop_foot_params.r_step
		right_stand = loop_foot_params.r_stand
		right_stand_local = loop_foot_params.r_stand_local
		prev_right_ground = loop_foot_params.p_prev_ground
		right_loop_state = loop_foot_params.r_loop_state
		right_grounded_stop = loop_foot_params.r_grounded_stop
	else:
		var right_dangle: Transform3D = dangle_foot(p_head,
						(spine_length + right_leg_length) * dangle_ratio,
						right_leg_length, right_hip_offset)
		right_step.basis = right_step.basis.slerp(right_dangle.basis, 1.0 - (1.0 / dangle_stiffness))
		right_step.origin = renik_helper.log_clamp(right_step.origin, right_dangle.origin, 1.0 / dangle_stiffness)


func step_direction(p_forward: Vector3, p_side: Vector3,
		p_velocity: Vector3, p_left_ground: Vector3,
		p_right_ground: Vector3, p_left_grounded: bool,
		p_right_grounded: bool) -> void:
	var normalized_velocity: Vector3 = p_velocity.normalized()
	var normalized_forward: Vector3 = p_forward.normalized()
	var normalized_side: Vector3 = p_side.normalized()
	if absf(normalized_velocity.dot(normalized_side)) > strafe_angle_limit:
		if walk_state != STRAFING && walk_state != STRAFING_TRANSITION:
			walk_state = STRAFING_TRANSITION
			walk_transition_progress = stepping_transition_duration # In units of loop progression
			initialize_loop(normalized_velocity, p_left_ground, p_right_ground,
					p_left_grounded, p_right_grounded)

	elif normalized_velocity.dot(normalized_forward) < 0:
		if walk_state != BACKSTEPPING && walk_state != BACKSTEPPING_TRANSITION:
			walk_state = BACKSTEPPING_TRANSITION
			walk_transition_progress = stepping_transition_duration # In units of loop progression
			initialize_loop(normalized_velocity, p_left_ground, p_right_ground,
					p_left_grounded, p_right_grounded)

	else:
		if walk_state != STEPPING && walk_state != STEPPING_TRANSITION:
			walk_state = STEPPING_TRANSITION
			walk_transition_progress = stepping_transition_duration # In units of loop progression
			initialize_loop(normalized_velocity, p_left_ground, p_right_ground,
					p_left_grounded, p_right_grounded)


func stand_foot(p_foot: Transform3D, p_stand_local: Transform3D, p_ground: Node3D) -> Transform3D:
	var ground_global: Transform3D = p_ground.global_transform
	ground_global.basis = ground_global.basis.orthonormalized()
	var r_stand: Transform3D = ground_global * p_stand_local
	r_stand.basis = r_stand.basis.orthonormalized()
	return r_stand


'''
Step 1: Figure out what state we're in.
If we're far from the ground, we're FALLING
If we're too close to the ground, we're LAYING
If we're moving too fast forward or off-balance, we're STEPPING
If we're moving too fast backward, we're BACKSTEPPING
Else we're just STANDING

There are transition states between all these base states

Step 2: Based on the state we place the feet.
FALLING: Dangle the feet down.
LAYING: Align feet with the rejection of our head's -z axis on the ground
normal. STEPPING: DO THE LOOP STANDING: If any foot is in the air we lerp it to
where the raycast hit the ground. If any foot was already on the ground, we
leave it there. Transitions to the STANDING state is only possible from the
stepping state, so we'll know if a foot is already on the ground based on where
it was in the stepping loop.

THE LOOP: Made up of 6 parts
1. The push - From when foot is on the ground directly below the center of
gravity until it lifts off the ground.
2. The kick - Foot kicks up to the furthest point backward of the loop.
3. Enter saddle - Foot swings down to point directly below center of gravity.
It's still above the ground.
4. Exit saddle - Foot continues swing up to the furthest point forward of the
loop.
5. The buildup - Foot gains speed as it comes in contact with the ground.
6. The landing - Foot touches down and sticks the ground until it's under the
center of gravity

Parts 1 and 6 are made by keeping the foot in place in world space.
Parts 2-5 are animated with bezier curves with continuous tangents between
parts. Parts 5 and 2 have vertical tangents, 2 and 3 have horizontal tangents, 3
and 4 have vertical tangents

At high speeds the durations of parts 1 and 6 will be 0 which makes the loop an
uninterrupted loop of bezier curves At low speeds the durations of 2 and 5 will
be almost 0 (though I don't plan to go all the way to 0)

Progress through loop will be represented with a float that goes from 0.0 to 1.0
where 0.0 is the beginning of part 1 and 1.0 is the end of part 6. The progress
from 0.0 to 1.0 happens smoothly and linearly with movement speed. What range of
numbers represents each part of the loop changes dynamically with movement
speed.
'''
func foot_place_raycasts(
		p_delta: float, p_head: Transform3D,
		p_left_raycast: RaycastResult,
		p_right_raycast: RaycastResult,
		p_laying_raycast: RaycastResult, p_instant: bool) -> void:
	# Step 1: Find the proper state
	# Note we always enter transition states when possible

	left_ground = p_left_raycast.collider as Node3D
	right_ground = p_right_raycast.collider as Node3D
	var velocity: Vector3 = (p_head.origin - prevHead) / p_delta
	var left_velocity: Vector3
	var right_velocity: Vector3
	if p_left_raycast.collider != null:
		left_velocity = renik_helper.vector_rejection(velocity, p_left_raycast.normal)
	else:
		left_velocity = renik_helper.vector_rejection(velocity, Vector3(0, 1, 0))

	if p_right_raycast.collider != null:
		right_velocity = renik_helper.vector_rejection(velocity, p_right_raycast.normal)
	else:
		right_velocity = renik_helper.vector_rejection(velocity, Vector3(0, 1, 0))


	var effective_min_threshold: float = min_threshold * ((left_leg_length + right_leg_length) / 2) / step_pace
	if (!p_left_raycast.collider && !p_right_raycast.collider && !p_laying_raycast.collider) || fall_override:
		# If none of the raycasts hit anything then there isn't any ground to stand on
		walk_state = FALLING
		walk_transition_progress = 0
	elif p_laying_raycast.collider || prone_override:
		# If we're close enough for the laying raycast to trigger and we aren't
		# already laying down transition to laying down
		if walk_state != LAYING && walk_state != LAYING_TRANSITION:
			walk_state = LAYING_TRANSITION
			walk_transition_progress = laying_transition_duration # In units of loop progression

	else:
		var left_forward: Vector3 = renik_helper.vector_rejection(Vector3.BACK*left_stand.basis, p_left_raycast.normal).normalized()
		var right_forward: Vector3 = renik_helper.vector_rejection(Vector3.BACK*right_stand.basis, p_right_raycast.normal).normalized()
		var forward: Vector3 = (left_forward + right_forward).normalized()
		var upward: Vector3 = Vector3.UP*p_head.basis
		var left_upward: Vector3 = Vector3.UP*left_stand.basis
		var right_upward: Vector3 = Vector3.UP*right_stand.basis
		var feet_sideways: Vector3 = (Vector3.RIGHT*left_stand.basis + Vector3.RIGHT*right_stand.basis).normalized()
		forward.x = -forward.x # Flip the x for some reason
		feet_sideways.x = -feet_sideways.x # Flip the x for some reason
		match walk_state:
			STANDING:
				# test that the feet aren't twisted in weird ways
				var left_head_forward: Vector3 = Vector3.BACK*(p_head.basis * Basis(renik_helper.align_vectors(Vector3(0, 1, 0), p_left_raycast.normal * p_head.basis)))
				var right_head_forward: Vector3 = Vector3.BACK*(p_head.basis * Basis(renik_helper.align_vectors(Vector3(0, 1, 0), p_right_raycast.normal * p_head.basis)))
				# left_head_forward = renik_helper.vector_rejection(left_head_forward, ground_normal).normalized()
				# var left_forward: Vector3 = renik_helper.vector_rejection(Vector3.BACK*left_stand.basis, left_raycast.normal).normalized()
				# var right_forward: Vector3 = renik_helper.vector_rejection(Vector3.BACK*right_stand.basis, right_raycast.normal).normalized()
				# var forward: Vector3 = left_forward.lerp(right_forward, 0.5).normalized()
				# var upward: Vector3 = Vector3.UP*head.basis
				# var left_upward: Vector3 = Vector3.UP*left_stand.basis
				# var right_upward: Vector3 =Vector3.UP* right_stand.basis
				# var feet_sideways: Vector3 = (Vector3.RIGHT*left_stand.basis).lerp(Vector3.RIGHT*right_stand.basis, 0.5).normalized()

				if (left_velocity.length() > effective_min_threshold ||
						right_velocity.length() > effective_min_threshold ||
						(p_left_raycast.collider != null &&
								p_right_raycast.collider != null &&
								!is_balanced(target_left_foot, target_right_foot)) ||
						(p_left_raycast.collider != null &&
								left_stand.origin.distance_squared_to(p_left_raycast.position) >
										balance_threshold * (left_leg_length + right_leg_length) / 2) ||
						(p_right_raycast.collider != null &&
								right_stand.origin.distance_squared_to(p_right_raycast.position) >
										balance_threshold * (left_leg_length + right_leg_length) / 2) ||
						(p_left_raycast.collider != null &&
								(p_left_raycast.collider as Node3D) != left_ground) ||
						(p_right_raycast.collider != null &&
								(p_right_raycast.collider as Node3D) != right_ground) ||
						left_head_forward.dot(left_forward) < cos(rotation_threshold) ||
						right_head_forward.dot(right_forward) < cos(rotation_threshold) ||
						(p_left_raycast.collider != null &&
								p_left_raycast.normal.dot(left_upward) < cos(rotation_threshold) &&
								upward.dot(left_upward) < cos(rotation_threshold)) ||
						(p_right_raycast.collider != null &&
								p_right_raycast.normal.dot(right_upward) < cos(rotation_threshold) &&
								upward.dot(right_upward) < cos(rotation_threshold))):
					step_direction(forward, feet_sideways, velocity, p_left_raycast.position,
							p_right_raycast.position, p_left_raycast.collider != null,
							p_right_raycast.collider != null)

			STANDING_TRANSITION:
				if (left_velocity.length() > effective_min_threshold ||
						right_velocity.length() > effective_min_threshold ||
						(p_left_raycast.collider != null &&
								(p_left_raycast.collider as Node3D) != left_ground) ||
						(p_right_raycast.collider != null &&
								(p_right_raycast.collider as Node3D) != right_ground)):
					step_direction(forward, feet_sideways, velocity, p_left_raycast.position,
							p_right_raycast.position, p_left_raycast.collider != null,
							p_right_raycast.collider != null)

			STEPPING, STEPPING_TRANSITION, BACKSTEPPING, BACKSTEPPING_TRANSITION, STRAFING, STRAFING_TRANSITION:
				if (left_velocity.length() < effective_min_threshold &&
						right_velocity.length() < effective_min_threshold &&
						walk_transition_progress == 0 &&
						(p_left_raycast.collider == null ||
								left_stand.origin.distance_squared_to(p_left_raycast.position) <
										balance_threshold * (left_leg_length + right_leg_length) / 2) &&
						(p_right_raycast.collider == null ||
								right_stand.origin.distance_squared_to(p_right_raycast.position) <
										balance_threshold * (left_leg_length + right_leg_length) / 2)):
					walk_state = STANDING_TRANSITION
					walk_transition_progress = standing_transition_duration # In units of loop progression
				else:
					step_direction(forward, feet_sideways, velocity, p_left_raycast.position,
							p_right_raycast.position, p_left_raycast.collider != null,
							p_right_raycast.collider != null)

			_:
				step_direction(forward, feet_sideways, velocity, p_left_raycast.position,
						p_right_raycast.position, p_left_raycast.collider != null,
						p_right_raycast.collider != null)

	var stride_speed: float = step_pace * velocity.length() / ((left_leg_length + right_leg_length) / 2)
	walk_transition_progress -= maxf(min_transition_speed, stride_speed)
	walk_transition_progress = maxf(walk_transition_progress, 0.0)
	if walk_transition_progress == 0 && walk_state < 0:
		walk_state *= -1

	# Step 2: Place foot based on state
	match walk_state:
		FALLING:
			var left_dangle: Transform3D = dangle_foot(p_head, (spine_length + left_leg_length) * dangle_ratio,
							left_leg_length, left_hip_offset)
			var right_dangle: Transform3D = dangle_foot(p_head, (spine_length + right_leg_length) * dangle_ratio,
							right_leg_length, right_hip_offset)

			target_left_foot.basis = target_left_foot.basis.slerp(left_dangle.basis * foot_basis_offset,
							1.0 - (1.0 / dangle_stiffness))
			target_left_foot.origin = renik_helper.log_clamp(
					target_left_foot.origin, left_dangle.origin, 1.0 / dangle_stiffness)

			target_right_foot.basis = target_right_foot.basis.slerp(right_dangle.basis * foot_basis_offset,
							1.0 - (1.0 / dangle_stiffness))
			target_right_foot.origin = renik_helper.log_clamp(
					target_right_foot.origin, right_dangle.origin, 1.0 / dangle_stiffness)

			# for easy transitions
			left_stand = target_left_foot
			right_stand = target_right_foot
			left_step = target_left_foot
			right_step = target_right_foot
			left_grounded_stop = target_left_foot.origin
			right_grounded_stop = target_right_foot.origin
			left_ground = null
			right_ground = null
			prev_left_ground = null
			prev_right_ground = null

		STANDING_TRANSITION, STANDING:
			var effective_transition_progress: float = walk_transition_progress / standing_transition_duration
			effective_transition_progress = minf(effective_transition_progress, 1.0)
			if left_ground != null:
				left_stand = stand_foot(target_left_foot, left_stand_local, left_ground)
				target_left_foot = Transform3D(left_stand.basis * foot_basis_offset, left_stand.origin).interpolate_with(
						target_left_foot, effective_transition_progress)
				left_grounded_stop = left_stand.origin
			else:
				var left_dangle: Transform3D = dangle_foot(p_head, (spine_length + left_leg_length) * dangle_ratio,
								left_leg_length, left_hip_offset)
				target_left_foot.basis = target_left_foot.basis.slerp(left_dangle.basis * foot_basis_offset,
								1.0 - (1.0 / dangle_stiffness))
				target_left_foot.origin = renik_helper.log_clamp(
						target_left_foot.origin, left_dangle.origin, 1.0 / dangle_stiffness)


			if right_ground != null:
				right_stand = stand_foot(target_right_foot, right_stand_local, right_ground)
				target_right_foot = Transform3D(right_stand.basis * foot_basis_offset, right_stand.origin).interpolate_with(
							target_right_foot, effective_transition_progress)
				right_grounded_stop = right_stand.origin
			else:
				var right_dangle: Transform3D = dangle_foot(p_head, (spine_length + right_leg_length) * dangle_ratio,
								right_leg_length, right_hip_offset)
				target_right_foot.basis = target_right_foot.basis.slerp(right_dangle.basis * foot_basis_offset,
								1.0 - (1.0 / dangle_stiffness))
				target_right_foot.origin = renik_helper.log_clamp(target_right_foot.origin, right_dangle.origin,
								1.0 / dangle_stiffness)

		STEPPING_TRANSITION, STEPPING:
			var effective_transition_progress: float = walk_transition_progress / stepping_transition_duration
			effective_transition_progress = minf(effective_transition_progress, 1.0)
			loop(p_head, velocity, p_left_raycast.position, p_left_raycast.normal,
					p_right_raycast.position, p_right_raycast.normal,
					p_left_raycast.collider != null, p_right_raycast.collider != null,
					forward_gait)
			target_left_foot = Transform3D(left_step.basis * foot_basis_offset, left_step.origin).interpolate_with(
						target_left_foot, effective_transition_progress)
			target_right_foot = Transform3D(right_step.basis * foot_basis_offset, right_step.origin).interpolate_with(
						target_right_foot, effective_transition_progress)

		BACKSTEPPING_TRANSITION, BACKSTEPPING:
			var effective_transition_progress: float = walk_transition_progress / stepping_transition_duration
			effective_transition_progress = minf(effective_transition_progress, 1.0)
			loop(p_head, velocity, p_left_raycast.position, p_left_raycast.normal,
					p_right_raycast.position, p_right_raycast.normal,
					p_left_raycast.collider != null, p_right_raycast.collider != null,
					backward_gait)
			target_left_foot = Transform3D(left_step.basis * foot_basis_offset, left_step.origin).interpolate_with(
							target_left_foot, effective_transition_progress)
			target_right_foot = Transform3D(right_step.basis * foot_basis_offset, right_step.origin).interpolate_with(
							target_right_foot, effective_transition_progress)

		STRAFING_TRANSITION, STRAFING:
			var effective_transition_progress: float = walk_transition_progress / stepping_transition_duration
			effective_transition_progress = minf(effective_transition_progress, 1.0)
			loop(p_head, velocity, p_left_raycast.position, p_left_raycast.normal,
					p_right_raycast.position, p_right_raycast.normal,
					p_left_raycast.collider != null, p_right_raycast.collider != null,
					sideways_gait)
			target_left_foot = Transform3D(left_step.basis * foot_basis_offset, left_step.origin).interpolate_with(
						target_left_foot, effective_transition_progress)
			target_right_foot = Transform3D(right_step.basis * foot_basis_offset, right_step.origin).interpolate_with(
						target_right_foot, effective_transition_progress)

		LAYING_TRANSITION, LAYING, OTHER_TRANSITION, OTHER:
			pass

	if p_instant:
		prev_left_foot = target_left_foot
		prev_right_foot = target_right_foot

	prevHead = p_head.origin


func is_balanced (p_left: Transform3D, p_right: Transform3D) -> bool:
	var relative_right: Vector3 = p_right.origin * p_left
	var relative_left: Vector3 = p_left.origin * p_right

	# when these point in the same direction, then both the left
	# and the right are on the same side of the center
	return (relative_right.dot(Vector3(1, 0, 0)) > 0 ||
			relative_left.dot(Vector3(1, 0, 0)) < 0)


func set_falling (p_falling: bool) -> void: fall_override = p_falling

func set_collision_mask (p_mask: int) -> void:
	collision_mask = p_mask


func get_collision_mask() -> int:
	return collision_mask

func set_collision_mask_bit (p_bit: int, p_value: bool) -> void:
	var mask: int = get_collision_mask()
	if p_value:
		mask |= 1 << p_bit
	else:
		mask &= ~(1 << p_bit)
	set_collision_mask(mask)


func get_collision_mask_bit(p_bit: int) -> bool:
	return get_collision_mask() & (1 << p_bit)


func set_collide_with_areas (p_clip: bool) -> void:
	collide_with_areas = p_clip


func is_collide_with_areas_enabled() -> bool:
	return collide_with_areas


func set_collide_with_bodies (p_clip: bool) -> void:
	collide_with_bodies = p_clip


func is_collide_with_bodies_enabled() -> bool:
	return collide_with_bodies




func calculate_leg_lengths():
	left_leg_length = 0
	left_hip_offset = Vector3()
	right_leg_length = 0
	right_hip_offset = Vector3()

	if skeleton == null:
		return

	var leg_length: float = 0
	var upper_leg: int = skeleton.find_bone(armature_left_upper_leg)
	var foot: int = skeleton.find_bone(armature_left_foot)
	if upper_leg != -1 and foot != -1:
		left_leg_length = skeleton.get_bone_global_rest(foot).origin.distance_to(skeleton.get_bone_global_rest(upper_leg).origin)
		left_hip_offset = skeleton.get_bone_rest(upper_leg).origin # (skeleton.get_bone_global_rest(hips)).affine_inverse() * skeleton.get_bone_global_rest(upper_leg)).origin
	upper_leg = skeleton.find_bone(armature_right_upper_leg)
	foot = skeleton.find_bone(armature_right_foot)
	if upper_leg != -1 and foot != -1:
		right_leg_length = skeleton.get_bone_global_rest(foot).origin.distance_to(skeleton.get_bone_global_rest(upper_leg).origin)
		right_hip_offset = skeleton.get_bone_rest(upper_leg).origin # (skeleton.get_bone_global_rest(hips)).affine_inverse() * skeleton.get_bone_global_rest(upper_leg)).origin



func calculate_hip_offset () -> void:
	spine_length = 0
	# calc rest offset of hips
	var head: int = skeleton.find_bone(armature_head)
	var hip: int = skeleton.find_bone(armature_hip)

	if (skeleton && head >= 0 && head < skeleton.get_bone_count() && hip >= 0 && hip < skeleton.get_bone_count()):

		var bone: int = head
		while bone != hip:
			bone = skeleton.get_bone_parent(bone)
			if bone == hip:
				break
			spine_length += skeleton.get_bone_rest(bone).origin.length()
			if bone < 0: # invalid chain
				break

		var delta: Transform3D = skeleton.get_bone_rest(head)
		var bone_parent: int = skeleton.get_bone_parent(head)
		while bone_parent != hip && bone_parent >= 0:
			delta = skeleton.get_bone_rest(bone_parent) * delta
			bone_parent = skeleton.get_bone_parent(bone_parent)

		while bone_parent >= 0:
			delta = Transform3D(skeleton.get_bone_rest(bone_parent).basis) * delta
			bone_parent = skeleton.get_bone_parent(bone_parent)

		hip_offset = -delta.origin
