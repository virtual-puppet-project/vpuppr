extends "res://addons/gut/test.gd"

func before_all():
	AM.env.current_env = Env.Envs.TEST
	gut.p("Setup complete", 2)
