extends "res://tests/base_test.gd"

# https://github.com/bitwes/Gut/wiki/Quick-Start

###############################################################################
# Builtin functions                                                           #
###############################################################################

func before_all():
	pass

func before_each():
	pass

func after_each():
	pass

func after_all():
	pass

###############################################################################
# Tests                                                                       #
###############################################################################

var good_string0 := """
{
	"other": {
		"type": 18,
		"value": {}
	},
	"config_name": {
		"type": 4,
		"value": "changeme"
	},
	"main_light": {
		"type": 201,
		"value": {
			"light_energy": 0.7
		}
	}
}
"""

func test_parse_get_data():
	var mc0 := ModelConfig.new()

	assert_true(mc0.parse_string(good_string0).is_ok())
	assert_true(mc0.other.empty())
	assert_eq(mc0.get_data("config_name"), "changeme")
	assert_eq(mc0.get_nested_data("main_light/light_energy"), 0.7)
