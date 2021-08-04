extends Reference

const DEMO_MODEL_PATH: String = "res://entities/basic-models/Duck.tscn"

const METADATA_NAME: String = "app-config.json"
var metadata_path: String = ""
var metadata_config := Metadata.new()

var has_loaded_metadata := false

class Metadata:
	var default_model_to_load_path: String = ""
	var default_search_path: String = "/"
	var should_use_portable_config_files: bool = false
	
	# Config name to config path
	var model_data: Dictionary = {} # String: String

	# Model name to config name
	var model_defaults: Dictionary = {} # String: String

	func load_from_json(json_string: String) -> bool:
		var json_data = parse_json(json_string)

		if typeof(json_data) != TYPE_DICTIONARY:
			AppManager.log_message("Invalid metadata loaded, using default metadata values", true)
			return false
		
		default_model_to_load_path = json_data["default_model_to_load_path"]
		default_search_path = json_data["default_search_path"]
		should_use_portable_config_files = json_data["should_use_portable_config_files"]
		model_data = json_data["model_data"]
		model_defaults = json_data["model_defaults"]

		return true
	
	func get_as_json() -> String:
		return to_json({
			"default_model_to_load_path": default_model_to_load_path,
			"default_search_path": default_search_path,
			"should_use_portable_config_files": should_use_portable_config_files,
			"model_data": model_data,
			"model_defaults": model_defaults
		})

var current_model_config: ConfigData

class ConfigData:
	###
	# Metadata
	###
	var config_name: String = "changeme"
	var model_name: String = "changeme"
	var is_default_for_model := false

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

	###
	# Feature
	###
	var main_light_light_color := Color.white
	var main_light_energy: float = 0.0
	var main_light_light_indirect_energy: float = 0.0
	var main_light_light_specular: float = 0.0
	var main_light_shadow_enabled: float = true

	var world_environment_ambient_light_color := Color.white
	var world_environment_ambient_light_energy: float = 0.0
	var world_environment_ambient_light_sky_contribution: float = 0.0

	var instanced_props: Array = []

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
						if i_value.size() > 0:
							# Handle dictionaries of transforms
							if typeof(i_value[i_value.keys()[0]]) == TYPE_TRANSFORM:
								for key in i_value.keys():
									i_value[key] = JSONUtil.transform_to_dictionary(i_value[key])
					_:
						# Do nothing
						pass
				
				data_point.data_value = i_value

				result[i.name] = data_point.get_as_dict()

		return result

	func load_from_json(json_string: String) -> void:
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

			match data[DataPoint.TYPE_KEY]:
				TYPE_COLOR:
					data_value = JSONUtil.dictionary_to_color(data_value)
				TYPE_TRANSFORM:
					data_value = JSONUtil.dictionary_to_transform(data_value)
			
			set(key, data_value)

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

	if metadata_config.model_defaults.has(metadata_config.default_model_to_load_path):
		load_config(metadata_config.model_defaults[metadata_config.default_model_to_load_path])
	else:
		current_model_config = ConfigData.new()

func load_config(path: String) -> void:
	AppManager.log_message("Begin loading config for %s" % path)

	current_model_config = ConfigData.new()

	var dir := Directory.new()
	if not dir.file_exists(path):
		AppManager.log_message("%s does not exist" % path)
		return

	var config_file := File.new()
	config_file.open(path, File.READ)
	current_model_config.load_from_json(config_file.get_as_text())
	config_file.close()

func save_config() -> void:
	AppManager.log_message("Saving config")
	var config_name = current_model_config.config_name
	var model_name = current_model_config.model_name
	var is_default = current_model_config.is_default_for_model

	var config_path := "%s/%s" % [metadata_path, config_name]

	metadata_config.model_data[config_name] = config_path

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

	AppManager.log_message("Config saved")
