class_name ConfigManager
extends AbstractManager

const METADATA_FILE_NAME := "metadata.json"
const CONFIG_FILE_EXTENSION := "json"

const METADATA_CALLBACK := "_on_metadata_changed"
const MODEL_CONFIG_CALLBACK := "_on_model_config_changed"

var save_data_path := ""

var metadata := Metadata.new()
var model_config := ModelConfig.new()

#-----------------------------------------------------------------------------#
# Builtin functions                                                           #
#-----------------------------------------------------------------------------#

func _init() -> void:
	pass

func _setup_logger() -> void:
	logger = Logger.new("ConfigManager")

func _setup_class() -> void:
	if not OS.is_debug_build():
		save_data_path = "user://"
	else:
		save_data_path = "res://export"
	
	if AM.env.current_env != Env.Envs.TEST:
		var result := Safely.wrap(load_metadata())
		if result.is_err():
			logger.error(result)
			
			logger.info("Using defaults")
			metadata = Metadata.new()
		
	var result := Safely.wrap(_register_all_configs_with_pub_sub())
	if result.is_err():
		logger.error(result)

#-----------------------------------------------------------------------------#
# Connections                                                                 #
#-----------------------------------------------------------------------------#

func _on_metadata_changed(data, key: String) -> void:
	metadata.set_data(key, data.data if data is SignalPayload else data)
	AM.save_config()

func _on_model_config_changed(data, key: String) -> void:
	model_config.set_data(key, data.data if data is SignalPayload else data)
	AM.save_config()

#-----------------------------------------------------------------------------#
# Private functions                                                           #
#-----------------------------------------------------------------------------#

## Save a string to a given path
##
## @return: Result<String> - The path the String was saved at
func _save_to_file(path: String, data: String) -> Result:
	return FileUtil.save_file_at_path("%s/%s" % [save_data_path, path], data)

## All config keys are registered with the PubSub. A new signal is created for each key and then
## the ConfigManager subscribes itself to any changes.
##
## @return: Result - An error from registration or OK
func _register_all_configs_with_pub_sub() -> Result:
	var result := _register_config_data_with_pub_sub(metadata.get_as_dict(), METADATA_CALLBACK)
	if result.is_err():
		return result

	result = _register_config_data_with_pub_sub(model_config.get_as_dict(), MODEL_CONFIG_CALLBACK)
	if result.is_err():
		return result
	
	return Safely.ok()

func _register_config_data_with_pub_sub(data: Dictionary, callback: String) -> Result:
	for key in data.keys():
		if key != "other":
			var result: Result = AM.ps.create_signal(key)
			if result.is_err():
				if result.unwrap_err().code == Error.Code.PUB_SUB_USER_SIGNAL_ALREADY_EXISTS:
					continue
				return result

			result = AM.ps.subscribe(self, key, {
				"args": [key],
				"callback": callback
			})
		else:
			# This doesn't infinite recurse because we are passing the dictionary
			# for "other", not the "other" key
			var result: Result = _register_config_data_with_pub_sub(data[key], callback)
			if result.is_err():
				return result

	return Safely.ok()

#-----------------------------------------------------------------------------#
# Public functions                                                            #
#-----------------------------------------------------------------------------#

## Add signals at runtime and subscribe to them. Meant for extension to hook the
## ConfigManager up to new config values
##
## @param: signal_name: String - The name of the config value to listen for
## @param: is_metadata: bool - Whether the metadata should be used
##
## @return: Result<Error> - The error code
func runtime_subscribe_to_signal(signal_name: String, is_metadata: bool = false) -> Result:
	var res: Result = Safely.wrap(AM.ps.create_signal(signal_name))
	if res.is_err():
		if res.unwrap_err().code != Error.Code.PUB_SUB_USER_SIGNAL_ALREADY_EXISTS:
			return res

	res = AM.ps.subscribe(self, signal_name, {
		"args": [signal_name],
		"callback": METADATA_CALLBACK if is_metadata else MODEL_CONFIG_CALLBACK
	})

	return res

#region Save/load

func load_metadata() -> Result:
	logger.info("Loading metadata")

	var file := File.new()
	if file.open("%s/%s" % [save_data_path, METADATA_FILE_NAME], File.READ) != OK:
		return Safely.err(Error.Code.CONFIG_MANAGER_METADATA_LOAD_ERROR)

	var result := metadata.parse_string(file.get_as_text())
	if result.is_err():
		return result

	logger.info("Finished loading metadata")
	
	return Safely.ok()

## Creates a new model config if possible. Does not immediately set the config but does store
## the config in metadata
##
## @param: model_name: String - The name of the model
## @param: model_path: String - The absolute path to the model
## @param: config_name: String - The name of the config file
##
## @return: Result<ModelConfig> - The resulting config file
func create_new_model_config(model_name: String, model_path: String, config_name: String = "") -> Result:
	if config_name.empty():
		config_name = model_name
	
	if metadata.model_configs.has(config_name):
		return Safely.err(Error.Code.METADATA_CONFIG_ALREADY_EXISTS, config_name)
	
	var mc := ModelConfig.new()
	mc.config_name = config_name
	mc.model_name = model_name
	mc.model_path = model_path
	
	var res := _save_to_file("%s.json" % config_name, mc.get_as_json_string())
	if res.is_err():
		return res
	
	metadata.model_configs[config_name] = res.unwrap()
	
	return Safely.ok(mc)

func load_model_config(path: String) -> Result:
	var result := Safely.wrap(load_model_config_no_set(path))
	if result.is_err():
		return result

	model_config = result.unwrap()

	logger.info("Successfully set ModelConfig %s" % path)

	return result

# TODO make this the default behavior
func load_model_config_no_set(path: String) -> Result:
	logger.info("Loading model config: %s" % path)

	var file := File.new()
	if file.open("%s/%s" % [save_data_path, path] if not path.is_abs_path() else path, File.READ) != OK:
		return Safely.err(Error.Code.CONFIG_MANAGER_MODEL_CONFIG_LOAD_ERROR)

	var mc := ModelConfig.new()

	var result := Safely.wrap(mc.parse_string(file.get_as_text()))
	if result.is_err():
		return result

	logger.info("Finished loading model config")

	return Safely.ok(mc)

func save_data(data_name: String = "", data: String = "") -> Result:
	logger.info("Saving data")
	
	var result := Safely.wrap(_save_to_file(METADATA_FILE_NAME, metadata.get_as_json_string()))
	if result.is_err():
		return result

	if model_config.config_name.empty():
		result = Safely.wrap(_save_to_file(
			"%s.json" % (data_name if not data_name.empty() else model_config.config_name),
			data if not data.empty() else model_config.get_as_json_string()
		))
		if result.is_err():
			return result
	
	logger.info("Finished saving data")

	return result

#endregion

#region Data access

## Checks if the metadata or model config contains some key
##
## @param: key: String - The key to check
func has_data(key: String) -> bool:
	return metadata.has_data(key) or model_config.has_data(key)

# TODO this logic is wrong since set
## Wrapper for setting KNOWN data in ModelConfig or Metadata, in that search order.
##
## Has no effect if the key does not exist. If arbitrary data should be set, the individual config file
## should be accessed and have set_data(...) called on them directly
##
## @param: key: String
## @param: value: Variant
func set_data(key: String, value) -> void:
	if model_config.get_data(key) != null:
		model_config.set_data(key, value)
	elif metadata.get_data(key) != null:
		metadata.set_data(key, value)
	else:
		logger.info("Data %s not found in any config file. Storing in metadata." % key)
		metadata.set_data(key, value)

## Wrapper for getting data in ModelConfig or Metadata, in that search order
##
## @param: key: String - The key to find
##
## @return: Variant - The data found at the given key
func get_data(key: String, default_value = null, use_metadata: bool = false):
	var val = model_config.get_data(key)
	if val != null:
		return val
	
	val = metadata.get_data(key)
	if val != null:
		return val

	logger.debug("Key %s not found in ModelConfig and Metadata, creating and using default value" % key)

	if use_metadata:
		metadata.set_data(key, default_value)
	else:
		model_config.set_data(key, default_value)

	return default_value

## Wrapper for getting KNOWN data in ModelConfig or Metadata, in that search order.
##
## Uses the find_data_get(...) method which is very slow
func find_data_get(query: String) -> Result:
	var result := Safely.wrap(model_config.find_data_get(query))
	if result.is_ok():
		return result

	result = Safely.wrap(metadata.find_data_get(query))
	if result.is_ok():
		return result

	logger.error("Invalid search query %s" % query)

	return Safely.err(Error.Code.CONFIG_MANAGER_DATA_NOT_FOUND)

## Wrapper for setting KNOWN data in ModelConfig or Metadata, in that search order.
##
## Uses the find_data_set(...) method which is very slow
func find_data_set(query: String, new_value) -> Result:
	var result := Safely.wrap(model_config.find_data_set(query, new_value))
	if result.is_ok():
		return result

	result = Safely.wrap(metadata.find_data_set(query, new_value))
	if result.is_ok():
		return result

	logger.error("Invalid search query %s" % query)

	return Safely.err(Error.Code.CONFIG_MANAGER_DATA_NOT_FOUND)

#endregion
