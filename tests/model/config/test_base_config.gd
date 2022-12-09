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

func test_parse_unknown_fields() -> void:
	var data := {
		"other": {
			"hello": "world",
			"inner_dict": {
				"vec3": Vector3.ONE
			}
		},
		"test_transform": Transform(),
		"test_int": 22,
		"test_float": 1.1,
		"test_color": Color.aqua
	}
	
	var bc := BaseConfig.new()
	
	bc.from_string(var2str(data))

	assert_eq(bc.other.hello, "world")
	assert_eq(bc.other.inner_dict.vec3, Vector3.ONE)
	assert_eq(bc.other.test_transform, Transform())
	assert_eq(bc.other.test_int, 22)
	assert_eq("%1.1f" % bc.other.test_float, "%1.1f" % 1.1)
	assert_eq(bc.other.test_color, Color.aqua)
