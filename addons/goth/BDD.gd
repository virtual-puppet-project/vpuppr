class_name BDD
extends Reference

class Tuple2:
	var v0
	var v1

	func _init(p0, p1) -> void:
		v0 = p0
		v1 = p1
	
	func _to_string() -> String:
		return "%s: %s" % [v0, v1]

class Result:
	var _tuple: Tuple2

	func _init(v0, v1) -> void:
		_tuple = Tuple2.new(v0, v1)

	func unwrap():
		# Error
		if _tuple.v1:
			printerr("Unwrapped an error")
			return null
		else:
			return _tuple.v0

	func unwrap_err() -> String:
		return _tuple.v1

	func is_ok() -> bool:
		return _tuple.v1 == null

	func is_err() -> bool:
		return _tuple.v1 != null

	func set_value(value) -> void:
		_tuple.v0 = value

	func set_error(value) -> void:
		_tuple.v1 = value

class Tokenizer:
	enum { None = 0, ParseSpace, ParseSymbol, ParseQuotation, ParseBracket, ParseIgnore }

	const EXP_END: String = "__exp_end__"

	var _current_type: int = None
	var _is_escape_character: bool = false

	var _token_builder: PoolStringArray = PoolStringArray()

	func _build_token(result: Array) -> void:
		if _token_builder.size() != 0:
			result.append(_token_builder.join(""))
			_token_builder = PoolStringArray()
	
	func tokenize(value: String) -> Result:
		var result: Array = []
		var error

		var paren_counter: int = 0
		var square_bracket_counter: int = 0
		var curly_bracket_counter: int = 0
		
		# Checks for raw strings of size 1
		if value.length() <= 2:
			return Result.new(result, "Program too short")

		for i in value.length():
			var c: String = value[i]
			if _current_type == ParseIgnore:
				match c:
					"\r\n", "\n", ";":
						_current_type = None
					_:
						continue
			elif c == '"':
				if _is_escape_character: # This is a double quote literal
					_token_builder.append(c)
					_is_escape_character = false
				elif _current_type == ParseQuotation: # Close the double quote
					_token_builder.append(c)
					_current_type = None
					_build_token(result)
				else: # Open the double quote
					_token_builder.append(c)
					_current_type = ParseQuotation
			elif _current_type == ParseQuotation:
				if c == "\\":
					_is_escape_character = true
				else:
					_token_builder.append(c)
			else:
				match c:
					"(":
						paren_counter += 1
						_build_token(result)
						_current_type = ParseBracket
						result.append(c)
					")":
						paren_counter -= 1
						_build_token(result)
						_current_type = None
						result.append(c)
					"[":
						square_bracket_counter += 1
						_build_token(result)
						_current_type = ParseBracket
						result.append(c)
					"]":
						square_bracket_counter -= 1
						_build_token(result)
						_current_type = None
						result.append(c)
					"{":
						curly_bracket_counter += 1
						_build_token(result)
						_current_type = ParseBracket
						result.append(c)
					"}":
						curly_bracket_counter -= 1
						_build_token(result)
						_current_type = None
						result.append(c)
					" ", "\t":
						_build_token(result)
						_current_type = ParseSpace
					"\r\n", "\n":
						_build_token(result)
						result.append(EXP_END)
						_build_token(result)
					";":
						_current_type = ParseIgnore
					_:
						_current_type = ParseSymbol
						_token_builder.append(c)

		if paren_counter != 0:
			result.clear()
			error = "Mismatched parens"

		if square_bracket_counter != 0:
			result.clear()
			error = "Mismatched square brackets"

		if curly_bracket_counter != 0:
			result.clear()
			error = "Mismatched curly brackets"

		return Result.new(result, error)

class Parser:
	enum { None = 0, Scenario, Given, When, Then }
	var _current_type: int = None

	var _method_builder: PoolStringArray = PoolStringArray()
	var _param_builder: PoolStringArray = PoolStringArray()

	var _expression: Expression = Expression.new()

	var _current_scenario

	var _method_param_mapping: Dictionary = {} # String: Dictionary of String: Array [String]
	var _params: Array = [] # String

	func _build_method() -> bool:
		if _method_builder.size() != 0:
			var method_name: String = _method_builder.join("_")
			match _current_type:
				Scenario:
					_current_scenario = method_name
					# _method_param_mapping[_current_scenario] = {
					# 	"given": {},
					# 	"when": {},
					# 	"then": {}
					# }
					_method_param_mapping[_current_scenario] = ScenarioData.new()
				_:
					if _param_builder.size() != 0:
						_build_param()
					
					var scenario_method: ScenarioMethod = ScenarioMethod.new(method_name, _params.duplicate())
					
					match _current_type:
						Given:
							# _method_param_mapping[_current_scenario]["given"][method_name] = _params.duplicate()
							_method_param_mapping[_current_scenario].given.append(scenario_method)
						When:
							# _method_param_mapping[_current_scenario]["when"][method_name] = _params.duplicate()
							_method_param_mapping[_current_scenario].when.append(scenario_method)
						Then:
							# _method_param_mapping[_current_scenario]["then"][method_name] = _params.duplicate()
							_method_param_mapping[_current_scenario].then.append(scenario_method)
						_:
							printerr("Invalid scenario type")
							return false
					
					# Clear params for next method
					_params.clear()

			# Reset builder
			_method_builder = PoolStringArray()

			return true
		
		printerr("Method builder length is 0")
		return false

	func _build_param() -> bool:
		if _param_builder.size() != 0:
			var joined_param: String = _param_builder.join(" ")
			if _expression.parse(joined_param) == OK:
				_params.append(_expression.execute())
			else:
				# Failed to parse
				printerr("Failed to parse")
				return false
			if _expression.has_execute_failed():
				# Failed to execute
				printerr("Failed to execute")
				return false
			_param_builder = PoolStringArray()
			return true
		# Tried to build an empty param
		printerr("Param builder length is 0")
		return false

	func parse(tokens: Array) -> Result:
		var error

		var param_counter: int = 0
		var is_param: bool = false
		
		if tokens.size() == 0:
			return Result.new(null, "Unexpected EOF")

		tokens.invert()
		var token: String = tokens.pop_back()

		while true:
			match token.to_lower():
				"scenario", "scenario:":
					if (_current_type != None and _current_type != Then):
						return Result.new(null, "Scenario clause must be the first clause")
					_current_type = Scenario
				"given":
					if _current_type != Scenario:
						return Result.new(null, "Given clause must come directly after Scenario")
					_current_type = Given
				"when":
					if _current_type != Given:
						return Result.new(null, "When clause must come directly after Given")
					_current_type = When
				"then":
					if _current_type != When:
						return Result.new(null, "Then clause must come directly after When")
					_current_type = Then
				"(":
					is_param = true
					if param_counter > 0:
						_param_builder.append(token)
					param_counter += 1
				")":
					param_counter -= 1
					if param_counter == 0:
						is_param = false
						if not _build_param():
							error = "Failed to parse param %s" % _param_builder.join(" ")
							break
					else:
						_param_builder.append(token)
				Tokenizer.EXP_END, "and":
					# Ignore line break between tests
					if (_current_type != None and _current_type != Then):
						if not _build_method():
							error = "Failed to parse method %s" % _method_builder.join("_")
							break
				_:
					if not is_param:
						_method_builder.append(token)
					else:
						_param_builder.append(token)
			
			if tokens.empty():
				break
			token = tokens.pop_back()

		# Clean up methods if there is no newline at the end of the file
		if not _method_builder.empty():
			if not _build_method():
				error = "Failed to parse method %s" % _method_builder.join("_")

		if not _param_builder.empty():
			if not _build_param():
				error = "Failed to parse param %s" % _param_builder.join(" ")

		if param_counter != 0:
			error = "Mismatched params"

		return Result.new(_method_param_mapping, error)

class ScenarioData:
	var given: Array = [] # ScenarioMethod
	var when: Array = [] # ScenarioMethod
	var then: Array = [] # ScenarioMethod

class ScenarioMethod:
	var name: String
	var params: Array = []

	func _init(p_name: String, p_params: Array) -> void:
		name = p_name
		params = p_params

var step_definitions: Dictionary
var goth

###############################################################################
# Builtin functions                                                           #
###############################################################################

###############################################################################
# Connections                                                                 #
###############################################################################

###############################################################################
# Private functions                                                           #
###############################################################################

###############################################################################
# Public functions                                                            #
###############################################################################

func run(file_name: String) -> void:
	var tokenizer: Tokenizer = Tokenizer.new()
	var parser: Parser = Parser.new()
	
	var ids: Array = ["given", "when", "then"]
	
	var file: File = File.new()
	
	# Read file and immediately close
	if file.open(file_name, File.READ) == OK:
		var content: String = file.get_as_text()
		file.close()

		# Tokenize
		var t_result: Result = tokenizer.tokenize(content)
		if t_result.is_err():
			goth.log_message("Unable to tokenize %s" % file_name)
			goth.log_message("%s" % t_result.unwrap_err())
			return
		
		var tokens: Array = t_result.unwrap()
		
		# Parse
		var p_result: Result = parser.parse(tokens)
		if p_result.is_err():
			goth.log_message("Unable to parse %s" % file_name)
			goth.log_message("%s" % p_result.unwrap_err())
			return

		var bdd_data: Dictionary = p_result.unwrap()

		# Process and run each scenario
		for scen_name in bdd_data.keys():
			var usable_step_definitions: Dictionary = {} # Dictionary method name: file name
			var needed_step_definitions: Array = [] # String
			
			var scenario_data: ScenarioData = bdd_data[scen_name]

			# Check known methods against methods in BDD file
			for id in ids:
				var id_data: Array = scenario_data.get(id)

				for m_data in id_data:
					var found_method: bool = false
					for f_name in step_definitions.keys():
						for step_def in step_definitions[f_name]:
							if step_def["name"] == m_data.name:
								usable_step_definitions[m_data.name] = f_name
								found_method = true
								break
						if found_method:
							break
					if found_method:
						break
					else:
						needed_step_definitions.append(m_data.name)
			
			# Data is missing, cannot continue processing Scenario
			if not needed_step_definitions.empty():
				goth.log_message("Missing step definitions for %s" % str(needed_step_definitions))
				return
			
			var context: SceneTree = SceneTree.new()
			var file_refs: Dictionary = {} # File name to loaded script
			
			# Load in the actual files so we can call methods
			for m_name in usable_step_definitions.keys():
				var f_name: String = usable_step_definitions[m_name]
				file_refs[f_name] = load(f_name).new()
			
			# Run the scenario
			for id in ids:
				var id_data: Array = scenario_data.get(id) # Array [ScenarioMethod]
				
				for m_data in id_data:
					file_refs[usable_step_definitions[m_data.name]].callv(m_data.name, m_data.params)
	else:
		goth.log_message("Unable to open file %s" % file_name)
