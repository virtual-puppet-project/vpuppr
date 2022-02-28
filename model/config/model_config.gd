class_name ModelConfig
extends BaseConfig

enum CustomTypes {
	NONE = 200,
	
	MAIN_LIGHT,
	MAIN_WORLD_ENVIRONMENT
}

#region Metadata

var config_name := "changeme"
var description := "changeme"
var hotkey := ""
var notes := ""
# Models can have 1-many configs
# The setter automatically flags the value as dirty when changed
var is_default_for_model := false setget _set_is_default_for_model
# Whether or not the default config in Metadata needs to be changed
var is_default_dirty := false

var model_name := "changeme"
var model_path := "changeme"

#endregion

#region Model

var additional_bones := [] # Bone id: int
var bone_transforms := {} # Bone name: String -> Bone transform: Transform
var model_transform := Transform()
var model_parent_transform := Transform()

#endregion

#region Tracking

# Damping values for various tracker values
var translation_damp: float = 0.3
var rotation_damp: float = 0.02
var additional_bone_damp: float = 0.3

# This is always overridden when loading a VRM file
var head_bone := "head"

var apply_translation := false
var apply_rotation := true

#region Interpolation

var interpolate_global := true
var base_interpolation_rate := 0.1

# Overrideable interpolation values that ignore interpolate_global
var interpolate_bones := false
var bone_interpolation_rate := 0.1
var interpolate_gaze := false
var gaze_interpolation_rate := 0.1
var interpolate_blinks := false
var blinks_interpolation_rate := 0.1
var interpolate_mouth := true # NOTE It's better to use rawer data for mouth
var mouth_interpolation_rate := 0.8
var interpolate_eyebrows := false
var eyebrow_interpolation_rate := 0.1

#endregion

var should_track_eye := true
var gaze_strength := 0.5
var blink_threshold := 0.2
var link_eye_blinks := false
var use_raw_eye_rotation := false

#region Mouth tracking values

var mouth_open_max: float = 2.0
var mouth_open_group_1: float = 0.25
var mouth_open_group_2: float = 0.3
var mouth_wide_max: float = 2.0
var mouth_wide_group_1: float = 0.25
var mouth_wide_group_2: float = 0.3

#endregion

#region Launch tracker values

var tracker_should_launch := true
var tracker_fps: int = 12
var tracker_address := "127.0.0.1"
var tracker_port: int = 11573

#endregion

#endregion

#region Features

class MainLight extends BaseConfig:
	var light_color := Color.white
	var light_energy: float = 0.7
	var light_indirect_energy: float = 1.0
	var light_specular: float = 0.0
	var shadow_enabled := true

var main_light := MainLight.new()

class MainWorldEnvironment extends BaseConfig:
	var ambient_light_color := Color.black
	var ambient_light_energy: float = 0.5
	var ambient_light_sky_contribution: float = 1.0

var main_world_environment := MainWorldEnvironment.new()

var instanced_props := {} # Prop name: String -> PropData

#endregion

class DataPoint:
	const TYPE_KEY := "type"
	const VALUE_KEY := "value"
	
	var data_type: int
	var data_value

	func _init(dt: int, dv) -> void:
		data_type = dt
		data_value = dv

	func get_as_dict() -> Dictionary:
		return {
			TYPE_KEY: data_type,
			VALUE_KEY: data_value
		}

###############################################################################
# Builtin functions                                                           #
###############################################################################

###############################################################################
# Connections                                                                 #
###############################################################################

###############################################################################
# Private functions                                                           #
###############################################################################

func _set_is_default_for_model(value: bool) -> void:
	if is_default_for_model != value:
		is_default_for_model = value
		is_default_dirty = true


func _marshal_data(data) -> Result:
	if data is Result:
		return data
	if data == null:
		return Result.err(Error.Code.NULL_VALUE)

	match typeof(data):
		TYPE_COLOR:
			return Result.ok(JSONUtil.color_to_dictionary(data))
		TYPE_TRANSFORM:
			return Result.ok(JSONUtil.transform_to_dictionary(data))
		TYPE_DICTIONARY:
			var r := {}

			for key in data.keys():
				var result := _marshal_data(data[key])
				if result.is_err():
					return result
				r[key] = result.unwrap()

			return Result.ok(r)
		TYPE_ARRAY:
			var r := []

			for v in data:
				var result := _marshal_data(v)
				if result.is_err():
					return result
				r.append(result.unwrap())

			return Result.ok(r)
		TYPE_OBJECT:
			return Result.ok(data.get_as_dict())
		_:
			return Result.ok(data)

func _unmarshal_data(data_type: int, data_value) -> Result:
	if data_value is Result:
		return data_value
	if data_value == null:
		return Result.err(Error.Code.NULL_VALUE)

	match data_type:
		TYPE_COLOR:
			return Result.ok(JSONUtil.dictionary_to_color(data_value))
		TYPE_TRANSFORM:
			return Result.ok(JSONUtil.dictionary_to_transform(data_value))
		TYPE_DICTIONARY:
			var r := {}

			for key in data_value.keys():
				var data_point = data_value[key]
				var result := _unmarshal_data(data_point[DataPoint.TYPE_KEY], data_point[DataPoint.VALUE_KEY])
				if result.is_err():
					return result

				r[key] = result.unwrap()

			return Result.ok(r)
		TYPE_ARRAY:
			var r := []

			for point in data_value:
				var result := _unmarshal_data(point[DataPoint.TYPE_KEY], point[DataPoint.VALUE_KEY])
				if result.is_err():
					return result

				r.append(result.unwrap())

			return Result.ok(r)
		CustomTypes.MAIN_LIGHT:
			var ml := MainLight.new()
			var result := ml.parse_dict(data_value)
			if result.is_err():
				return result
			return Result.ok(ml)
		CustomTypes.MAIN_WORLD_ENVIRONMENT:
			var mwe := MainWorldEnvironment.new()
			var result := mwe.parse_dict(data_value)
			if result.is_err():
				return result
			return Result.ok(mwe)
		_:
			return Result.ok(data_value)

func _normalize_data_type(data) -> int:
	var type := typeof(data)

	if type == TYPE_OBJECT:
		if data is MainLight:
			type = CustomTypes.MAIN_LIGHT
		elif data is MainWorldEnvironment:
			type = CustomTypes.MAIN_WORLD_ENVIRONMENT
	
	return type

###############################################################################
# Public functions                                                            #
###############################################################################

func get_as_dict() -> Dictionary:
	var r := {}

	for i in get_property_list():
		if i.name in GlobalConstants.IGNORED_PROPERTIES_REFERENCE:
			continue

		var data_value = get(i.name)

		var result := _marshal_data(data_value)
		if result.is_err():
			AM.logger.error(str(result.unwrap_err()))
			continue

		r[i.name] = DataPoint.new(_normalize_data_type(data_value), result.unwrap()).get_as_dict()

	return r

func parse_dict(data: Dictionary) -> Result:
	for key in data.keys():
		var data_point = data[key]

		if typeof(data_point) != TYPE_DICTIONARY:
			AM.logger.error("Invalid data point loaded: %s, bailing out" % str(data_point))
			return Result.err(Error.Code.MODEL_CONFIG_UNEXPECTED_DATA)

		var result := _unmarshal_data(data_point[DataPoint.TYPE_KEY], data_point[DataPoint.VALUE_KEY])
		if result.is_err():
			return result

		set(key, result.unwrap())

	return Result.ok()
