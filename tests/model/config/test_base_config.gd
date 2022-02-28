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
# Tests                                                                       #
###############################################################################

# A BaseConfig doesn't have other fields defined besides "other",
# so all keys should be parsed into the "other" dict

var good_dict0 := {
	"other": {
		"hello": "world"
	},
	"some_key": "some_value",
	"int_key": 1,
	"float_key": 1.0
}

var good_string0 := """
{
	"other": {
		"other_array": [
			"this is a test",
			1
		],
		"other_key": "other_value",
		"other_dict": {
			"hello": "world"
		}
	},
	"test": "value",
	"other_key": "not_other_value"
}
"""

var good_string1 := """
{
	"other": {
		"hello": "world"
	},
	"test_array": [
		1
	]
}
"""

var bad_string0 := """
{
	"other": {},
	lul: 1
}
"""

func test_parse_get_data_pass():
	var bc0 := BaseConfig.new()

	assert_true(bc0.parse_dict(good_dict0).is_ok())
	assert_eq(bc0.other.hello, "world")
	assert_eq(bc0.get_data("hello"), "world") # get_data should be used instead of direct field access
	assert_eq(bc0.other.some_key, "some_value")
	assert_eq(bc0.get_data("some_key"), "some_value")
	assert_eq(bc0.other.int_key, int(1))
	assert_eq(bc0.get_data("int_key"), int(1))
	assert_eq(bc0.other.float_key, 1.0)
	assert_eq(bc0.get_data("float_key"), 1.0)

	var bc1 := BaseConfig.new()

	assert_true(bc1.parse_string(good_string0).is_ok())
	assert_eq(bc1.get_data("test"), "value")
	assert_eq(bc1.get_data("other_array")[0], "this is a test")
	assert_eq(bc1.get_data("other_array")[1], float(1))
	assert_eq(typeof(bc1.get_data("other_array")[1]), TYPE_REAL) # Raw number values parsed from a string are always floats
	assert_eq(bc1.get_data("other_dict")["hello"], "world")
	assert_ne(bc1.get_data("other_key"), "other_value") # Data stored in "other" is accessed at a lower priority
	assert_eq(bc1.get_data("other_key"), "not_other_value")
	assert_eq(bc1.get_nested_data("other/other_key"), "not_other_value")
	assert_eq(bc1.get_nested_data("other/other_array/0"), "this is a test")
	assert_eq(bc1.get_nested_data("other/other_dict/hello"), "world")

func test_parse_get_data_fail():
	var bc0 := BaseConfig.new()

	var res := bc0.parse_string(bad_string0)

	assert_false(res.is_ok())
	assert_eq(res.unwrap_err().error_code(), Error.Code.BASE_CONFIG_PARSE_FAILURE)
	assert_true(bc0.other.empty())

	var bc1 := BaseConfig.new()

	assert_true(bc1.parse_string(good_string0).is_ok())
	# Gracefully handle bad queries or missing data
	assert_null(bc1.get_data("asdf"))
	assert_null(bc1.get_nested_data("other/other_array/asdf"))
	assert_null(bc1.get_nested_data("other/other_dict/hello/world"))

func test_print_pass():
	var bc := BaseConfig.new()

	var expected_string := """
	{
		"other": {
			"hello": "world",
			"test_array": [
				1
			]
		}
	}
	"""

	assert_true(bc.parse_string(good_string1).is_ok())
	assert_eq(str(bc).strip_escapes(), expected_string.strip_escapes())

func test_as_dict_pass():
	var bc := BaseConfig.new()

	var expected := {
		"other": {
			"hello": "world",
			"test_array": [
				float(1)
			]
		}
	}

	assert_true(bc.parse_string(good_string1).is_ok())
	assert_eq_deep(bc.get_as_dict(), expected)
