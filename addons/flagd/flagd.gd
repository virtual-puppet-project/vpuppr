extends Reference

const RAW_ARGS_KEY := "__raw__"

const FEATURE_FLAGS_FUNC_SIGNATURE_PREFIX := "_flagd_features_"

enum Action {
	NONE = 0,
	
	STORE,
	STORE_TRUE,
	STORE_FALSE,
	APPEND,
	COUNT
}

class Parser:
	var _arguments := {}
	var _feature_func_refs := []
	
	var description := ""

	# Cmdline args can override feature flags
	var should_parse_feature_flags := true
	# Cmdline args always take precendence over user data args
	var should_parse_cmdline_args := true
	var should_parse_user_data_args := false
	var user_data_args_file_name := "flagd"
	
	func _init(args: Dictionary = {}) -> void:
		description = args.get("description", description)

		should_parse_cmdline_args = args.get("should_parse_cmdline_args",
			should_parse_cmdline_args)
		should_parse_user_data_args = args.get("should_parse_user_data_args",
			should_parse_user_data_args)
		user_data_args_file_name = args.get("user_data_args_file_name",
			user_data_args_file_name)
	
	func _to_string() -> String:
		var r := {
			"description": description
		}
		
		for key in _arguments.keys():
			r[key] = _arguments[key].to_dict()
		
		return JSON.print(r, "\t")
	
	func add_argument(args: Dictionary = {}) -> void:
		if not args.has("name"):
			printerr("A name for the argument must be provided")
			return
		
		var arg := Argument.new(args)
		
		_arguments[arg.name] = arg
		
		for alias in arg.aliases:
			_arguments[alias] = arg

	func register_feature_funcs(from: Object) -> void:
		for f in from.get_method_list():
			if not f.name.begins_with(FEATURE_FLAGS_FUNC_SIGNATURE_PREFIX):
				continue
			if f.args.size() > 0:
				printerr("Malformed feature func: %s" % f.name)
				continue
			
			_feature_func_refs.append(funcref(from, f.name))
	
	## Parse all args. If input is provided, those will be the only args parsed
	##
	## @param: input: Array<String> - Optional args to parse
	##
	## @return: Dictionary<String, Variant> - A list of all args
	func parse(input: Array = []) -> Dictionary:
		var args = input.duplicate()
		
		if args.empty():
			if should_parse_cmdline_args:
				args.append_array(OS.get_cmdline_args())

			if should_parse_user_data_args:
				_get_user_data_args(user_data_args_file_name, args)
		
		for f_ref in _feature_func_refs:
			if not OS.has_feature(f_ref.function.trim_prefix(FEATURE_FLAGS_FUNC_SIGNATURE_PREFIX)):
				continue

			var result = f_ref.call_func()
			if not typeof(result) == TYPE_ARRAY:
				printerr("Invalid return type from %s in flagd" % f_ref.function)
				continue
				
			args.append_array(result.duplicate(true))

		return _parse(args)
	
	func _parse(input: Array) -> Dictionary:
		var r := {RAW_ARGS_KEY: input}
		
		# Array<String> of argument names
		var unhandled_args := _arguments.duplicate(true)
		
		var idx: int = 0
		while idx < input.size():
			var current_arg: String = input[idx]
			
			var split: PoolStringArray = current_arg.split("=", false, 1)
			if split.size() > 1:
				var key: String = split[0].lstrip("-").replace("-", "_")
				
				var arg_config: Argument = _arguments.get(key, null)
				if arg_config == null:
					idx += 1
					continue
				
				var val = split[1]
				
				match arg_config.type:
					TYPE_STRING:
						r[arg_config.name] = val
					TYPE_INT:
						r[arg_config.name] = int(val)
					TYPE_REAL:
						r[arg_config.name] = float(val)
					TYPE_BOOL:
						r[arg_config.name] = bool(val)
					_:
						r[arg_config.name] = val
				
				unhandled_args.erase(arg_config.name)
				for alias in arg_config.aliases:
					unhandled_args.erase(alias)
			else:
				current_arg = current_arg.lstrip("-").replace("-", "_")
				
				var arg_config: Argument = _arguments.get(current_arg, null)
				if arg_config == null:
					idx += 1
					continue
				
				if arg_config.is_flag:
					r[arg_config.name] = true
					
					unhandled_args.erase(arg_config.name)
					for alias in arg_config.aliases:
						unhandled_args.erase(alias)
					
					idx += 1
					continue
				
				# Arg expects a value
				idx += 1
				
				if idx >= input.size():
					return r
				
				match arg_config.type:
					TYPE_STRING:
						r[arg_config.name] = input[idx]
					TYPE_INT:
						r[arg_config.name] = int(input[idx])
					TYPE_REAL:
						r[arg_config.name] = float(input[idx])
					TYPE_BOOL:
						r[arg_config.name] = bool(input[idx])
					_:
						r[arg_config.name] = input[idx]
				
				unhandled_args.erase(arg_config.name)
				for alias in arg_config.aliases:
					unhandled_args.erase(alias)
				
				idx += 1
		
		for config in unhandled_args.values():
			r[config.name] = config.default
		
		return r
	
	static func _get_user_data_args(file_name: String, args: Array) -> void:
		var file := File.new()

		if file.open("user://%s" % file_name, File.READ) != OK:
			printerr("Arg file %s could not be opened, ignoring" % file_name)
			return

		var file_lines := file.get_as_text().split("\n")
		for line in file_lines:
			var split: PoolStringArray = line.split(" ", false)
			
			var idx: int = 0
			while idx < split.size():
				var arg: String = split[idx]

				if arg.begins_with("-"):
					# If the arg was already passed as an app arg, then ignore the arg from the file
					if arg in args:
						idx += 1
						# Check next arg to see if it's a value or a flag
						# If it's a value, assume it's associated with the flag and skip it
						if idx < split.size() and not split[idx].begins_with("-"):
							idx += 1
						
						continue
					
				args.append(arg)
				idx += 1

		file.close()

class Argument:
	var name := ""
	var description := ""
	
	var aliases := []
	
	var is_flag := false
	var type := TYPE_STRING
	var default
	
	func _init(args: Dictionary = {}) -> void:
		name = args.get("name", "").lstrip("-").replace("-", "_")
		description = args.get("description", "")
		
		var temp_aliases = args.get("aliases", []).duplicate(true)
		for alias in temp_aliases:
			aliases.append(alias.lstrip("-"))
		
		is_flag = args.get("is_flag", false)
		if not is_flag:
			type = args.get("type", TYPE_STRING)
			if args.has("default"):
				default = args["default"]
			else:
				match type:
					TYPE_STRING:
						default = ""
					TYPE_INT:
						default = 0
					TYPE_REAL:
						default = 0.0
					TYPE_BOOL:
						default = false
					_:
						default = ""
		else:
			type = TYPE_BOOL
			default = args.get("default", false)
	
	func _to_string() -> String:
		return JSON.print(to_dict(), "\t")
	
	func to_dict() -> Dictionary:
		var r := {}
		
		for prop in get_property_list():
			if prop.name in ["Reference", "script", "Script Variables"]:
				continue
			
			r[prop.name] = get(prop.name)
		
		return r

#-----------------------------------------------------------------------------#
# Builtin functions                                                           #
#-----------------------------------------------------------------------------#

#-----------------------------------------------------------------------------#
# Connections                                                                 #
#-----------------------------------------------------------------------------#

#-----------------------------------------------------------------------------#
# Private functions                                                           #
#-----------------------------------------------------------------------------#

#-----------------------------------------------------------------------------#
# Public functions                                                            #
#-----------------------------------------------------------------------------#

func new_parser(args: Dictionary = {}) -> Parser:
	var parser := Parser.new(args)
	
	return parser
