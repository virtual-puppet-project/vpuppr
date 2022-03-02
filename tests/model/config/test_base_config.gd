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

# equal to good_string0 except the order of "other" is flipped
var good_string2 := """
{
	"test": "value",
	"other_key": "not_other_value",
	"other": {
		"other_array": [
			"this is a test",
			1
		],
		"other_key": "other_value",
		"other_dict": {
			"hello": "world"
		}
	}
}
"""

var bad_string0 := """
{
	"other": {},
	lul: 1
}
"""

func test_parse_get_set_data_pass():
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
	assert_null(bc1.find_data_get("other_key").unwrap()) # Finding data requires the full path
	
	assert_eq(bc1.find_data_get("other/other_key").unwrap(), "not_other_value")
	assert_eq(bc1.find_data_get("other/other_array/0").unwrap(), "this is a test")
	assert_eq(bc1.find_data_get("/other/other_dict/hello/").unwrap(), "world") # find_data_get strips leading/ending slashes
	
	assert_null(bc1.find_data_get("/").unwrap())
	assert_null(bc1.find_data_get("{").unwrap())
	assert_null(bc1.find_data_get("{/{").unwrap())

	# Order of keys is flipped
	var bc2 := BaseConfig.new()

	assert_true(bc2.parse_string(good_string2).is_ok())

	assert_eq(bc2.get_data("other_key"), "not_other_value")

	bc2.set_data("other_key", "asdf")
	assert_true(bc2.find_data_set("other/test", "changed").is_ok())

	assert_eq(bc2.get_data("other_key"), "asdf")
	assert_eq(bc2.get_data("test"), "changed")

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
	assert_null(bc1.find_data_get("other/other_array/asdf").unwrap())
	assert_null(bc1.find_data_get("other/other_dict/hello/world").unwrap())

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

func test_get_as_dict_pass():
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

func test_roundtrip_pass():

	#region good_dict0

	var bc0 := BaseConfig.new()

	assert_true(bc0.parse_dict(good_dict0).is_ok())

	var dic0 := bc0.get_as_dict()

	assert_eq(dic0.other.hello, bc0.get_data("hello"))
	assert_eq(dic0.other.some_key, bc0.get_data("some_key"))
	assert_eq(dic0.other.int_key, bc0.get_data("int_key"))

	var bc1 := BaseConfig.new()

	assert_true(bc1.parse_string(bc0.get_as_json_string()).is_ok())

	assert_eq(bc1.get_data("hello"), bc0.get_data("hello"))
	assert_eq(bc1.get_data("hello"), dic0.other.hello)
	assert_eq(bc1.get_data("hello"), good_dict0.other.hello)

	#endregion

	#region good_string0

	var bc2 := BaseConfig.new()

	assert_true(bc2.parse_string(good_string0).is_ok())

	var dic1 := bc2.get_as_dict()

	assert_eq(dic1.other.other_array[1], bc2.find_data_get("other/other_array/1").unwrap())
	assert_eq(dic1.other.test, bc2.get_data("test"))

	var bc3 := BaseConfig.new()

	assert_true(bc3.parse_string(bc2.get_as_json_string()).is_ok())

	assert_eq(bc3.find_data_get("other/other_dict/hello").unwrap(), bc2.get_data("other_dict").hello)

	#endregion
