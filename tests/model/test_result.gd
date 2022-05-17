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

func test_result_ok_pass():
	var result0 := Result.new(OK)

	assert_true(result0.is_ok())
	assert_false(result0.is_err())
	assert_eq(result0.unwrap(), OK)
	assert_null(result0.unwrap_err())
	assert_eq(result0.to_string(), "OK: 0")

	var result1 := Result.ok()

	assert_true(result1.is_ok())
	assert_eq(result1.unwrap(), OK)

	var result2 := Result.ok(1)

	assert_true(result2.is_ok())
	assert_eq(result2.unwrap(), 1)

func test_result_error_pass():
	var result0 := Result.new(Error.new(Error.Code.FILE_NOT_FOUND))

	assert_false(result0.is_ok())
	assert_true(result0.is_err())
	assert_eq(result0.unwrap_err().error_code(), Error.Code.FILE_NOT_FOUND)
	assert_eq(result0.unwrap_err().error_name(), "FILE_NOT_FOUND")
	assert_null(result0.unwrap())
	assert_eq(str(result0), "ERR: %s" % "Code: %d\nName: %s\nDescription: %s" % [
		result0.unwrap_err().error_code(),
		result0.unwrap_err().error_name(),
		result0.unwrap_err().error_description()
	])

	var result1 := Result.err(Error.Code.CONNECT_FAILED, "test error")

	assert_true(result1.is_err())
	assert_eq(result1.unwrap_err().error_code(), Error.Code.CONNECT_FAILED)
	assert_eq(result1.unwrap_err().error_name(), "CONNECT_FAILED")
	assert_eq(result1.unwrap_err().error_description(), "test error")
