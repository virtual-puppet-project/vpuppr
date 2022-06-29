extends "res://addons/gut/test.gd"

const TEST_TEMP_DIR := "res://tests/temp/"

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

func assert_eq(actual, expected, text: String = "") -> bool:
	.assert_eq(actual, expected, text)

	return actual == expected

func assert_ne(actual, expected, text: String = "") -> bool:
	.assert_ne(actual, expected, text)

	return actual != expected

func assert_true(actual, text: String = "") -> bool:
	.assert_true(actual, text)

	return actual == true

func assert_false(actual, text: String = "") -> bool:
	.assert_false(actual, text)

	return actual == false

func assert_result_is_ok(actual: Result, text: String = "") -> bool:
	if not assert_not_null(actual, text):
		return false

	if not assert_true(actual.is_ok(), text):
		return false

	return true

func assert_result_is_err(actual: Result, text: String = "") -> bool:
	if not assert_not_null(actual, text):
		return false

	if not assert_true(actual.is_err(), text):
		return false
	
	return true

func assert_null(actual, text: String = "") -> bool:
	.assert_null(actual, text)

	return actual == null

func assert_not_null(actual, text: String = "") -> bool:
	.assert_not_null(actual, text)

	return actual != null
