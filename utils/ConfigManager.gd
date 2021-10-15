extends Reference

const DEMO_MODEL_PATH: String = "res://entities/basic-models/Duck.tscn"

const CONFIG_FORMAT: String = "%s/%s.json"

const METADATA_NAME: String = "app-config.json"
var metadata_path: String = ""
var metadata_config := Metadata.new()

var has_loaded_metadata := false

const DEBOUNCE_TIME: float = 0.5
var should_save := false

class Metadata:
	var default_model_to_load_path: String = ""
	var default_search_path: String = "/"
	var should_use_portable_config_files: bool = false

	# Antialiasing
	var use_transparent_background: bool = true # Cannot use with fxaa
	var use_fxaa: bool = false
	var msaa_value: bool = false # TODO change this to be specific values 
	
	# Config name to config path
	var config_data: Dictionary = {} # String: String

	# Model file name to config name
	var model_defaults: Dictionary = {} # String: String

	# Not stored as an int since we can guarantee that this value
	# will always come as a String
	var camera_index: String = "0"

	func load_from_json(json_string: String) -> bool:
		var json_data = parse_json(json_string)

		if typeof(json_data) != TYPE_DICTIONARY:
			AppManager.log_message("Invalid metadata loaded, using default metadata values", true)
			return false
		
		for key in (json_data as Dictionary).keys():
			var data = json_data[key]

			set(key, data)

		return true
	
	func get_as_json() -> String:
		var result: Dictionary = {}
		for i in get_property_list():
			if i.name in ["Reference", "script", "Script Variables"]:
				continue
			result[i.name] = get(i.name)

		return to_json(result)
	
	func apply_rendering_changes(viewport: Viewport) -> void:
		viewport.transparent_bg = use_transparent_background
		viewport.fxaa = use_fxaa
		if msaa_value: # TODO change this to be specific values
			viewport.msaa = Viewport.MSAA_4X
		else:
			viewport.msaa = Viewport.MSAA_DISABLED

var current_model_config: ConfigData

class ConfigData:
	###
	# Metadata
	###
	var config_name: String = "changeme"
	var description: String = "changeme"
	var hotkey: String = ""
	var notes: String = ""
	var is_default_for_model := false setget _set_is_default_for_model
	var is_default_dirty := false

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

	var tracker_fps: int = 12

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

	func _set_is_default_for_model(value: bool) -> void:
		if is_default_for_model != value:
			is_default_for_model = value
			is_default_dirty = true

	func get_as_dict() -> Dictionary:
		"""
		Iterate through all variables using reflection, convert variables
		into dictionaries if needed, and then return a dictionary of those variables
		"""
		var result: Dictionary = {}

		for i in get_property_list():
			if not i.name in ["Reference", "script", "Script Variables", "is_default_dirty"]:
				var data_point := DataPoint.new()
				var i_value = get(i.name)

				data_point.data_type = typeof(i_value)
				match data_point.data_type:
					TYPE_COLOR:
						i_value = JSONUtil.color_to_dictionary(i_value)
					TYPE_TRANSFORM:
						i_value = JSONUtil.transform_to_dictionary(i_value)
					TYPE_DICTIONARY:
						# Dicts are guaranteed to be only 1 dict nested deep
						i_value = i_value.duplicate(true)
						for key in i_value.keys():
							var i_data_point := DataPoint.new()
							i_data_point.data_type = typeof(i_value[key])
							match i_data_point.data_type:
								TYPE_TRANSFORM:
									i_data_point.data_value = JSONUtil.transform_to_dictionary(i_value[key])
								TYPE_COLOR:
									i_data_point.data_value = JSONUtil.color_to_dictionary(i_value[key])
								_:
									i_data_point.data_value = i_value[key]
							i_value[key] = i_data_point.get_as_dict()
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
				TYPE_DICTIONARY:
					# Dicts are guaranteed to be only 1 dict nested deep
					data_value = data_value.duplicate()
					for key_i in data_value.keys():
						var i_data_value = data_value[key_i][DataPoint.VALUE_KEY]
						match int(data_value[key_i][DataPoint.TYPE_KEY]):
							TYPE_COLOR:
								i_data_value = JSONUtil.dictionary_to_color(i_data_value)
							TYPE_TRANSFORM:
								i_data_value = JSONUtil.dictionary_to_transform(i_data_value)
						data_value[key_i] = i_data_value
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

	func duplicate() -> ConfigData:
		var cd = ConfigData.new()
		for i in get_property_list():
			if not i.name in ["Reference", "script", "Script Variables"]:
				var i_value = get(i.name)

				cd.set(i.name, i_value)

		return cd

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

	# Model

	AppManager.sb.connect("set_model_as_default", self, "_on_set_model_as_default")

	# Tracking

	AppManager.sb.connect("translation_damp", self, "_on_translation_damp")
	AppManager.sb.connect("rotation_damp", self, "_on_rotation_damp")
	AppManager.sb.connect("additional_bone_damp", self, "_on_additional_bone_damp")

	AppManager.sb.connect("head_bone", self, "_on_head_bone")

	AppManager.sb.connect("apply_translation", self, "_on_apply_translation")
	AppManager.sb.connect("apply_rotation", self, "_on_apply_rotation")

	AppManager.sb.connect("interpolate_model", self, "_on_interpolate_model")
	AppManager.sb.connect("interpolation_rate", self, "_on_interpolation_rate")

	AppManager.sb.connect("should_track_eye", self, "_on_should_track_eye")
	AppManager.sb.connect("gaze_strength", self, "_on_gaze_strength")

	AppManager.sb.connect("camera_select", self, "_on_camera_select")

	# Features

	AppManager.sb.connect("main_light", self, "_on_main_light")
	AppManager.sb.connect("world_environment", self, "_on_environment")

	# Presets

	# App settings

	AppManager.sb.connect("default_search_path", self, "_on_default_search_path")

###############################################################################
# Connections                                                                 #
###############################################################################

# Model

func _on_set_model_as_default() -> void:
	metadata_config.default_model_to_load_path = current_model_config.model_path

# Tracking

func _on_translation_damp(value: float) -> void:
	current_model_config.translation_damp = value

func _on_rotation_damp(value: float) -> void:
	current_model_config.rotation_damp = value

func _on_additional_bone_damp(value: float) -> void:
	current_model_config.additional_bone_damp = value

func _on_head_bone(value: String) -> void:
	current_model_config.head_bone = value

func _on_apply_translation(value: bool) -> void:
	current_model_config.apply_translation = value

func _on_apply_rotation(value: bool) -> void:
	current_model_config.apply_rotation = value

func _on_interpolate_model(value: bool) -> void:
	current_model_config.interpolate_model = value

func _on_interpolation_rate(value: float) -> void:
	current_model_config.interpolation_rate = value

func _on_should_track_eye(value: float) -> void:
	current_model_config.should_track_eye = value

func _on_gaze_strength(value: float) -> void:
	current_model_config.gaze_strength = value

func _on_camera_select(camera_index: String) -> void:
	metadata_config.camera_index = camera_index

# Features

func _on_main_light(prop_name: String, value) -> void:
	current_model_config.main_light[prop_name] = value

func _on_environment(prop_name: String, value) -> void:
	current_model_config.world_environment[prop_name] = value

# Presets

# App settings

func _on_default_search_path(value: String) -> void:
	metadata_config.default_search_path = value

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

func _normalize_default_configs(p_config_name: String, p_model_name: String) -> void:
	for config_name in metadata_config.config_data.keys():
		var path: String = metadata_config.config_data[config_name]
		var data: ConfigData = load_config_for_preset(path)
		if (data.model_name == p_model_name and data.config_name != p_config_name):
			data.is_default_for_model = false
			save_config(data)

###############################################################################
# Public functions                                                            #
###############################################################################

func setup() -> void:
	if not _load_metadata():
		var output: Array = []
		match OS.get_name().to_lower():
			"windows":
				OS.execute("echo", ["%HOMEDRIVE%%HOMEPATH%"], true, output)
			"osx", "x11":
				OS.execute("echo", ["$HOME"], true, output)
		if output.size() == 1:
			metadata_config.default_search_path = output[0].strip_edges()

		var file_path = "%s/%s" % [metadata_path, METADATA_NAME]

		var metadata_file := File.new()
		metadata_file.open(file_path, File.WRITE)

		metadata_file.store_string(metadata_config.get_as_json())

		metadata_file.close()
	
	if metadata_config.default_model_to_load_path.empty():
		metadata_config.default_model_to_load_path = DEMO_MODEL_PATH

	has_loaded_metadata = true

func load_config_for_preset(preset_name: String) -> ConfigData:
	var full_path: String = preset_name
	if not full_path.is_abs_path():
		full_path = CONFIG_FORMAT % [metadata_path, preset_name]
	var config := ConfigData.new()
	
	var dir := Directory.new()
	if not dir.file_exists(full_path):
		AppManager.log_message("%s does not exist" % full_path, true)
		config.config_name = "invalid"
		config.model_name = "invalid"
		config.model_path = "invalid"
		return config
	
	var config_file := File.new()
	if config_file.open(full_path, File.READ) != OK:
		AppManager.log_message("Unable to open file at path: %s" % full_path, true)
		config.config_name = "invalid"
		config.model_name = "invalid"
		config.model_path = "invalid"
		return config
	config.load_from_json(config_file.get_as_text())
	config_file.close()
	
	return config

func load_config_and_set_as_current(model_path: String) -> void:
	var model_name: String = model_path.get_file().get_basename()
	var config_name: String = model_name
	if metadata_config.model_defaults.has(model_name):
		config_name = metadata_config.model_defaults[model_name]
	var full_path: String = CONFIG_FORMAT % [metadata_path, config_name]

	AppManager.log_message("Begin loading config for %s" % full_path)

	current_model_config = ConfigData.new()

	var dir := Directory.new()
	if not dir.file_exists(full_path):
		AppManager.log_message("%s does not exist" % full_path)
		current_model_config.config_name = model_name
		current_model_config.model_name = model_name
		current_model_config.model_path = model_path
		current_model_config.is_default_for_model = true # We can assume there are no defaults
		save_config(current_model_config)
		AppManager.sb.broadcast_new_preset(model_name)
		return

	var config_file := File.new()
	config_file.open(full_path, File.READ)
	current_model_config.load_from_json(config_file.get_as_text())
	config_file.close()

	AppManager.log_message("Finished loading config")

func save_config(p_config: ConfigData = null) -> void:
	AppManager.log_message("Saving config")

	var config: ConfigData
	if p_config:
		config = p_config.duplicate()
	else:
		# TODO this is gross
		var model = AppManager.main.model_display_screen.model
		var model_parent = AppManager.main.model_display_screen.model_parent
		current_model_config.model_transform = model.transform
		current_model_config.model_parent_transform = model_parent.transform

		for bone_index in model.skeleton.get_bone_count() - 1:
			var bone_transform: Transform = model.skeleton.get_bone_pose(bone_index)
			var bone_name: String = model.skeleton.get_bone_name(bone_index)

			current_model_config.bone_transforms[bone_name] = bone_transform

		config = current_model_config.duplicate()

	var config_name = config.config_name
	var model_name = config.model_name
	var is_default = config.is_default_for_model
	var is_default_dirty = config.is_default_dirty

	var config_path := CONFIG_FORMAT % [metadata_path, config_name]

	metadata_config.config_data[config_name] = config_path

	if metadata_config.model_defaults.has(model_name):
		if is_default_dirty:
			config.is_default_dirty = false
			if is_default:
				metadata_config.model_defaults[model_name] = config_name
				_normalize_default_configs(config_name, model_name)
	else:
		config.is_default_for_model = true
		metadata_config.model_defaults[model_name] = config_name

	for prop_key in AppManager.main.gui.props.keys(): # PropData
		var prop_data = AppManager.main.gui.props[prop_key]
		config.instanced_props[prop_data.prop_name] = prop_data.get_as_dict()
	
	var config_file := File.new()
	config_file.open(config_path, File.WRITE)
	config_file.store_string(to_json(config.get_as_dict()))
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
