class_name JSONUtil
extends Reference

static func vector2_to_dict(vec: Vector2) -> Dictionary:
	return {
		"x": vec.x,
		"y": vec.y
	}

static func dict_to_vector2(data: Dictionary) -> Vector2:
	return Vector2(data.x, data.y)

static func vector3_to_dict(vec: Vector3) -> Dictionary:
	return {
		"x": vec.x,
		"y": vec.y,
		"z": vec.z
	}

static func dict_to_vector3(data: Dictionary) -> Vector3:
	return Vector3(data.x, data.y, data.z)

static func transform_to_dict(transform: Transform) -> Dictionary:
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

static func dict_to_transform(data: Dictionary) -> Transform:
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

static func color_to_dict(color: Color) -> Dictionary:
	return {
		"r": color.r,
		"g": color.g,
		"b": color.b,
		"a": color.a
	}

static func dict_to_color(data: Dictionary) -> Color:
	return Color(
		data["r"],
		data["g"],
		data["b"],
		data["a"]
	)
