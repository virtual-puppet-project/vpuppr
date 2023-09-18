# renik_limb.cpp
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
# EXPRESS OR IMPLIED, I`NCLUDING BUT NOT LIMITED TO THE WARRANTIES OF
# MERCHANTABILITY, FITNESS FOR A PARTICULAR PURPOSE AND NONINFRINGEMENT.
# IN NO EVENT SHALL THE AUTHORS OR COPYRIGHT HOLDERS BE LIABLE FOR ANY
# CLAIM, DAMAGES OR OTHER LIABILITY, WHETHER IN AN ACTION OF CONTRACT,
# TORT OR OTHERWISE, ARISING FROM, OUT OF OR IN CONNECTION WITH THE
# SOFTWARE OR THE USE OR OTHER DEALINGS IN THE SOFTWARE.

@tool
extends RefCounted

var upper: Transform3D
var lower: Transform3D
var leaf: Transform3D
var upper_extra_bones: Transform3D # Extra bones between upper and lower
var lower_extra_bones: Transform3D # Extra bones between lower and leaf
var upper_extra_bone_ids: PackedInt32Array
var lower_extra_bone_ids: PackedInt32Array
var leaf_id: int = -1
var lower_id: int = -1
var upper_id: int = -1

var upper_twist_offset: float = 0
var lower_twist_offset: float = 0
var roll_offset: float = 0 # Rolls the entire limb so the joint points in a different direction.
var upper_limb_twist: float = 0 # How much the upper limb follows the lower limb.
var lower_limb_twist: float = 0 # How much the lower limb follows the leaf limb.
var twist_inflection_point_offset: float = 0 # When the limb snaps from twisting in the positive direction to twisting in the negative direction.
var twist_overflow: float = 0 # How much past the inflection point we go before snapping.

# ADVANCED - Moving the limb 180 degrees from rest tends to
# be a bit unpredictable as there is a pole in the forward vector sphere at
# that spot. This offsets the rest position so that the pole is in a place
# where the limb is unlikely to go
var pole_offset: Quaternion

# ADVANCED - How much each of the leaf's axis of translation from rest affects the ik.
var target_position_influence: Vector3
# ADVANCED - How much the rotation the leaf points in affects the ik.
var target_rotation_influence: float

# STATE: We're keeping a little bit of state now... kinda goes against the design, but it makes life easier so fuck it.
var overflow_state: int = 0 # 0 means no twist overflow. -1 means underflow. 1 means overflow.


func _init(p_upper_twist_offset: float, p_lower_twist_offset: float,
		p_roll_offset: float, p_upper_limb_twist: float,
		p_lower_limb_twist: float,
		p_twist_inflection_point_offset: float,
		p_twist_overflow: float, p_target_rotation_influence: float,
		p_pole_offset: Vector3,
		p_target_position_influence: Vector3):
	upper_twist_offset = p_upper_twist_offset
	lower_twist_offset = p_lower_twist_offset
	roll_offset = p_roll_offset
	upper_limb_twist = p_upper_limb_twist
	lower_limb_twist = p_lower_limb_twist
	twist_inflection_point_offset = p_twist_inflection_point_offset
	twist_overflow = p_twist_overflow
	target_rotation_influence = p_target_rotation_influence
	pole_offset = Quaternion.from_euler(p_pole_offset)
	target_position_influence = p_target_position_influence


func get_extra_bones(skeleton: Skeleton3D, p_root_bone_id: int, p_tip_bone_id: int) -> Transform3D:
	var cumulative_rest: Transform3D
	var current_bone_id: int = p_tip_bone_id
	while current_bone_id != -1 && current_bone_id != p_root_bone_id:
		current_bone_id = skeleton.get_bone_parent(current_bone_id)
		if current_bone_id == -1 || current_bone_id == p_root_bone_id:
			break
		cumulative_rest = skeleton.get_bone_rest(current_bone_id) * cumulative_rest

	return cumulative_rest

func get_extra_bone_ids(skeleton: Skeleton3D, p_root_bone_id: int, p_tip_bone_id: int) -> PackedInt32Array:
	var output: PackedInt32Array
	var current_bone_id: int = p_tip_bone_id
	while current_bone_id != -1:
		current_bone_id = skeleton.get_bone_parent(current_bone_id)
		if current_bone_id == -1 || current_bone_id == p_root_bone_id:
			break
		output.push_back(current_bone_id)

	return output


func update(skeleton: Skeleton3D) -> void:
	if skeleton != null && leaf_id >= 0:
		lower_id = lower_id if lower_id >= 0 else skeleton.get_bone_parent(leaf_id)
		if lower_id >= 0:
			upper_id = upper_id if upper_id >= 0 else skeleton.get_bone_parent(lower_id)
			if upper_id >= 0:
				# leaf = get_full_rest(skeleton, leaf_id, lower_id)
				# lower = get_full_rest(skeleton, lower_id, upper_id)
				# upper = skeleton.get_bone_rest(upper_id)

				lower_extra_bones = get_extra_bones(
						skeleton, lower_id,
						leaf_id) # lower bone + all bones after that except the leaf
				upper_extra_bones = get_extra_bones(
						skeleton, upper_id,
						lower_id) # upper bone + all bones between upper and lower
				lower_extra_bone_ids = get_extra_bone_ids(skeleton, lower_id, leaf_id)
				upper_extra_bone_ids = get_extra_bone_ids(skeleton, upper_id, lower_id)

				leaf = Transform3D(Basis(), skeleton.get_bone_rest(leaf_id).origin)
				lower = Transform3D(Basis(), skeleton.get_bone_rest(lower_id).origin)
				upper = Transform3D(Basis(), skeleton.get_bone_rest(upper_id).origin)


func is_valid() -> bool:
	return upper_id >= 0 && lower_id >= 0 && leaf_id >= 0


func is_valid_in_skeleton(skeleton: Skeleton3D) -> bool:
	if (skeleton == null || upper_id < 0 || lower_id < 0 || leaf_id < 0 ||
			upper_id >= skeleton.get_bone_count() ||
			lower_id >= skeleton.get_bone_count() ||
			leaf_id >= skeleton.get_bone_count()):
		return false

	var curr: int = skeleton.get_bone_parent(leaf_id)
	while curr != -1 && curr != lower_id:
		curr = skeleton.get_bone_parent(curr)

	while curr != -1 && curr != upper_id:
		curr = skeleton.get_bone_parent(curr)

	return curr != -1

