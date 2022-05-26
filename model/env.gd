class_name Env
extends Reference

## The default environment variable name
const ENV_VAR_NAME := "VSS_ENV"

## The list of recognized environments
const Envs := {
	"DEFAULT": "default",
	"TEST": "test"
}

## The current environment in use
var current_env: String

func _init(p_current_env: String = "") -> void:
	if not p_current_env.empty():
		current_env = p_current_env
	else:
		var system_env = OS.get_environment(ENV_VAR_NAME)
		current_env = system_env if system_env else Envs.DEFAULT
