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

func test_env_pass():
	var env0 := Env.new(Env.Envs.DEFAULT)
	
	assert_eq(env0.current_env, Env.Envs.DEFAULT)

	env0.current_env = Env.Envs.TEST

	assert_eq(env0.current_env, Env.Envs.TEST)

	env0.current_env = "wew"

	assert_eq(env0.current_env, "wew")
