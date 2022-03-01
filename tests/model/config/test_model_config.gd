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
	"other": {
		"type": 18,
		"value": {}
	},
	"config_name": {
		"type": 4,
		"value": "changeme"
	},
	"main_light": {
		"type": 18,
		"value": {
			"light_energy": {
				"type": 3,
				"value": 0.7
			}
		}
	}
}
"""

func test_parse_get_data_pass():
	var mc0 := ModelConfig.new()

	assert_true(mc0.parse_string(good_string0).is_ok())
	assert_true(mc0.other.empty())
	assert_eq(mc0.get_data("config_name"), "changeme")
	assert_eq(mc0.find_data("main_light/light_energy"), 0.7)

func test_roundtrip_pass():
	var mc0 := ModelConfig.new()

	assert_true(mc0.parse_string(good_string0).is_ok())

	var str0 := mc0.get_as_json_string()

	var mc1 := ModelConfig.new()

	assert_true(mc1.parse_string(str0).is_ok())

	assert_eq(mc1.get_as_json_string().replace(" ", "").strip_edges().strip_escapes(),
		mc0.get_as_json_string().replace(" ", "").strip_edges().strip_escapes())
