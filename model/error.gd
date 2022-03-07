class_name Error
extends Reference

enum Code {
	NONE = 0,

	NULL_VALUE,
	SIGNAL_DOES_NOT_EXIST,
	CONNECT_FAILED,
	
	#region File

	FILE_NOT_FOUND,
	FILE_PARSE_FAILURE,
	FILE_WRITE_FAILURE,
	FILE_UNEXPECTED_DATA,
	
	#endregion

	#region PubSub

	PUB_SUB_INVALID_SIGNAL_NAME,
	PUB_SUB_USER_SIGNAL_ALREADY_EXISTS,

	PUB_SUB_PLUGIN_ALREADY_EXISTS,
	PUB_SUB_PLUGIN_NOT_FOUND,

	#endregion

	#region ConfigManager

	CONFIG_MANAGER_DATA_NOT_FOUND,
	CONFIG_MANAGER_METADATA_LOAD_ERROR,
	CONFIG_MANAGER_MODEL_CONFIG_LOAD_ERROR,

	#endregion

	#region RuntimeLoadableManager

	RUNTIME_LOADABLE_MANAGER_RESOURCE_PATH_DOES_NOT_EXIST,
	RUNTIME_LOADABLE_MANAGER_CONFIG_DOES_NOT_EXIST,
	RUNTIME_LOADABLE_MANAGER_RESOURCE_CONFIG_PARSE_FAILURE,
	RUNTIME_LOADABLE_MANAGER_MISSING_GENERAL_SECTION,
	RUNTIME_LOADABLE_MANAGER_MISSING_EXTENSION_NAME,
	RUNTIME_LOADABLE_MANAGER_MISSING_EXTENSION_SECTION_KEY,

	#endregion

	#region Extension

	EXTENSION_RESOURCE_ALREADY_EXISTS,
	EXTENSION_UNHANDLED_EXTENSION_TYPE,

	#endregion

	#region BaseConfig

	BASE_CONFIG_PARSE_FAILURE,
	BASE_CONFIG_UNEXPECTED_DATA,
	BASE_CONFIG_DATA_NOT_FOUND,
	BASE_CONFIG_UNHANDLED_FIND_SET_DATA_TYPE,

	#endregion

	#region Metadata
	
	METADATA_NOT_FOUND,
	METADATA_PARSE_FAILURE,
	METADATA_UNEXPECTED_DATA

	#endregion

	#region ModelConfig

	MODEL_CONFIG_NOT_FOUND,
	MODEL_CONFIG_PARSE_FAILURE,
	MODEL_CONFIG_UNEXPECTED_DATA,

	#endregion

	#region Viewer

	VIEWER_FILE_NOT_FOUND,
	VIEWER_UNHANDLED_FILE_FORMAT,

	#endregion

	#region Runner

	RUNNER_NO_LOADERS_FOUND,
	RUNNER_FILE_NOT_FOUND,
	RUNNER_LOAD_FILE_FAILED,
	RUNNER_UNHANDLED_FILE_FORMAT

	#endregion
}

var _error: int
var _description: String

func _init(error: int, description: String = "") -> void:
	_error = error
	_description = description

func _to_string() -> String:
	return "Code: %d\nName: %s\nDescription: %s" % [_error, error_name(), _description]

func error_code() -> int:
	return _error

func error_name() -> int:
	return Code.keys()[_error]

func error_description() -> String:
	return _description
