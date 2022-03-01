extends "res://tests/base_test.gd"

# https://github.com/bitwes/Gut/wiki/Quick-Start

###############################################################################
# Builtin functions                                                           #
###############################################################################

func before_all():
	.before_all()

func before_each():
	pass

func after_each():
	pass

func after_all():
	pass

###############################################################################
# Utils                                                                       #
###############################################################################

###############################################################################
# Tests                                                                       #
###############################################################################

var good_string0 := """
{
	"other": {},
	"default_model_path": "some/model/path",
	"default_search_path": "some/search_path",
	"use_transparent_background": false,
	"use_fxaa": false,
	"msaa_value": false,
	"model_configs": {
		"duck_config": "duck/path"
	},
	"model_defaults": {
		"duck.glb": "duck_config"
	},
	"camera_index": "1",
	"python_path": "python/path"
}
"""

var good_string1 := """
{
	"other": {
		"use_lip_sync": true
	},
	"default_model_path": "eh/path",
	"some_garbage": "garbage_value"
}
"""

func test_parse_get_data_pass():
	var md0 := Metadata.new()

	assert_true(md0.parse_string(good_string0).is_ok())
	assert_true(md0.get_data("other").empty())
	assert_false(md0.other.has("default_model_path"))
	assert_eq(md0.get_data("default_model_path"), "some/model/path")
	assert_eq(md0.get_data("default_search_path"), "some/search_path")
	assert_eq(md0.get_data("use_transparent_background"), false)
	assert_eq(md0.get_data("use_fxaa"), false)
	assert_eq(md0.get_data("msaa_value"), false)
	assert_eq(md0.get_data("model_configs").duck_config, "duck/path")
	assert_eq(md0.get_nested_data("model_defaults/duck.glb"), "duck_config")
	assert_eq(md0.get_data("camera_index"), "1")
	assert_eq(md0.get_data("python_path"), "python/path")

	var md1 := Metadata.new()

	assert_true(md1.parse_string(good_string1).is_ok())
	assert_eq(md1.get_nested_data("other/some_garbage"), "garbage_value")
	assert_eq(md1.get_nested_data("other/use_lip_sync"), true)
	assert_eq(md1.get_data("default_model_path"), "eh/path")
