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

func test_error_pass():
	var error0 := Error.new(Error.Code.CONNECT_FAILED)

	assert_eq(error0.error_code(), Error.Code.CONNECT_FAILED)
	assert_eq(error0.error_name(), "CONNECT_FAILED")
	assert_eq(error0.error_description(), "")
	assert_eq(error0.to_string(), "Code: %d\nName: %s\nDescription: %s" % [
		error0.error_code(),
		error0.error_name(),
		error0.error_description()
	])

	var error1 := Error.new(Error.Code.FILE_NOT_FOUND, "test")

	assert_eq(error1.error_code(), Error.Code.FILE_NOT_FOUND)
	assert_eq(error1.error_name(), "FILE_NOT_FOUND")
	assert_eq(error1.error_description(), "test")
