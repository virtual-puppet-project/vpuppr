extends TestBase

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
	assert(output["basis"], "No 'basis' field found.")
	assert(output["origin"], "No 'origin' field found.")

	# Check basis
	assert(output["basis"]["x"]["x"] == original_basis.x.x)
	assert(output["basis"]["x"]["y"] == original_basis.x.y)
	assert(output["basis"]["x"]["z"] == original_basis.x.z)

	assert(output["basis"]["y"]["x"] == original_basis.y.x)
	assert(output["basis"]["y"]["y"] == original_basis.y.y)
	assert(output["basis"]["y"]["z"] == original_basis.y.z)

	assert(output["basis"]["z"]["x"] == original_basis.z.x)
	assert(output["basis"]["z"]["y"] == original_basis.z.y)
	assert(output["basis"]["z"]["z"] == original_basis.z.z)

	# Check origin
	assert(output["origin"]["x"] == original_origin.x)
	assert(output["origin"]["y"] == original_origin.y)
	assert(output["origin"]["z"] == original_origin.z)

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
	assert(output.basis.x.x == input["basis"]["x"]["x"])
	assert(output.basis.x.y == input["basis"]["x"]["y"])
	assert(output.basis.x.z == input["basis"]["x"]["z"])

	assert(output.basis.y.x == input["basis"]["y"]["x"])
	assert(output.basis.y.y == input["basis"]["y"]["y"])
	assert(output.basis.y.z == input["basis"]["y"]["z"])
	
	assert(output.basis.z.x == input["basis"]["z"]["x"])
	assert(output.basis.z.y == input["basis"]["z"]["y"])
	assert(output.basis.z.z == input["basis"]["z"]["z"])

	# Check origin
	assert(output.origin.x == input["origin"]["x"])
	assert(output.origin.y == input["origin"]["y"])
	assert(output.origin.z == input["origin"]["z"])

func test_color_to_dictionary() -> void:
	var json_util = JSON_UTIL.new()

	var input: Color = ColorN("salmon")

	var output: Dictionary = json_util.color_to_dictionary(input)

	# Check color
	assert(output["r"] == input.r)
	assert(output["g"] == input.g)
	assert(output["b"] == input.b)
	assert(output["a"] == input.a)

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
	assert(output.r == salmon_color.r)
	assert(output.g == salmon_color.g)
	assert(output.b == salmon_color.b)
	assert(output.a == salmon_color.a)
