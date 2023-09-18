# renik_placement_gait.gd
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
# NOTE: extends Resource are required to have class_name.
# If class_name is removed, @export var in RenIKPlacement will become null.
# It does not matter what class_name is used.
class_name RenIKGait
extends Resource

@export_range(0,2,0.001) var speed_scalar_min: float = 1
@export_range(0,2,0.001) var speed_scalar_max: float = 1
# timing
@export_range(0,1,0.001) var ground_time: float = 20
@export_range(0,1,0.001) var lift_time_base: float = 10
@export_range(0,1,0.001) var lift_time_scalar: float = 5
@export_range(0,1,0.001) var apex_in_time_base: float = 10
@export_range(0,1,0.001) var apex_in_time_scalar: float = 5
@export_range(0,1,0.001) var apex_out_time_base: float = 10
@export_range(0,1,0.001) var apex_out_time_scalar: float = 5
@export_range(0,1,0.001) var drop_time_base: float = 10
@export_range(0,1,0.001) var drop_time_scalar: float = 5
# ground
@export_range(-180,180,0.1,"radians") var tip_toe_distance_scalar: float = PI / 8
@export_range(-180,180,0.1,"radians") var tip_toe_speed_scalar: float = PI / 4
@export_range(-180,180,0.1,"radians") var tip_toe_angle_max: float = PI / 3
# lift
@export_range(0,1,0.001) var lift_vertical: float = 0.025
@export_range(0,1,0.001) var lift_vertical_scalar: float = 0.25
@export_range(0,1,0.001) var lift_horizontal_scalar: float = 0.5
@export_range(-180,180,0.1,"radians") var lift_angle: float = 0
# apex
@export_range(0,1,0.001) var apex_vertical: float = 0.01
@export_range(0,1,0.001) var apex_vertical_scalar: float = 0.1
@export_range(-180,180,0.1,"radians") var apex_angle: float = 0
# drop
@export_range(0,1,0.001) var drop_vertical: float = 0.0
@export_range(0,1,0.001) var drop_vertical_scalar: float = 0.15
@export_range(0,1,0.001) var drop_horizontal_scalar: float = 0.25
@export_range(-180,180,0.1,"radians") var drop_angle: float = 0
# contact
@export_range(0,1,0.001) var contact_point_ease: float = 0.1
@export_range(0,1,0.001) var contact_point_ease_scalar: float = 0.4
@export_range(0,1,0.001) var scaling_ease: float = 0.9

func _init(p_speed_min_scalar: float, p_speed_max_scalar: float,
		p_ground_time_min: float, p_lift_time_base: float,
		p_lift_time_scalar: float, p_apex_in_time_base: float,
		p_apex_in_time_scalar: float, p_apex_out_time_base: float,
		p_apex_out_time_scalar: float, p_drop_time_base: float,
		p_drop_time_scalar: float, p_tip_toe_distance_scalar: float,
		p_tip_toe_speed_scalar: float, p_tip_toe_angle_max: float,
		p_lift_vertical: float, p_lift_vertical_scalar: float,
		p_lift_horizontal_scalar: float, p_lift_angle: float,
		p_apex_vertical: float, p_apex_vertical_scalar: float, p_apex_angle: float,
		p_drop_vertical: float, p_drop_vertical_scalar: float,
		p_drop_horizontal_scalar: float, p_drop_angle: float,
		p_contact_point_ease: float, p_contact_point_ease_scalar: float,
		p_scaling_ease: float):
	speed_scalar_min = p_speed_min_scalar
	speed_scalar_max = p_speed_max_scalar
	ground_time = p_ground_time_min
	lift_time_base = p_lift_time_base
	lift_time_scalar = p_lift_time_scalar
	apex_in_time_base = p_apex_in_time_base
	apex_in_time_scalar = p_apex_in_time_scalar
	apex_out_time_base = p_apex_out_time_base
	apex_out_time_scalar = p_apex_out_time_scalar
	drop_time_base = p_drop_time_base
	drop_time_scalar = p_drop_time_scalar
	tip_toe_distance_scalar = p_tip_toe_distance_scalar
	tip_toe_speed_scalar = p_tip_toe_speed_scalar
	tip_toe_angle_max = p_tip_toe_angle_max
	lift_vertical = p_lift_vertical
	lift_vertical_scalar = p_lift_vertical_scalar
	lift_horizontal_scalar = p_lift_horizontal_scalar
	lift_angle = p_lift_angle
	apex_vertical = p_apex_vertical
	apex_vertical_scalar = p_apex_vertical_scalar
	apex_angle = p_apex_angle
	drop_vertical = p_drop_vertical
	drop_vertical_scalar = p_drop_vertical_scalar
	drop_horizontal_scalar = p_drop_horizontal_scalar
	drop_angle = p_drop_angle
	contact_point_ease = p_contact_point_ease
	contact_point_ease_scalar = p_contact_point_ease_scalar
	scaling_ease = p_scaling_ease
