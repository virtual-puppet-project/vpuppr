class_name Result
extends Reference

var _value
var _error: Error

func _init(v) -> void:
	if not v is Error:
		_value = v
	else:
		_error = v

func _to_string() -> String:
	if is_err():
		return "ERR: %s" % str(_error)
	else:
		return "OK: %s" % str(_value)

## Checks if the result does _not_ contain an error
##
## @return: bool - Whether or not the data is _not_ an error
func is_ok() -> bool:
	return not is_err()

## Checks if the result _does_ contain an error
##
## @return: bool - Whether or not the data is an error
func is_err() -> bool:
	return _error != null

## Returns the value contained by the Result
##
## @return: Variant - The value contained by the Result
func unwrap():
	return _value

## Returns the Error contained by the Result
##
## @return: Error - The error contained by the Result
func unwrap_err() -> Error:
	return _error

## Returns the value contained by the Result or else logs an error
##
## @param: text: String - The error to be logged to the console if the result
## is not null
##
## @return: Variant - The value contained by the Result
func expect(text: String):
	if is_err():
		AM.logger.error(text)
		return null
	return _value

## Returns the value contained by the Result or else the backup value
##
## @param: Variant - The alternative value to be returned
##
## @return: Variant - The value to be returned
func or_else(val):
	return _value if is_ok() else val

## Helper function for generating new, successful Results
##
## @param: v: Variant - The value contained by the Result
##
## @return: Result<Variant> - The successful Result
static func ok(v = null) -> Result:
	return load("res://model/result.gd").new(v if v != null else OK)

## Helper function for generating new, failure Results
##
## @param: error_code: int - The error code to assign to the Result
## @param: description: String - The optional description of the Error
##
## @return: Result<Error> - The failed Result
static func err(error_code: int, description: String = "") -> Result:
	return load("res://model/result.gd").new(Error.new(error_code, description))
