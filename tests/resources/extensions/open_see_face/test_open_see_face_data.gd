extends "res://tests/base_test.gd"

# https://github.com/bitwes/Gut/wiki/Quick-Start

#-----------------------------------------------------------------------------#
# Builtin functions                                                           #
#-----------------------------------------------------------------------------#

func before_all():
	.before_all()

func before_each():
	pass

func after_each():
	pass

func after_all():
	pass

#-----------------------------------------------------------------------------#
# Utils                                                                       #
#-----------------------------------------------------------------------------#

func _create_buffer() -> StreamPeerBuffer:
	var b := StreamPeerBuffer.new()
	b.data_array = bytes
	b.seek(0)

	return b

func _create_integer() -> OpenSeeFaceData.Integer:
	return OpenSeeFaceData.Integer.new(0)

#-----------------------------------------------------------------------------#
# Tests                                                                       #
#-----------------------------------------------------------------------------#

var bytes := PoolByteArray(
	[
		0x9A, 0x99, 0x19, 0x3F, 0x9A, 0x99, 0x19, 0x3F, 0, 0, 0, 0,
		0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0
	]
)

# TODO test read_from_packet
# This will require actual tracking data OR very tediously-put-together test data

func test_init_pass():
	var d := OpenSeeFaceData.new()

	assert_eq(d.confidence.size(), OpenSeeFaceData.NUMBER_OF_POINTS)
	assert_eq(d.points.size(), OpenSeeFaceData.NUMBER_OF_POINTS)
	assert_eq(d.points_3d.size(), OpenSeeFaceData.NUMBER_OF_POINTS + 2)
	
	# All fields have garbage default values
	assert_eq(d.time, -1.0)
	assert_eq(d.id, -1)
	assert_eq(d.camera_resolution, Vector2.ZERO)

func test_swap_x_pass():
	var d := OpenSeeFaceData.new()

	var input := Vector3.ONE

	assert_eq(d._swap_x(input), Vector3(-1.0, 1.0, 1.0))

func test_read_float_pass():
	var d := OpenSeeFaceData.new()
	var b := _create_buffer()
	var i := _create_integer()

	# Round to the nearest tenths and make sure this method is correct
	assert_true(stepify(0.6, 0.1) != 1.0)
	# Floats are read in bundles of 4
	assert_eq(stepify(d._read_float(b, i), 0.1), stepify(0.6, 0.1))
	assert_eq(stepify(d._read_float(b, i), 0.1), stepify(0.6, 0.1))
	# We should eventually get to only 0s in the data
	assert_eq(stepify(d._read_float(b, i), 0.1), 0.0)

func test_read_vector2_pass():
	var d := OpenSeeFaceData.new()
	var b := _create_buffer()
	var i := _create_integer()

	var res: Vector2 = d._read_vector2(b, i)

	# Vector2s are read as bundles of 2 floats
	assert_eq(stepify(res.x, 0.1), stepify(0.6, 0.1))
	assert_eq(stepify(res.y, 0.1), stepify(0.6, 0.1))
	assert_eq(d._read_vector2(b, i), Vector2.ZERO)

func test_read_vector3_pass():
	var d := OpenSeeFaceData.new()
	var b := _create_buffer()
	var i := _create_integer()

	var res: Vector3 = d._read_vector3(b, i)

	assert_eq(stepify(res.x, 0.1), stepify(0.6, 0.1))
	assert_eq(stepify(res.y, 0.1), -stepify(0.6, 0.1))
	assert_eq(stepify(res.z, 0.1), 0.0)
	assert_eq(d._read_vector3(b, i), Vector3.ZERO)

func test_read_quat_pass():
	var d := OpenSeeFaceData.new()
	var b := _create_buffer()
	var i := _create_integer()

	var res: Quat = d._read_quaternion(b, i)

	assert_eq(stepify(res.x, 0.1), stepify(0.6, 0.1))
	assert_eq(stepify(res.y, 0.1), stepify(0.6, 0.1))
	assert_eq(stepify(res.z, 0.1), 0.0)
	assert_eq(stepify(res.w, 0.1), 0.0)
	assert_eq(d._read_quaternion(b, i), Quat(0.0, 0.0, 0.0, 0.0))
