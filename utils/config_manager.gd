class_name ConfigManager
extends AbstractManager

const METADATA_FILE_NAME := "metadata.json"

var save_data_path := ""

var metadata := Metadata.new()
var model_config := ModelConfig.new()

###############################################################################
# Builtin functions                                                           #
###############################################################################

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
		var result := load_metadata()
		if result.is_err():
			logger.error(result.unwrap_err().to_string())
			
			logger.info("Using defaults")
			metadata = Metadata.new()
		
	var result := _register_all_configs_with_pub_sub()
	if result.is_err():
		logger.error(result.unwrap_err().to_string())

###############################################################################
# Connections                                                                 #
###############################################################################

func _on_metadata_changed(data, key: String) -> void:
	metadata.set_data(key, data)
	AM.save_config()

func _on_model_config_data_changed(data, key: String) -> void:
	model_config.set_data(key, data)
	AM.save_config()

###############################################################################
# Private functions                                                           #
###############################################################################

func _save_to_file(path: String, data: String) -> Result:
	var file := File.new()
	if file.open("%s/%s" % [save_data_path, path], File.WRITE) != OK:
		return Result.err(Error.Code.FILE_WRITE_FAILURE)

	file.store_string(data)

	return Result.ok()

func _register_all_configs_with_pub_sub() -> Result:
	"""
	All config keys are registered with the PubSub. A new signal is created for each key and then
	the ConfigManager subscribes itself to any changes.
	
	Returns:
		Result - An error from registration or OK
	"""
	var result := _register_config_data_with_pub_sub(metadata.get_as_dict(), "_on_metadata_changed")
	if result.is_err():
		return result

	result = _register_config_data_with_pub_sub(model_config.get_as_dict(), "_on_model_config_data_changed")
	if result.is_err():
		return result
	
	return Result.ok()

func _register_config_data_with_pub_sub(data: Dictionary, callback: String) -> Result:
	for key in data.keys():
		if key != "other":
			var result: Result = AM.ps.create_signal(key)
			if result.is_err():
				if result.unwrap_err().error_code() == Error.Code.PUB_SUB_USER_SIGNAL_ALREADY_EXISTS:
					continue
				return result

			result = AM.ps.register(self, key, PubSubPayload.new({
				"args": [key],
				"callback": callback
			}))
		else:
			# This doesn't infinite recurse because we are passing the dictionary
			# for "other", not the "other" key
			var result: Result = _register_config_data_with_pub_sub(data[key], callback)
			if result.is_err():
				return result

	return Result.ok()

###############################################################################
# Public functions                                                            #
###############################################################################

#region Save/load

func load_metadata() -> Result:
	logger.info("Loading metadata")

	var file := File.new()
	if file.open("%s/%s" % [save_data_path, METADATA_FILE_NAME], File.READ) != OK:
		return Result.err(Error.Code.CONFIG_MANAGER_METADATA_LOAD_ERROR)

	var result := metadata.parse_string(file.get_as_text())
	if result.is_err():
		return result

	logger.info("Finished loading metadata")
	
	return Result.ok()

func load_model_config(path: String) -> Result:
	var result := load_model_config_no_set(path)
	if result.is_err():
		return result

	model_config = result.unwrap()

	logger.info("Successfully set ModelConfig %s" % path)

	return Result.ok()

func load_model_config_no_set(path: String) -> Result:
	logger.info("Loading model config: %s" % path)

	var file := File.new()
	if file.open("%s/%s" % [save_data_path, path] if not path.is_abs_path() else path, File.READ) != OK:
		return Result.err(Error.Code.CONFIG_MANAGER_MODEL_CONFIG_LOAD_ERROR)

	var mc := ModelConfig.new()

	var result := mc.parse_string(file.get_as_text())
	if result.is_err():
		return result

	logger.info("Finished loading model config")

	return Result.ok(mc)

func save_data() -> Result:
	logger.info("Saving data")
	
	var result := _save_to_file(METADATA_FILE_NAME, metadata.get_as_json_string())
	if result.is_err():
		return result

	if model_config.config_name != ModelConfig.DEFAULT_NAME:
		result = _save_to_file("%s.json" % model_config.config_name, model_config.get_as_json_string())
		if result.is_err():
			return result
	
	logger.info("Finished saving data")

	return Result.ok()

#endregion

#region Data access

func set_data(key: String, value) -> void:
	"""
	Wrapper for setting KNOWN data in ModelConfig or Metadata, in that search order.

	Has no effect if the key does not exist. If arbitrary data should be set, the individual config file
	should be accessed and have set_data(...) called on them directly
	"""
	if model_config.get_data(key) != null:
		model_config.set_data(key, value)
	elif metadata.get_data(key) != null:
		metadata.set_data(key, value)
	else:
		logger.error("Key %s not found in ModelConfig or Metadata. Declining to set data %s." % [key, str(value)])

func get_data(key: String):
	"""
	Wrapper for getting data in ModelConfig or Metadata, in that search order
	"""
	var val = model_config.get_data(key)
	if val != null:
		return val
	
	val = metadata.get_data(key)
	if val != null:
		return val

	logger.error("Key %s not found in ModelConfig and Metadata" % key)

	return null

func find_data_get(query: String) -> Result:
	"""
	Wrapper for getting KNOWN data in ModelConfig or Metadata, in that search order.

	Uses the find_data_get(...) method which is very slow
	"""
	var result := model_config.find_data_get(query)
	if result.is_ok():
		return result

	result = metadata.find_data_get(query)
	if result.is_ok():
		return result

	logger.error("Invalid search query %s" % query)

	return Result.err(Error.Code.CONFIG_MANAGER_DATA_NOT_FOUND)

func find_data_set(query: String, new_value) -> Result:
	"""
	Wrapper for setting KNOWN data in ModelConfig or Metadata, in that search order.

	Uses the find_data_set(...) method which is very slow
	"""
	var result := model_config.find_data_set(query, new_value)
	if result.is_ok():
		return result

	result = metadata.find_data_set(query, new_value)
	if result.is_ok():
		return result

	logger.error("Invalid search query %s" % query)

	return Result.err(Error.Code.CONFIG_MANAGER_DATA_NOT_FOUND)

#endregion
