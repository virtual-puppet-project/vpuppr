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
	
	if AM.ps.connect("metadata_changed", self, "_on_metadata_changed") != OK:
		logger.error("Unable to subscribe to metadata_changed")

	if AM.ps.connect("model_config_data_changed", self, "_on_model_config_data_changed") != OK:
		logger.error("Unable to subscribe to model_config_data_changed")

###############################################################################
# Connections                                                                 #
###############################################################################

func _on_metadata_changed(key: String, data) -> void:
	metadata.set_data(key, data)

func _on_model_config_data_changed(key: String, data) -> void:
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

###############################################################################
# Public functions                                                            #
###############################################################################

func save() -> Result:
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
