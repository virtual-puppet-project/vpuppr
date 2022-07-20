class_name BaseConfig
extends Reference

## Completely generic key/value structure for random values
## Try and prefer using explicit fields over using this
var other := {}

func _to_string() -> String:
	return get_as_json_string()

#region Export

## Gets all valid properties as a Dictionary
##
## @return: Dictionary - The Dictionary of properties from the current config
func get_as_dict() -> Dictionary:
	var r := {}

	for i in get_property_list():
		if i.name in Globals.IGNORED_PROPERTIES:
			continue

		r[i.name] = get(i.name)

	return r

## Gets all valid properties as a JSON String
##
## @see: `get_as_dict`
##
## @return: String - The JSON String
func get_as_json_string() -> String:
	return JSON.print(get_as_dict(), "\t")

#endregion

#region Parsing

func _parse_data(data) -> Result:
	if data is Result:
		return data
	
	match typeof(data):
		TYPE_DICTIONARY:
			var r := {}
			
			for key in data.keys():
				var result := _parse_data(data[key])
				if result.is_err():
					return result
				r[key] = result.unwrap()
			
			return Safely.ok(r)
		TYPE_ARRAY:
			var r := []
			
			for v in data:
				var result := _parse_data(v)
				if result.is_err():
					return result
				
				r.append(result.unwrap())
			
			return Safely.ok(r)
		TYPE_OBJECT:
			return Safely.ok(data.get_as_dict())
		_:
			return Safely.ok(data)

func parse_dict(data: Dictionary) -> Result:
	var result: Result
	if data.has("other"):
		result = _parse_data(data["other"])
		if result.is_err():
			return result
		other = result.unwrap()

	for key in data.keys():
		if key == "other":
			continue
		var value = data[key]

		match typeof(value):
			TYPE_DICTIONARY, TYPE_ARRAY:
				result = _parse_data(value)
				if result.is_err():
					return result
				if get(key) != null:
					set(key, result.unwrap())
				else:
					other[key] = result.unwrap()
			TYPE_VECTOR2:
				pass
			_:
				if get(key) != null: # All fields will be initialized with a value
					set(key, value)
				else:
					other[key] = value
	
	return Safely.ok()

func parse_string(data: String) -> Result:
	var json_result := JSON.parse(data)
	if json_result.error != OK:
		return Safely.err(Error.Code.BASE_CONFIG_PARSE_FAILURE, json_result.error_string)

	var json_data = json_result.result
	if typeof(json_data) != TYPE_DICTIONARY:
		return Safely.err(Error.Code.BASE_CONFIG_UNEXPECTED_DATA, str(json_data))

	return parse_dict(json_data)

#endregion

#region Data getter/setter

func has_data(key: String) -> bool:
	if get(key) != null:
		return true
	elif other.has(key):
		return true
	return false

func get_data(key: String):
	var r = get(key)
	if r != null:
		return r
	
	r = other.get(key)
	if r != null:
		return r
	
	return null # Still null but log something

## Splits a node-path query into a PoolStringArray
##
## @example: other/some_array/0 -> ["other", "some_array", "0"]
##
## @param: query: String - The node-path query
##
## @return: PoolStringArray - The split node-path query
static func _split_query(query: String) -> PoolStringArray:
	return query.lstrip("/").rstrip("/").split("/")

## Grabs a nested chain of data following node-path syntax
##
## @example: other/some_array/0 - Finds index 0 of some_array of other
##
## @param: PoolStringArray - The query in node-path syntax
##
## @return: Array - The chain of data
func _find_data(split_query: PoolStringArray) -> Array:
	if split_query.empty():
		AM.logger.error("base_config: Search query was empty %s" % split_query)
		return []
	
	var r := [self]

	for key_idx in split_query.size():
		var current_container = r[key_idx]
		var key: String = split_query[key_idx]
		
		var val
		
		match typeof(current_container):
			TYPE_OBJECT, TYPE_DICTIONARY:
				val = current_container.get(key)
			TYPE_ARRAY:
				if key.is_valid_integer():
					val = current_container[int(key)]
		
		if val != null:
			r.append(val)
			continue
		
		AM.logger.error("base_config: Invalid search query %s" % split_query)
		
		return []

	return r

## Finds nested data using node-path syntax
##
## @see: _find_data
##
## @param: query: String - The query in node-path syntax
##
## @return: Result<Variant> - The final item in the query
func find_data_get(query: String) -> Result:
	var r := _find_data(_split_query(query))

	if r.empty():
		return Safely.err(Error.Code.BASE_CONFIG_DATA_NOT_FOUND)

	return Safely.ok(r.pop_back())

## Finds nested data and replaces it with a new value using node-path syntax
##
## @see: _find_data
##
## @param: query: String - The query in node-path syntax
## @param: new_value: Variant - The replacement value
##
## @return: Result<int> - The error code
func find_data_set(query: String, new_value) -> Result:
	var split := _split_query(query)
	var r := _find_data(split)

	if r.empty():
		return Safely.err(Error.Code.BASE_CONFIG_DATA_NOT_FOUND)

	var val = r[r.size() - 2]
	var key = split[split.size() - 1]
	match typeof(val):
		TYPE_OBJECT:
			val.set(key, new_value)
		TYPE_ARRAY:
			val[int(key)] = new_value
		TYPE_DICTIONARY:
			val[key] = new_value
		_:
			return Safely.err(Error.Code.BASE_CONFIG_UNHANDLED_FIND_SET_DATA_TYPE)

	# TODO might not need this?
	# AM.ps.publish(key, new_value)
	
	return Safely.ok()

## Set data on the current config
##
## @param: key: String - The key that corresponds to a property on the config. Will resolve
## to the other Dictionary if the property does not exist
## @param: value: Variant - The new value
func set_data(key: String, value) -> void:
	if get(key) != null:
		set(key, value)
	else:
		other[key] = value

#endregion
