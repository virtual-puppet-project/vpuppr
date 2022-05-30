extends TrackingDataInterface

const NUMBER_OF_POINTS: int = 68

# The time this tracking data was captured at
var time: float = -1.0
# ID of the tracked face
var id: int = -1
var camera_resolution := Vector2.ZERO
# How likely it is that the given eye is open
var right_eye_open: float = -1.0
var left_eye_open: float = -1.0
# Rotation of the given eyeball
var right_gaze := Quat.IDENTITY
var left_gaze := Quat.IDENTITY
# Tells you if the 3D points have been successfully estimated from the 2d points
# If false, do not rely on pose or 3D data
var got_3d_points := false
# The error for fitting the original 3D points
# Shouldn't matter much, but if it is very high, something is probably wrong
var fit_3d_error: float = -1.0
# Rotation vector for the 3D points to turn into the estimated face pose
var rotation := Vector3.ZERO
# Translation vector for the 3D points to turn into the estimated face pose
var translation := Vector3.ZERO
# Raw rotation quaternion calculated from the OpenCV rotation matrix
var raw_quaternion := Quat.IDENTITY
# Raw rotation euler angles calculated by OpenCV from the rotation matrix
var raw_euler := Vector3.ZERO
# How certain the tracker is
var confidence := PoolRealArray()
# The detected face landmarks in image coordinates
# There are 60 points
# The last 2 points are pupil points from the gaze tracker
var points := PoolVector2Array()
# 3D points estimated from the 2D points
# They should be rotation and translation compensated
# There are 70 points with guess for the eyeball center positions
# being added at the end of 68 2D points
var points_3d := PoolVector3Array()

class Features:
	var eye_left: float
	var eye_right: float

	var eyebrow_steepness_left: float
	var eyebrow_up_down_left: float
	var eyebrow_quirk_left: float

	var eyebrow_steepness_right: float
	var eyebrow_up_down_right: float
	var eyebrow_quirk_right: float

	var mouth_corner_up_down_left: float
	var mouth_corner_in_out_left: float

	var mouth_corner_up_down_right: float
	var mouth_corner_in_out_right: float

	var mouth_open: float
	var mouth_wide: float
# The number of action unit-like features
var features := Features.new()

# We need to pass ints by reference
class Integer:
	var i: int

	func _init(p_i: int) -> void:
		i = p_i

#-----------------------------------------------------------------------------#
# Builtin functions                                                           #
#-----------------------------------------------------------------------------#

func _init() -> void:
	confidence.resize(NUMBER_OF_POINTS)
	points.resize(NUMBER_OF_POINTS)
	points_3d.resize(NUMBER_OF_POINTS + 2)

#-----------------------------------------------------------------------------#
# Connections                                                                 #
#-----------------------------------------------------------------------------#

#-----------------------------------------------------------------------------#
# Private functions                                                           #
#-----------------------------------------------------------------------------#

func _swap_x(v: Vector3) -> Vector3:
	v.x = -v.x
	return v

func _read_float(b: StreamPeerBuffer, i: Integer) -> float:
	b.seek(i.i)
	var v := b.get_float()
	i.i += 4
	return v

func _read_quaternion(b: StreamPeerBuffer, i: Integer) -> Quat:
	var x := _read_float(b, i)
	var y := _read_float(b, i)
	var z := _read_float(b, i)
	var w := _read_float(b, i)
	return Quat(x, y, z, w)

func _read_vector3(b: StreamPeerBuffer, i: Integer) -> Vector3:
	# NOTE we invert the y value here
	# TODO we adjust the y value when loading models and always seem to negate it
	# Maybe we don't need to negate it here?
	return Vector3(_read_float(b, i), -_read_float(b, i), _read_float(b, i))

func _read_vector2(b: StreamPeerBuffer, i: Integer) -> Vector2:
	return Vector2(_read_float(b, i), _read_float(b, i))

#-----------------------------------------------------------------------------#
# Public functions                                                            #
#-----------------------------------------------------------------------------#

func read_from_packet(b: PoolByteArray, regular_int: int) -> void:
	var spb := StreamPeerBuffer.new()
	spb.data_array = b
	var i := Integer.new(regular_int)

	spb.seek(i.i)
	time = spb.get_double()
	i.i += 8

	spb.seek(i.i)
	id = spb.get_32()
	i.i += 4

	camera_resolution = _read_vector2(spb, i)
	right_eye_open = _read_float(spb, i)
	left_eye_open = _read_float(spb, i)

	var got_3d := b[i.i]
	i.i += 1
	got_3d_points = false
	if got_3d != 0:
		got_3d_points = true

	fit_3d_error = _read_float(spb, i)
	raw_quaternion = _read_quaternion(spb, i)
	raw_euler = _read_vector3(spb, i)

	rotation = raw_euler
	# rotation.z = fmod(rotation.z - 90, 360)
	rotation.x = rotation.x if rotation.x > 0.0 else rotation.x + 360.0

	var x := _read_float(spb, i)
	var y := _read_float(spb, i)
	var z := _read_float(spb, i)
	
	translation = Vector3(-y, -x, -z)

	for point_idx in NUMBER_OF_POINTS:
		confidence.set(point_idx, _read_float(spb, i))

	for point_idx in NUMBER_OF_POINTS:
		points.set(point_idx, _read_vector2(spb, i))

	for point_idx in NUMBER_OF_POINTS + 2:
		points_3d.set(point_idx, _read_vector3(spb, i))

	# TODO im pretty sure this is kind of wrong
	right_gaze = Quat(Transform().looking_at(points_3d[66] - points_3d[68], Vector3.UP).basis).normalized()
	left_gaze = Quat(Transform().looking_at(points_3d[67] - points_3d[69], Vector3.UP).basis).normalized()

	features.eye_left = _read_float(spb, i)
	features.eye_right = _read_float(spb, i)
	features.eyebrow_steepness_left = _read_float(spb, i)
	features.eyebrow_up_down_left = _read_float(spb, i)
	features.eyebrow_quirk_left = _read_float(spb, i)
	features.eyebrow_steepness_right = _read_float(spb, i)
	features.eyebrow_up_down_right = _read_float(spb, i)
	features.eyebrow_quirk_right = _read_float(spb, i)
	features.mouth_corner_up_down_left = _read_float(spb, i)
	features.mouth_corner_in_out_left = _read_float(spb, i)
	features.mouth_corner_up_down_right = _read_float(spb, i)
	features.mouth_corner_in_out_right = _read_float(spb, i)
	features.mouth_open = _read_float(spb, i)
	features.mouth_wide = _read_float(spb, i)

#region Metadata

func get_updated_time() -> float:
	return time

func get_confidence() -> float:
	return fit_3d_error

#endregion

#region General

func get_euler() -> Vector3:
	# return raw_euler
	return rotation

func get_rotation() -> Quat:
	return raw_quaternion

func get_translation() -> Vector3:
	return translation

#endregion

#region Eyes

func get_left_eye_open_amount() -> float:
	return features.eye_left

func get_left_eye_euler() -> Vector3:
	return left_gaze.get_euler()

func get_left_eye_rotation() -> Quat:
	return left_gaze

func get_right_eye_open_amount() -> float:
	return features.eye_right

func get_right_eye_euler() -> Vector3:
	return right_gaze.get_euler()

func get_right_eye_rotation() -> Quat:
	return right_gaze

#endregion

#region Mouth

func get_mouth_open_amount() -> float:
	return features.mouth_open

func get_mouth_wide_amount() -> float:
	return features.mouth_wide

#endregion

func get_additional_info():
	return features
