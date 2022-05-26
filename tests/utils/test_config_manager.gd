extends "res://tests/base_test.gd"

# https://github.com/bitwes/Gut/wiki/Quick-Start

#-----------------------------------------------------------------------------#
# Builtin functions                                                           #
#-----------------------------------------------------------------------------#

func before_all():
	.before_all()

func before_each():
	cm = ConfigManager.new()

	var dir := Directory.new()
	if not dir.dir_exists(temp_folder_path):
		dir.make_dir_recursive(temp_folder_path)

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

# TODO test other code paths

var temp_folder_path := ProjectSettings.globalize_path("res://tests/temp")

var good_metadata0 := """
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

var cm: ConfigManager

func test_get_set_data_pass():
	cm.model_config.description = "test description"
	cm.model_config.other["nested_dict"] = {}
	cm.model_config.other["nested_dict"]["nested_array"] = []
	cm.model_config.other["nested_dict"]["nested_array"].append(1)
	cm.model_config.other["nested_dict"]["nested_array"].append(10)
	cm.metadata.other["nested_dict"] = {}
	cm.metadata.other["nested_dict"]["hello"] = "world"

	assert_eq(cm.get_data("description"), "test description")
	assert_eq(cm.find_data_get("other/nested_dict/nested_array/1").unwrap(), 10)
	assert_eq(cm.find_data_get("other/nested_dict/hello").unwrap(), "world")

	cm.set_data("description", "other description")

	assert_eq(cm.get_data("description"), "other description")

	assert_true(cm.find_data_set("other/nested_dict/nested_array/1", 20).is_ok())
	assert_false(cm.find_data_set("asdf/asdf", 123).is_ok())

	assert_eq(cm.find_data_get("other/nested_dict/nested_array/1").unwrap(), 20)

func test_save_pass():
	var metadata_file := File.new()
	assert_eq(metadata_file.open("res://tests/test_resources/test_metadata.json", File.READ), OK)

	var model_config_file := File.new()
	assert_eq(model_config_file.open("res://tests/test_resources/test_model_config.json", File.READ), OK)

	cm.metadata.parse_string(metadata_file.get_as_text())
	cm.model_config.parse_string(model_config_file.get_as_text())

	cm.model_config.config_name = "test_config"

	cm.save_data_path = temp_folder_path
	
	assert_true(cm.save_data().is_ok())

	metadata_file.close()
	model_config_file.close()

	assert_eq(metadata_file.open("%s/%s" % [temp_folder_path, cm.METADATA_FILE_NAME], File.READ), OK)
	assert_eq(model_config_file.open("%s/%s" % [temp_folder_path, "test_config.json"], File.READ), OK)

	var md := Metadata.new()
	var mc := ModelConfig.new()

	assert_true(md.parse_string(metadata_file.get_as_text()).is_ok())
	assert_true(mc.parse_string(model_config_file.get_as_text()).is_ok())

	assert_eq(md.msaa_value, cm.get_data("msaa_value"))
	assert_eq(md.python_path, cm.get_data("python_path"))
	
	assert_eq(mc.config_name, "test_config")
	assert_eq(mc.description, cm.get_data("description"))

func test_on_model_config_changed_pass():
	# Testing the additional bones key
	var dict := {
		"head": 1,
		"spine": 2,
		"blah": 3
	}
	cm.model_config.additional_bones = dict

	if not assert_eq(cm.model_config.additional_bones.size(), 3):
		return
	if not assert_eq(cm.model_config.additional_bones[1], 2):
		return

	dict["spine"] = 4
	var data := SignalPayload.new("additional_bones", dict, 1)

	cm._on_model_config_changed(data, "additional_bones")
	var bones = cm.get_data("additional_bones")
	
	if not assert_not_null(bones):
		return
	assert_eq(bones["spine"], 4)

	assert_eq(data.get_changed(), 4)
