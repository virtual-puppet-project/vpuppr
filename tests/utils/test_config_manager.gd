extends "res://tests/base_test.gd"

# https://github.com/bitwes/Gut/wiki/Quick-Start

###############################################################################
# Builtin functions                                                           #
###############################################################################

func before_all():
	.before_all()

func before_each():
	cm = ConfigManager.new()

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
	assert_eq(cm.find_data("other/nested_dict/nested_array/1"), 10)
	assert_eq(cm.find_data("other/nested_dict/hello"), "world")

	cm.set_data("description", "other description")

	assert_eq(cm.get_data("description"), "other description")
