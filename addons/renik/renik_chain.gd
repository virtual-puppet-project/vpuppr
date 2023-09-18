# renik_chain.cpp
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
extends RefCounted

class Joint:
	var rotation: Quaternion
	var id: int
	var relative_prev: Vector3
	var relative_next: Vector3
	var prev_distance: float = 0
	var next_distance: float = 0
	var root_influence: float = 0
	var leaf_influence: float = 0
	var twist_influence: float = 1

var root_bone: int = -1
var first_bone: int = -1
var leaf_bone: int = -1

var joints: Array[Joint]
var total_length: float = 0
var rest_leaf: Transform3D

var chain_curve_direction: Vector3
var root_influence: float = 0 # how much the start bone is influenced by the root rotation
var leaf_influence: float = 0 # how much the end bone is influenced by the goal rotation
var twist_influence: float = 1 # How much the chain tries to twist to follow the end when the start is facing a different direction
var twist_start: float = 0 # Where along the chain the twisting starts


func _init(p_chain_curve_direction: Vector3, p_root_influence: float,
		p_leaf_influence: float, p_twist_influence: float,
		p_twist_start: float):
	chain_curve_direction = p_chain_curve_direction
	root_influence = p_root_influence
	leaf_influence = p_leaf_influence
	twist_influence = p_twist_influence
	twist_start = p_twist_start


func init_chain(skeleton: Skeleton3D):
	joints.clear()
	total_length = 0
	if (skeleton && root_bone >= 0 && leaf_bone >= 0 &&
			root_bone < skeleton.get_bone_count() &&
			leaf_bone < skeleton.get_bone_count()):
		var bone: int = skeleton.get_bone_parent(leaf_bone)
		# generate the chain of bones
		var chain: PackedInt32Array
		var last_length: float = 0.0
		rest_leaf = skeleton.get_bone_rest(leaf_bone)
		while bone != root_bone:
			var rest_pose: Transform3D = skeleton.get_bone_rest(bone)
			rest_leaf = rest_pose * rest_leaf.orthonormalized()
			last_length = rest_pose.origin.length()
			total_length += last_length
			if bone < 0: # invalid chain
				total_length = 0
				first_bone = -1
				rest_leaf = Transform3D()
				return
			chain.push_back(bone)
			first_bone = bone
			bone = skeleton.get_bone_parent(bone)

		total_length -= last_length
		total_length += skeleton.get_bone_rest(leaf_bone).origin.length()

		if total_length <= 0: # invalid chain
			total_length = 0
			first_bone = -1
			rest_leaf = Transform3D()
			return

		var totalRotation: Basis
		var progress: float = 0
		# flip the order and figure out the relative distances of these joints
		for i in range(len(chain) - 1, -1, -1):
			var j: Joint = Joint.new()
			j.id = chain[i]
			var boneTransform: Transform3D = skeleton.get_bone_rest(j.id)
			j.rotation = boneTransform.basis.get_rotation_quaternion()
			j.relative_prev = boneTransform.origin * totalRotation
			j.prev_distance = j.relative_prev.length()

			# calc influences
			progress += j.prev_distance
			var percentage: float = (progress / total_length)
			var effectiveRootInfluence: float = 0
			var effectiveLeafInfluence: float = 0
			var effectiveTwistInfluence: float = 0
			if root_influence > 0 and percentage < root_influence:
				effectiveRootInfluence = (percentage - root_influence) / -root_influence
			if leaf_influence > 0 and percentage > 1 - leaf_influence:
				effectiveLeafInfluence = (percentage - (1 - leaf_influence)) / leaf_influence
			if twist_start < 1 and twist_influence > 0 and percentage > twist_start:
				effectiveTwistInfluence = (percentage - twist_start) * (twist_influence / (1 - twist_start))
			j.root_influence = minf(effectiveRootInfluence, 1)
			j.leaf_influence = minf(effectiveLeafInfluence, 1)
			j.twist_influence = minf(effectiveTwistInfluence, 1)

			if not joints.is_empty():
				joints[len(joints) - 1].relative_next = -j.relative_prev
				joints[len(joints) - 1].next_distance = j.prev_distance

			joints.push_back(j)
			totalRotation = (totalRotation * boneTransform.basis).orthonormalized()

		if not joints.is_empty():
			joints[len(joints) - 1].relative_next = -skeleton.get_bone_rest(leaf_bone).origin
			joints[len(joints) - 1].next_distance = joints[len(joints) - 1].relative_next.length()


func is_valid() -> bool:
	return not joints.is_empty()


func contains_bone(skeleton: Skeleton3D, bone: int) -> bool:
	if skeleton:
		var spineBone: int = leaf_bone
		while spineBone >= 0:
			if spineBone == bone:
				return true

			spineBone = skeleton.get_bone_parent(spineBone)

	return false

