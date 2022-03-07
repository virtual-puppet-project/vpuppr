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

func test_init_pass():
	var am = partial_double("res://utils/abstract_manager.gd").new()
	
	assert_called(am, "_setup_logger")
	assert_call_count(am, "_setup_logger", 1)
	assert_called(am, "_setup_class")
	assert_call_count(am, "_setup_class", 1)
	assert_eq(am.is_setup, true)
	
	am._init()
	
	assert_call_count(am, "_setup_logger", 2)
	assert_call_count(am, "_setup_class", 2)
