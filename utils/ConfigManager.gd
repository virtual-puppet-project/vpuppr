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
			AppManager.log_message("Invalid metadata loaded, using default metadata values")
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

var current_model_config: ModelData

class ModelData:
	var model_config := ModelConfig.new()
	var face_tracking_config := FaceTrackingConfig.new()
	var feature_config := FeatureConfig.new()

	func to_byte_array() -> PoolByteArray:
		var result := PoolByteArray()

		for i in [model_config, face_tracking_config, feature_config]:
			result.append_array(i.to_byte_array())

		return result

class ModelConfig:
	var mapped_bones: Array = [] # String
	var bone_transforms: Dictionary = {} # String: Transform
	var model_transform := Transform()
	var model_parent_transform := Transform()

	func to_byte_array() -> PoolByteArray:
		var result := PoolByteArray()

		# TODO method stub

		return result

class FaceTrackingConfig:
	var translation_damp: float = 0.3
	var rotation_damp: float = 0.02
	var additional_bone_damp: float = 0.3

	var head_bone: String = "head"
	var apply_translation: bool = false
	var apply_rotation: bool = true

	var interpolate_model: bool = true
	var interpolation_rate: float = 0.1

	func to_byte_array() -> PoolByteArray:
		var result := PoolByteArray()

		# TODO method stub

		return result

class FeatureConfig:
	func to_byte_array() -> PoolByteArray:
		var result := PoolByteArray()

		# TODO method stub

		return result

###############################################################################
# Builtin functions                                                           #
###############################################################################

func _init() -> void:
	if not OS.is_debug_build():
		metadata_path = OS.get_executable_path().get_base_dir()
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
	
	if metadata_config.default_model_to_load.empty():
		metadata_config.default_model_to_load = DEMO_MODEL_PATH

	has_loaded_metadata = true

func load_config(path: String) -> void:
	AppManager.log_message("Begin loading config for %s" % path)

	var model_config := ModelConfig.new()

	var dir := Directory.new()
	if not dir.file_exists(path):
		AppManager.log_message("%s does not exist" % path)
		return

	# TODO fill out

func update_config() -> void:
	pass
