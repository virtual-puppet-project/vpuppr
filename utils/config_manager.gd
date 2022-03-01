class_name ConfigManager
extends Reference

const METADATA_FILE_NAME := "metadata.json"

var logger := Logger.new("ConfigManager")

var save_data_path := ""

var metadata := Metadata.new()
var model_config := ModelConfig.new()

###############################################################################
# Builtin functions                                                           #
###############################################################################

func _init() -> void:
	if not OS.is_debug_build():
		save_data_path = "user://"
	else:
		save_data_path = "res://export"

	if AM.env.current_env != Env.Envs.TEST:
		var result := load_data()
		if result.is_err():
			logger.error(result.unwrap_err().to_string())
			
			logger.info("Using defaults")
			metadata = Metadata.new()
			model_config = ModelConfig.new()
		
		result = _register_all_configs_with_pub_sub()
		if result.is_err():
			logger.error(result.unwrap_err().to_string())

###############################################################################
# Connections                                                                 #
###############################################################################

func _on_metadata_changed(data, key: String) -> void:
	metadata.set_data(key, data)

func _on_model_config_data_changed(data, key: String) -> void:
	model_config.set_data(key, data)

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
				return result

			result = AM.ps.register(self, key, PubSubPayload.new({
				"args": [key],
				"callback": callback
			}))
		else:
			var result: Result = _register_config_data_with_pub_sub(data[key], callback)
			if result.is_err():
				return result

	return Result.ok()

###############################################################################
# Public functions                                                            #
###############################################################################

func load_data() -> Result:
	# TODO stub
	return Result.ok()

func save_data() -> Result:
	var result := _save_to_file(METADATA_FILE_NAME, metadata.get_as_json_string())
	if result.is_err():
		return result

	result = _save_to_file("%s.json" % model_config.config_name, model_config.get_as_json_string())
	if result.is_err():
		return result

	return Result.ok()

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
	var val = model_config.get_data(key)
	if val != null:
		return val
	
	val = metadata.get_data(key)
	if val != null:
		return val

	logger.error("Key %s not found in ModelConfig and Metadata" % key)

	return null

func find_data(query: String):
	var val = model_config.find_data(query)
	if val != null:
		return val

	val = metadata.find_data(query)
	if val != null:
		return val

	logger.error("Invalid search query %s" % query)

	return null
