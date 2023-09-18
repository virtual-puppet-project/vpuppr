# renik_helper.cpp
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

#include "renik_helper.h"
@tool
extends RefCounted

static func safe_acos(f: float) -> float:
	return acos(clampf(f, -1, 1))


static func safe_asin(f: float) -> float:
	return asin(clampf(f, -1, 1))


static func get_perpendicular_vector(v: Vector3) -> Vector3:
	var perpendicular: Vector3
	if v.x != 0 && v.y != 0:
		perpendicular = Vector3(0, 0, 1).cross(v).normalized()
	else:
		perpendicular = Vector3(1, 0, 0)
	return perpendicular


static func vector_rejection(v: Vector3, normal: Vector3) -> Vector3:
	if v.length_squared() == 0 || normal.length_squared() == 0:
		return Vector3()

	var normalLength: float = normal.length()
	var proj: Vector3 = (normal.dot(v) / normalLength) * (normal / normalLength);
	return v - proj


static func align_vectors(a: Vector3, b: Vector3, influence: float=1) -> Quaternion:
	if a.length_squared() == 0 || b.length_squared() == 0:
		return Quaternion()

	a = a.normalized()
	b = b.normalized()
	if a.length_squared() != 0 && b.length_squared() != 0:
		# Find the axis perpendicular to both vectors and rotate along it by the angular difference
		var perpendicular: Vector3 = a.cross(b);
		var angleDiff: float = a.angle_to(b) * influence
		if perpendicular.length_squared() == 0:
			perpendicular = get_perpendicular_vector(a)
		# FIXME: double normalization
		return Quaternion(perpendicular.normalized().normalized(), angleDiff).normalized();
	else:
		return Quaternion()

static func smooth_curve(number: float, modifier: float=0.5) -> float:
	return number / (absf(number) + modifier)


static func log_clamp_basis(basis: Basis, target: Basis, looseness: float) -> Basis:
	return Basis(log_clamp_quat(basis.get_rotation_quaternion(), target.get_rotation_quaternion(), looseness))


static func log_clamp_quat(quat: Quaternion, target: Quaternion, looseness: float) -> Quaternion:
	quat.x = log_clampf(quat.x, target.x, looseness)
	quat.y = log_clampf(quat.y, target.y, looseness)
	quat.z = log_clampf(quat.z, target.z, looseness)
	quat.w = log_clampf(quat.w, target.w, looseness)
	return quat.normalized()


static func log_clamp(vector: Vector3, target: Vector3, looseness: float) -> Vector3:
	vector.x = log_clampf(vector.x, target.x, looseness)
	vector.y = log_clampf(vector.y, target.y, looseness)
	vector.z = log_clampf(vector.z, target.z, looseness)
	return vector


static func log_clampf(value: float, target: float, looseness: float) -> float:
	var difference: float = value - target
	var effectiveLooseness: float = looseness if difference >= 0 else looseness * -1
	return target + effectiveLooseness * log(1 + (difference / effectiveLooseness))

