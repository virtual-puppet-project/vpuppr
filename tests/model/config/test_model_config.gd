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

func test_e2e() -> void:
	var expected_values := {
		"name": "test name",
		"path": "/some/path/to/model",
		"transform": Transform.FLIP_X
	}

	var mc0 := ModelConfig.new()
	
	mc0.model_name = expected_values.name
	mc0.model_path = expected_values.path
	mc0.model_transform = expected_values.transform

	var file_contents := mc0.to_string()

	var mc1 := ModelConfig.new()

	assert_eq(mc1.model_name, "")
	assert_eq(mc1.model_path, "")
	assert_eq(mc1.model_transform, Transform.IDENTITY)

	mc1.from_string(file_contents)

	assert_eq(mc1.model_name, expected_values.name)
	assert_eq(mc1.model_path, expected_values.path)
	assert_eq(mc1.model_transform, expected_values.transform)
