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

#-----------------------------------------------------------------------------#
# Tests                                                                       #
#-----------------------------------------------------------------------------#

func test_transform_roundtrip_pass():
	var t := Transform(
		Vector3.ONE,
		Vector3.ZERO,
		-Vector3.ONE,
		Vector3(1.0, 2.0, 3.0)
	)

	var d := JSONUtil.transform_to_dict(t)

	# Demonstrate that this is indeed a Dictionary
	assert_typeof(d, TYPE_DICTIONARY)
	assert_eq(d["basis"]["x"]["x"], 1.0)
	assert_eq(d.basis.y.z, 0.0)
	assert_eq(d.basis.z.z, -1.0)
	assert_eq(d.origin.x, 1.0)
	assert_eq(d.origin.y, 2.0)
	assert_eq(d.origin.z, 3.0)

	var r := JSONUtil.dict_to_transform(d)

	assert_typeof(r, TYPE_TRANSFORM)
	assert_eq(r.basis.x.x, 1.0)
	assert_eq(r.basis.x.y, 1.0)
	assert_eq(r.basis.x.z, 1.0)
	assert_eq(r.basis.y.y, 0.0)
	assert_eq(r.basis.z.y, -1.0)
	assert_eq(r.origin.x, 1.0)
	assert_eq(r.origin.y, 2.0)
	assert_eq(r.origin.z, 3.0)

func test_color_roundtrip_pass():
	var c := Color.white
	c.a = 0.5

	var d := JSONUtil.color_to_dict(c)

	assert_typeof(d, TYPE_DICTIONARY)
	assert_eq(d.r, 1.0)
	assert_eq(d["g"], 1.0)
	assert_eq(d.b, 1.0)
	assert_eq(d.a, 0.5)

	var r := JSONUtil.dict_to_color(d)

	assert_typeof(r, TYPE_COLOR)
	assert_eq(r.r, 1.0)
	assert_eq(r.g, 1.0)
	assert_eq(r.b, 1.0)
	assert_eq(r.a, 0.5)

