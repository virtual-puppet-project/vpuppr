extends "res://tests/base_test.gd"

# https://github.com/bitwes/Gut/wiki/Quick-Start

#-----------------------------------------------------------------------------#
# Builtin functions                                                           #
#-----------------------------------------------------------------------------#

func before_all():
	.before_all()

func before_each():
	tcm = TempCacheManager.new()

func after_each():
	tcm.clear()

func after_all():
	tcm = null

#-----------------------------------------------------------------------------#
# Utils                                                                       #
#-----------------------------------------------------------------------------#

#-----------------------------------------------------------------------------#
# Tests                                                                       #
#-----------------------------------------------------------------------------#

var tcm: TempCacheManager

func test_push_pull_erase_string_pass():
	var key := "my_key"
	var val := "my_value"

	var res: Result = tcm.pull(key)
	
	if not assert_result_is_err(res):
		return
	
	tcm.push(key, val)

	res = tcm.pull(key)

	if not assert_result_is_ok(res):
		return
	
	assert_eq(res.unwrap(), val)
	assert_ne(res.unwrap(), key)

	tcm.erase(key)

	res = tcm.pull(key)

	assert_result_is_err(res)

func test_push_pull_string_overwrite_pass():
	var key := "my_key"
	var val := "my_value"
	var val_alt := "my_other_value"

	tcm.push(key, val)

	var res: Result = tcm.pull(key)

	if not assert_result_is_ok(res):
		return

	assert_eq(res.unwrap(), val)

	tcm.push(key, val_alt)

	res = tcm.pull(key)

	if not assert_result_is_ok(res):
		return

	assert_eq(res.unwrap(), val_alt)
	assert_ne(res.unwrap(), val)
