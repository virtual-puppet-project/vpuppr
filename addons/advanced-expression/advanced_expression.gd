extends Reference

class AbstractCode:
	var _cache := []
	
	func _to_string() -> String:
		return "%s\n%s" % [_get_name(), output()]
	
	func _get_name() -> String:
		return "AbstractCode"
	
	static func _build_string(list: Array) -> String:
		return PoolStringArray(list).join("")
	
	func tab(times: int = 1) -> AbstractCode:
		for i in times:
			_cache.append("\t")
		return self
	
	func newline() -> AbstractCode:
		_cache.append("\n")
		return self
	
	func add(text) -> AbstractCode:
		match typeof(text):
			TYPE_STRING:
				tab()
				_cache.append(text)
				newline()
			TYPE_ARRAY:
				_cache.append_array(text)
			_:
				push_error("Invalid type for add: %s" % str(text))
		
		return self
	
	func clear_cache() -> AbstractCode:
		_cache.clear()
		return self
	
	#endregion
	
	#region Finish
	
	func output() -> String:
		return _build_string(_cache)
	
	func raw_data() -> Array:
		return _cache
	
	#region

class Variable extends AbstractCode:
	func _init(var_name: String, var_value: String = "") -> void:
		_cache.append("var %s = " % var_name)
		if not var_value.empty():
			_cache.append(var_value)
	
	func _get_name() -> String:
		return "Variable"
	
	func add(text) -> AbstractCode:
		_cache.append(str(text))
		
		return self
	
	func output() -> String:
		return "%s\n" % .output()

class AbstractFunction extends AbstractCode:
	var _function_def := ""
	var _params := []
	
	func _get_name() -> String:
		return "AbstractFunction"
	
	func _construct_params() -> String:
		var params := []
		params.append("(")
		
		for i in _params:
			params.append(i)
			params.append(",")
		
		# Remove the last comma
		if params.size() > 1:
			params.pop_back()
		
		params.append(")")
		
		return PoolStringArray(params).join("") if not params.empty() else ""
	
	func add_param(text: String) -> AbstractFunction:
		if _params.has(text):
			push_error("Tried to add duplicate param %s" % text)
		else:
			_params.append(text)
		
		return self
	
	func output() -> String:
		var params = _construct_params()
		var the_rest = _build_string(_cache)
		return "%s%s" % [_function_def % _construct_params(), _build_string(_cache)]

class Function extends AbstractFunction:
	func _init(text: String) -> void:
		_function_def = "func %s%s:" % [text, "%s"]
		# Always add a newline into the cache
		newline()
	
	func _get_name() -> String:
		return "Function"

class Runner extends AbstractFunction:
	func _init() -> void:
		_function_def = "func %s%s:" % [RUN_FUNC, "%s"]
		# Always add a newline into the cache
		newline()
	
	func _get_name() -> String:
		return "Runner"

const RUN_FUNC := "__runner__"

var raw := []
var variables := []
var functions := []
var runner := Runner.new()

var gdscript: GDScript
var instance: Reference

###############################################################################
# Builtin functions                                                           #
###############################################################################

func _to_string() -> String:
	return _build_source(raw, variables, functions, runner)

###############################################################################
# Connections                                                                 #
###############################################################################

###############################################################################
# Private functions                                                           #
###############################################################################

static func _build_source(raw: Array, variables: Array, functions: Array, runner: Runner) -> String:
	var source := ""
	
	for i in variables:
		source += i.output()
	
	for i in functions:
		source += i.output()
	
	for i in raw:
		source += "\n%s\n" % i
	
	source += runner.output()
	
	return source

static func _create_script(raw: Array, variables: Array, functions: Array, runner: Runner) -> GDScript:
	var s := GDScript.new()
	
	s.source_code = _build_source(raw, variables, functions, runner)
	
	return s

func _get_instance() -> Reference:
	if instance == null:
		instance = gdscript.new()
	return instance

###############################################################################
# Public functions                                                            #
###############################################################################

## Adds a new variable with an optional initial value. The initial value must be in a
## GDScript-compatible String form
##
## @param: variable_name: String - The name of the variable
## @param: variable_value: String - The initial value of the variable
##
## @return: Variable - A builder object for variables
func add_variable(variable_name: String, variable_value: String = "") -> Variable:
	var variable := Variable.new(variable_name, variable_value)
	
	variables.append(variable)
	
	return variable

## Adds a new function with the given name. The function body must be added later
## with the builder that is returned
##
## @param: function_name: String - The name of the function
##
## @return: Function - A builder object for functions
func add_function(function_name: String) -> Function:
	var function := Function.new(function_name)
	
	functions.append(function)
	
	return function

## Adds a raw String that will be inserted into the script without any modifications
##
## @param: text: String - The text to be added
func add_raw(text: String) -> void:
	raw.append(text)

## Adds text to be added to the body of the runner function. No text can be provided
## so just the Runner builder can be obtained
##
## @param: text: String - The text to be added to the body of the runner function
##
## @return: Runner - A builder object for the runner function
func add(text: String = "") -> Runner:
	if not text.empty():
		runner.add(text)
	
	return runner

## Adds a parameter to the runner function
##
## @param: text: String - The name of the parameter to be passed to the runner function
##
## @return: Runner - A builder object for the runner function
func add_param(text: String) -> Runner:
	if not text.empty():
		runner.add(text)

	return runner

## Adds text to the body of the runner function. This text will be split by the specified
## delimiter and then added as separate lines
##
## @param: text: String - The delimited body of the runner
## @param: delimiter: String - The delimiter to split on
##
## @return: Runner - A builder object for the runner function
func add_delimited(text: String, delimiter: String = ";") -> Runner:
	var split := text.split(delimiter)
	for i in split:
		runner.add(i)
	
	return runner

## Adds the specified number of tabs to the body of the runner function. Does_not
## add a newline when adding a tab
##
## @param: amount: int - The amount of tabs to add
##
## @return: Runner - A builder object for the runner function
func tab(amount: int = 1) -> Runner:
	runner.tab(amount)
	
	return runner

## Adds a newline to the body of the runner function
##
## @return: Runner - A builder object for the runner function
func newline() -> Runner:
	runner.newline()
	
	return runner

## Compiles the expression, adding text to the runner function if any text was provided.
## The compilation process produces a gdscript file will all data added to it.
##
## @param: text: String - The text to add, if any
##
## @return: int - The error code
func compile(text: String = "") -> int:
	if not text.empty():
		runner.add(text)
	gdscript = _create_script(raw, variables, functions, runner)
	
	return gdscript.reload()

## Injects the given variables into the compiled GDScript instance
##
## @example:
##	{
##		"my_variable": "my_string_value"
##	}
##
## @param: data: Dictionary - The data to inject into the script
##
## @return: int - The error code
func inject_variables(data: Dictionary) -> int:
	var script_instance = _get_instance()
	
	for key in data.keys():
		script_instance.set(key, data[key])
	
	return OK

## Executes the runner function on the GDScript instance. Params can be passed to the
## runner function if parameters were defined beforehand
##
## @param: params: Array - The params to pass to the runner function
##
## @return: Variant - The return value of the runner function, if any
func execute(params: Array = []):
	return _get_instance().callv(RUN_FUNC, params)

## Clears all data
func clear() -> void:
	gdscript = null
	instance = null
	
	variables.clear()
	functions.clear()
	runner = Runner.new()