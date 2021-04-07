class_name JSONUtil
extends Reference

###############################################################################
# Builtin functions                                                           #
###############################################################################

###############################################################################
# Connections                                                                 #
###############################################################################

###############################################################################
# Private functions                                                           #
###############################################################################

###############################################################################
# Public functions                                                            #
###############################################################################

static func transform_to_dictionary(transform: Transform) -> Dictionary:
	var result: Dictionary = {}
	
	result["basis"] = {
		"x": {
			"x": transform.basis.x.x,
			"y": transform.basis.x.y,
			"z": transform.basis.x.z
		},
		"y": {
			"x": transform.basis.y.x,
			"y": transform.basis.y.y,
			"z": transform.basis.y.z
		},
		"z": {
			"x": transform.basis.z.x,
			"y": transform.basis.z.y,
			"z": transform.basis.z.z
		}
	}
	
	result["origin"] = {
		"x": transform.origin.x,
		"y": transform.origin.y,
		"z": transform.origin.z
	}
	
	return result

static func dictionary_to_transform(data: Dictionary) -> Transform:
	var result: Transform = Transform()
	
	result.basis.x.x = data["basis"]["x"]["x"]
	result.basis.x.y = data["basis"]["x"]["y"]
	result.basis.x.z = data["basis"]["x"]["z"]
	
	result.basis.y.x = data["basis"]["y"]["x"]
	result.basis.y.y = data["basis"]["y"]["y"]
	result.basis.y.z = data["basis"]["y"]["z"]
	
	result.basis.z.x = data["basis"]["z"]["x"]
	result.basis.z.y = data["basis"]["z"]["y"]
	result.basis.z.z = data["basis"]["z"]["z"]
	
	result.origin.x = data["origin"]["x"]
	result.origin.y = data["origin"]["y"]
	result.origin.z = data["origin"]["z"]
	
	return result

static func color_to_dictionary(color: Color) -> Dictionary:
	return {
		"r": color.r,
		"g": color.g,
		"b": color.b,
		"a": color.a
	}

static func dictionary_to_color(data: Dictionary) -> Color:
	return Color(
		data["r"],
		data["g"],
		data["b"],
		data["a"]
	)
