extends "res://tests/base_test.gd"

const JSON_UTIL: Resource = preload("res://utils/JSONUtil.gd")

###############################################################################
# Builtin functions                                                           #
###############################################################################

func _ready() -> void:
	pass

###############################################################################
# Utils                                                                       #
###############################################################################

###############################################################################
# Tests                                                                       #
###############################################################################

func test_transform_to_dictionary() -> void:
	var json_util = JSON_UTIL.new()
	
	var original_basis: Basis = Basis()
	original_basis.x = Vector3(1, 0, 0)
	original_basis.y = Vector3(0, 1, 0)
	original_basis.z = Vector3(0, 0, 1)
	
	var original_origin: Vector3 = Vector3(1, 2, 3)
	
	var input: Transform = Transform(original_basis, original_origin)
	
	var output: Dictionary = json_util.transform_to_dictionary(input)
	
	# Check for required fields
	assert_eq_deep(output["basis"], {
		"x": { "x": 1.0, "y": 0.0, "z": 0.0 },
		"y": { "x": 0.0, "y": 1.0, "z": 0.0 },
		"z": { "x": 0.0, "y": 0.0, "z": 1.0 }
	})
	assert_eq_deep(output["origin"], { "x": 1.0, "y": 2.0, "z": 3.0 })

	# Check basis
	assert_true(output["basis"]["x"]["x"] == original_basis.x.x)
	assert_true(output["basis"]["x"]["y"] == original_basis.x.y)
	assert_true(output["basis"]["x"]["z"] == original_basis.x.z)

	assert_true(output["basis"]["y"]["x"] == original_basis.y.x)
	assert_true(output["basis"]["y"]["y"] == original_basis.y.y)
	assert_true(output["basis"]["y"]["z"] == original_basis.y.z)

	assert_true(output["basis"]["z"]["x"] == original_basis.z.x)
	assert_true(output["basis"]["z"]["y"] == original_basis.z.y)
	assert_true(output["basis"]["z"]["z"] == original_basis.z.z)

	# Check origin
	assert_true(output["origin"]["x"] == original_origin.x)
	assert_true(output["origin"]["y"] == original_origin.y)
	assert_true(output["origin"]["z"] == original_origin.z)

func test_dictionary_to_transform() -> void:
	var json_util = JSON_UTIL.new()

	var input: Dictionary = {}
	input["basis"] = {
		"x": {
			"x": 1,
			"y": 0,
			"z": 0
		},
		"y": {
			"x": 0,
			"y": 1,
			"z": 0
		},
		"z": {
			"x": 0,
			"y": 0,
			"z": 1
		}
	}
	input["origin"] = {
		"x": 1,
		"y": 2,
		"z": 3
	}

	var output: Transform = json_util.dictionary_to_transform(input)

	# Check basis
	assert_true(output.basis.x.x == input["basis"]["x"]["x"])
	assert_true(output.basis.x.y == input["basis"]["x"]["y"])
	assert_true(output.basis.x.z == input["basis"]["x"]["z"])

	assert_true(output.basis.y.x == input["basis"]["y"]["x"])
	assert_true(output.basis.y.y == input["basis"]["y"]["y"])
	assert_true(output.basis.y.z == input["basis"]["y"]["z"])
	
	assert_true(output.basis.z.x == input["basis"]["z"]["x"])
	assert_true(output.basis.z.y == input["basis"]["z"]["y"])
	assert_true(output.basis.z.z == input["basis"]["z"]["z"])

	# Check origin
	assert_true(output.origin.x == input["origin"]["x"])
	assert_true(output.origin.y == input["origin"]["y"])
	assert_true(output.origin.z == input["origin"]["z"])

func test_color_to_dictionary() -> void:
	var json_util = JSON_UTIL.new()

	var input: Color = ColorN("salmon")

	var output: Dictionary = json_util.color_to_dictionary(input)

	# Check color
	assert_true(output["r"] == input.r)
	assert_true(output["g"] == input.g)
	assert_true(output["b"] == input.b)
	assert_true(output["a"] == input.a)

func test_dictionary_to_color() -> void:
	var json_util = JSON_UTIL.new()

	var salmon_color: Color = ColorN("salmon")

	var input: Dictionary = {
		"r": salmon_color.r,
		"g": salmon_color.g,
		"b": salmon_color.b,
		"a": salmon_color.a
	}

	var output: Color = json_util.dictionary_to_color(input)

	# Check color
	assert_true(output.r == salmon_color.r)
	assert_true(output.g == salmon_color.g)
	assert_true(output.b == salmon_color.b)
	assert_true(output.a == salmon_color.a)
