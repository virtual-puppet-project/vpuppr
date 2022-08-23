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

		"should_parse_feature_flags": true,
		"preparse_func": funcref(self, "_apply_preparse_args"),

		"should_parse_cmdline_args": true,

		"should_parse_user_data_args": true,
		"user_data_args_file_name": "flagd"
	})

	_parser.register_feature_funcs(self)

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

func _apply_preparse_args(key: String, val) -> void:
	if _parser.get(key) != null:
		_parser.set(key, val)
		return

	var ae := preload("res://addons/advanced-expression/advanced_expression.gd").new()

	ae.add("%s = %s" % [key, str(val)])

	var err: int = ae.compile()
	if err != OK:
		printerr("Unable to compile preparse func: %d" % err)
		return

	ae.execute()

func _flagd_features_editor() -> Array:
	return [
		"should_parse_user_data_args=false",
		"AM.app_args['stay_on_splash']=true"
	]

func _flagd_features_flatpak() -> Array:
	return [
		"resource_path=/app/share/vpuppr/resources/"
	]

func _flagd_features_gentoo() -> Array:
	return [
		"resource_path=/usr/share/vpuppr/resources/"
	]

#-----------------------------------------------------------------------------#
# Public functions                                                            #
#-----------------------------------------------------------------------------#
