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

func test_debounce_save_pass():
	# We cannot use a partial double here since simulate(...) doesn't appear to actually call _process
	var am = AppManager.new()
	am.env = Env.new(Env.Envs.TEST)

	add_child_autoqfree(am)

	var cm = double("res://utils/config_manager.gd").new()
	stub(cm, "load_data").to_return(Result.ok())
	stub(cm, "save_data").to_return(Result.ok())
	stub(cm, "_register_all_configs_with_pub_sub").to_return(Result.ok())
	am.cm = cm

	assert_false(am.should_save)
	assert_eq(am.debounce_counter, 0.0)

	am.save_config()

	assert_true(am.should_save)

	gut.simulate(am, 1, 0.1)

	assert_eq(am.debounce_counter, 0.1)
	assert_true(am.should_save)

	gut.simulate(am, 3, 10.0)

	assert_false(am.should_save)
	assert_eq(am.debounce_counter, 0.0)

	assert_called(cm, "save_data")
	assert_call_count(cm, "save_data", 1)

	am.save_config()

	assert_true(am.should_save)

	gut.simulate(am, 3, 10.0)

	assert_false(am.should_save)

	assert_call_count(cm, "save_data", 2)
