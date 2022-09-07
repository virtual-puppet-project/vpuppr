extends Reference

## Flag parsing
## See https://docs.godotengine.org/en/stable/tutorials/editor/command_line_tutorial.html
## for a list of reserved flags

var _parser

var data := {}

#-----------------------------------------------------------------------------#
# Builtin functions                                                           #
#-----------------------------------------------------------------------------#

func _init() -> void:
	var flagd := preload("res://addons/flagd/flagd.gd").new()
	
	_parser = flagd.new_parser({
		"description": "vpuppr flag parser",

		"should_parse_feature_flags": Globals.SHOULD_PARSE_FEATURE_FLAGS,

		"should_parse_cmdline_args": Globals.SHOULD_PARSE_CMDLINE_ARGS,

		"should_parse_user_data_args": Globals.SHOULD_PARSE_USER_DATA_ARGS,
		"user_data_args_file_name": "flagd"
	})

	#region General
	
	# Cannot call this 'verbose' since that's reserved by Godot
	_parser.add_argument({
		"name": "all-logs",
		"aliases": ["loud"],
		"description": "Show debug/trace logs. Only has an effect in release builds",
		"is_flag": true,
		"type": TYPE_BOOL,
		"default": false
	})
	_parser.add_argument({
		"name": "environment",
		"aliases": ["env"],
		"description": "The environment the application will assume it is running in (e.g. dev)",
		"type": TYPE_STRING,
		"default": Env.Envs.DEFAULT
	})

	_parser.add_argument({
		"name": "screen-scaling",
		"description": "Ratio to scale the application to",
		"type": TYPE_REAL,
		"default": 0.75
	})
	
	#endregion
	
	#region Splash
	
	_parser.add_argument({
		"name": "stay-on-splash",
		"description": "Whether to automatically move on from the splash screen",
		"is_flag": true,
		"type": TYPE_BOOL,
		"default": false
	})
	
	#endregion
	
	#region Extensions
	
	_parser.add_argument({
		"name": "resource_path",
		"description": "The location to scan for runtime resources",
		"type": TYPE_STRING
	})
	
	#endregion

	data = _parser.parse()

#-----------------------------------------------------------------------------#
# Connections                                                                 #
#-----------------------------------------------------------------------------#

#-----------------------------------------------------------------------------#
# Private functions                                                           #
#-----------------------------------------------------------------------------#

#-----------------------------------------------------------------------------#
# Public functions                                                            #
#-----------------------------------------------------------------------------#
