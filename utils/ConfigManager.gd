extends Reference

const DEMO_MODEL_PATH: String = "res://entities/basic-models/Duck.tscn"

const CONFIG_FORMAT: String = "%s/%s.json"

const METADATA_NAME: String = "app-config.json"
var metadata_path: String = ""
var metadata_config := Metadata.new()

var has_loaded_metadata := false

class Metadata:
	var default_model_to_load_path: String = ""
	var default_search_path: String = "/"
	var should_use_portable_config_files: bool = false
	
	# TODO load in all config data at the start?
	# Config name to config path
	var config_data: Dictionary = {} # String: String

	# Model file name to config name
	var model_defaults: Dictionary = {} # String: String

	func load_from_json(json_string: String) -> bool:
		var json_data = parse_json(json_string)

		if typeof(json_data) != TYPE_DICTIONARY:
			AppManager.log_message("Invalid metadata loaded, using default metadata values", true)
			return false
		
		default_model_to_load_path = json_data["default_model_to_load_path"]
		default_search_path = json_data["default_search_path"]
		should_use_portable_config_files = json_data["should_use_portable_config_files"]
		config_data = json_data["config_data"]
		model_defaults = json_data["model_defaults"]

		return true
	
	func get_as_json() -> String:
		return to_json({
			"default_model_to_load_path": default_model_to_load_path,
			"default_search_path": default_search_path,
			"should_use_portable_config_files": should_use_portable_config_files,
			"config_data": config_data,
			"model_defaults": model_defaults
		})

var current_model_config: ConfigData

class ConfigData:
	###
	# Metadata
	###
	var config_name: String = "changeme"
	var description: String = "changeme"
	var hotkey: String = ""
	var notes: String = ""
	var is_default_for_model := false

	var model_name: String = "changeme"
	var model_path: String = "changeme"

	###
	# Model
	###
	var mapped_bones: Array = [] # String
	var bone_transforms: Dictionary = {} # String: Transform
	var model_transform := Transform()
	var model_parent_transform := Transform()

	###
	# Face tracking
	###
	var translation_damp: float = 0.3
	var rotation_damp: float = 0.02
	var additional_bone_damp: float = 0.3

	var head_bone: String = "head"
	var apply_translation: bool = false
	var apply_rotation: bool = true

	var interpolate_model: bool = true
	var interpolation_rate: float = 0.1

	var should_track_eye: bool = true
	var gaze_strength: float = 0.5

	###
	# Feature
	###
	var main_light: Dictionary = {
		"light_color": Color.white,
		"light_energy": 0.7,
		"light_indirect_energy": 1.0,
		"light_specular": 0.0,
		"shadow_enabled": true
	}

	var world_environment: Dictionary = {
		"ambient_light_color": Color.black,
		"ambient_light_energy": 0.5,
		"ambient_light_sky_contribution": 1.0
	}

	var instanced_props: Dictionary = {} # String, Dictionary (PropData)

	func get_as_dict() -> Dictionary:
		"""
		Iterate through all variables using reflection, convert variables
		into dictionaries if needed, and then return a dictionary of those variables
		"""
		var result: Dictionary = {}

		for i in get_property_list():
			if not i.name in ["Reference", "script", "Script Variables"]:
				var data_point := DataPoint.new()
				var i_value = get(i.name)

				data_point.data_type = typeof(i_value)
				match data_point.data_type:
					TYPE_COLOR:
						i_value = JSONUtil.color_to_dictionary(i_value)
					TYPE_TRANSFORM:
						i_value = JSONUtil.transform_to_dictionary(i_value)
					TYPE_DICTIONARY:
						for key in i_value.keys():
							match typeof(i_value[key]):
								TYPE_TRANSFORM:
									i_value[key] = JSONUtil.transform_to_dictionary(i_value[key])
								TYPE_COLOR:
									i_value[key] = JSONUtil.color_to_dictionary(i_value[key])
								_:
									# Do nothing
									pass
						# if i_value.size() > 0:
						# 	# Handle dictionaries of transforms
						# 	if typeof(i_value[i_value.keys()[0]]) == TYPE_TRANSFORM:
						# 		for key in i_value.keys():
						# 			i_value[key] = JSONUtil.transform_to_dictionary(i_value[key])
					_:
						# Do nothing
						pass
				
				data_point.data_value = i_value

				result[i.name] = data_point.get_as_dict()

		return result

	func load_from_json(json_string: String) -> void:
		"""
		Converts json string to a dictionary with the appropriate values
		"""
		var json_result = parse_json(json_string)

		if typeof(json_result) != TYPE_DICTIONARY:
			AppManager.log_message("Invalid config data loaded", true)
			return
		
		for key in (json_result as Dictionary).keys():
			var data = json_result[key]

			if typeof(data) != TYPE_DICTIONARY:
				AppManager.log_message("Invalid data point loaded", true)
				return
			
			var data_value = data[DataPoint.VALUE_KEY]

			match int(data[DataPoint.TYPE_KEY]):
				TYPE_COLOR:
					data_value = JSONUtil.dictionary_to_color(data_value)
				TYPE_TRANSFORM:
					data_value = JSONUtil.dictionary_to_transform(data_value)
				_:
					pass
			
			set(key, data_value)

	func load_from_dict(json_dict: Dictionary) -> void:
		"""
		Since we are using the class as a struct, we can't just set the
		dict to a value
		"""
		for key in json_dict.keys():
			set(key, json_dict[key])

class DataPoint:
	"""
	Each field in the saved json must follow this format
	"""
	const TYPE_KEY: String = "type"
	const VALUE_KEY: String = "value"

	var data_type: int
	var data_value

	func get_as_dict() -> Dictionary:
		return {
			TYPE_KEY: data_type,
			VALUE_KEY: data_value
		}

###############################################################################
# Builtin functions                                                           #
###############################################################################

func _init() -> void:
	if not OS.is_debug_build():
		# TODO maybe not do this?
		# metadata_path = OS.get_executable_path().get_base_dir()
		metadata_path = "user://"
	else:
		metadata_path = "res://export"

###############################################################################
# Connections                                                                 #
###############################################################################

###############################################################################
# Private functions                                                           #
###############################################################################

func _load_metadata() -> bool:
	AppManager.log_message("Begin loading metadata")

	var file_path = "%s/%s" % [metadata_path, METADATA_NAME]

	var dir := Directory.new()
	if not dir.file_exists(file_path):
		AppManager.log_message("%s does not exist" % file_path)
		return false

	var metadata_file := File.new()
	metadata_file.open(file_path, File.READ)

	if not metadata_config.load_from_json(metadata_file.get_as_text()):
		AppManager.log_message("Failed to load metadata file")
		return false

	metadata_file.close()
	
	AppManager.log_message("Finished loading metadata")

	return true

###############################################################################
# Public functions                                                            #
###############################################################################

func setup() -> void:
	if not _load_metadata():
		var file_path = "%s/%s" % [metadata_path, METADATA_NAME]

		var metadata_file := File.new()
		metadata_file.open(file_path, File.WRITE)

		metadata_file.store_string(metadata_config.get_as_json())

		metadata_file.close()
	
	if metadata_config.default_model_to_load_path.empty():
		metadata_config.default_model_to_load_path = DEMO_MODEL_PATH

	has_loaded_metadata = true

func load_config(model_path: String) -> void:
	var model_name: String = model_path.get_file()
	var full_path: String = CONFIG_FORMAT % [metadata_path, model_name]

	AppManager.log_message("Begin loading config for %s" % full_path)

	current_model_config = ConfigData.new()

	var dir := Directory.new()
	if not dir.file_exists(full_path):
		AppManager.log_message("%s does not exist" % full_path)
		current_model_config.config_name = model_name
		current_model_config.model_name = model_name
		current_model_config.model_path = model_path
		return

	# var config_file := File.new()
	# config_file.open(full_path, File.READ)
	# current_model_config.load_from_json(config_file.get_as_text())
	current_model_config.load_from_dict(get_config_as_dict(full_path))
	# config_file.close()

	AppManager.log_message("Finished loading config")

func save_config() -> void:
	AppManager.log_message("Saving config")
	var config_name = current_model_config.config_name
	var model_name = current_model_config.model_name
	var is_default = current_model_config.is_default_for_model

	var config_path := CONFIG_FORMAT % [metadata_path, config_name]

	metadata_config.config_data[config_name] = config_path

	if metadata_config.model_defaults.has(model_name):
		if is_default:
			metadata_config.model_defaults[model_name] = config_name
	else:
		current_model_config.is_default_for_model = true
		metadata_config.model_defaults[model_name] = config_name
	
	var config_file := File.new()
	config_file.open(config_path, File.WRITE)
	config_file.store_string(to_json(current_model_config.get_as_dict()))
	config_file.close()

	var metadata_file := File.new()
	metadata_file.open("%s/%s" % [metadata_path, METADATA_NAME], File.WRITE)
	metadata_file.store_string(metadata_config.get_as_json())
	metadata_file.close()

	AppManager.log_message("Finished saving config")

func get_config_as_dict(config_path: String) -> Dictionary:
	var result: Dictionary = {}

	var config_file := File.new()
	config_file.open(config_path, File.READ)

	var json_dict = parse_json(config_file.get_as_text())
	config_file.close()
	if typeof(json_dict) != TYPE_DICTIONARY:
		AppManager.log_message("Invalid config data loaded", true)
		return {}

	for key in json_dict.keys():
		var data = json_dict[key]

		if typeof(data) != TYPE_DICTIONARY:
			AppManager.log_message("Invalid data point loaded", true)
			return {}

		var data_value = data[DataPoint.VALUE_KEY]

		match int(data[DataPoint.TYPE_KEY]):
			TYPE_COLOR:
				data_value = JSONUtil.dictionary_to_color(data_value)
			TYPE_TRANSFORM:
				data_value = JSONUtil.dictionary_to_transform(data_value)
			_:
				pass

		result[key] = data_value

	return result

func update_config_from_dict(old_name: String, new_config: Dictionary) -> void:
	"""
	Assume that the config name has changed, regardless of whether or not that is true

	Store all information in the old config file
	Move the file if necessary (because the name was changed)
	"""
	var config_name: String = new_config["config_name"]
	var model_name: String = new_config["model_name"]
	var is_default: bool = new_config["is_default_for_model"]
	
	var config_path := CONFIG_FORMAT % [metadata_path, old_name]

	# NOTE necessary because we can't just store the raw dictionary
	var cd := ConfigData.new()
	cd.load_from_dict(new_config)

	var config_file := File.new()
	config_file.open(config_path, File.WRITE)
	config_file.store_string(to_json(cd.get_as_dict()))

	var should_resave_metadata := false
	if config_name != old_name:
		should_resave_metadata = true
		var new_config_path := CONFIG_FORMAT % [metadata_path, config_name]
		var dir := Directory.new()
		dir.rename(config_path, new_config_path)

		metadata_config.config_data.erase(old_name)
		metadata_config.config_data[config_name] = new_config

	if is_default:
		should_resave_metadata = true
		metadata_config.model_defaults[model_name] = config_name

	if should_resave_metadata:
		var metadata_file := File.new()
		metadata_file.open("%s/%s" % [metadata_path, METADATA_NAME], File.WRITE)
		metadata_file.store_string(metadata_config.get_as_json())
		metadata_file.close()
