extends "res://addons/gut/test.gd"

func before_all():
	AM.env = Env.new(Env.Envs.TEST)
	gut.p("Test environment: %s" % AM.env.current_env, 2)
	gut.p("Setup complete", 2)

func create_class(c_name: String, data: Dictionary = {}):
	var r
	
	if ClassDB.class_exists(c_name):
		r = ClassDB.instance(r)
	else:
		r = load(c_name).new()

	for key in data.keys():
		r.set(key, data[key])

	return r
