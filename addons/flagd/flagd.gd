extends Reference

const RAW_ARGS_KEY := "__raw__"

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
	
	var description := ""
	
	func _init(args: Dictionary = {}) -> void:
		description = args.get("description", "")
	
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
	
	func parse(input: Array = []) -> Dictionary:
		return _parse(OS.get_cmdline_args() if input.empty() else input)
	
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
