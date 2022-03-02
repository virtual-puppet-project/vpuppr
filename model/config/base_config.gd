class_name BaseConfig
extends Reference

# Completely generic key/value structure for random values
# Try and prefer using explicit fields over using this
var other := {}

func _to_string() -> String:
	return get_as_json_string()

#region Export

func get_as_dict() -> Dictionary:
	var r := {}

	for i in get_property_list():
		if i.name in GlobalConstants.IGNORED_PROPERTIES_REFERENCE:
			continue

		r[i.name] = get(i.name)

	return r

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
			
			return Result.ok(r)
		TYPE_ARRAY:
			var r := []
			
			for v in data:
				var result := _parse_data(v)
				if result.is_err():
					return result
				
				r.append(result.unwrap())
			
			return Result.ok(r)
		TYPE_OBJECT:
			return Result.ok(data.get_as_dict())
		_:
			return Result.ok(data)

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
	
	return Result.ok()

func parse_string(data: String) -> Result:
	var json_result := JSON.parse(data)
	if json_result.error != OK:
		return Result.err(Error.Code.BASE_CONFIG_PARSE_FAILURE, json_result.error_string)

	var json_data = json_result.result
	if typeof(json_data) != TYPE_DICTIONARY:
		return Result.err(Error.Code.BASE_CONFIG_UNEXPECTED_DATA, str(json_data))

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

	AM.logger.error("key not found %s" % key)
	
	return null # Still null but log something

func _split_query(query: String) -> PoolStringArray:
	return query.lstrip("/").rstrip("/").split("/")

func _find_data(split_query: PoolStringArray) -> Array:
	"""
	Grab nested data using Godot-style node path syntax.
	
	Also optionally change the data if a new_value is provided. The value must already exist. Returns OK on success

	e.g. other/some_array/0
	"""
	if split_query.empty():
		AM.logger.error("Search query was empty %s" % split_query)
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
		
		AM.logger.error("Invalid search query %s" % split_query)
		
		return []

	return r

	# if new_value != null:
	# 	var val = r[r.size() - 2]
	# 	var key = keys[keys.size() - 1]
	# 	match typeof(val):
	# 		TYPE_OBJECT:
	# 			val.set(key, new_value)
	# 			return null
	# 		TYPE_ARRAY:
	# 			val[int(key)] = new_value
	# 			return null
	# 		TYPE_DICTIONARY:
	# 			val[key] = new_value
	# 			return null
	# 	AM.logger.error("Unable to set nested value %s - %s" % [query, str(new_value)])
	# 	return OK
	# else:
	# 	return r.pop_back()

func find_data_get(query: String) -> Result:
	var r := _find_data(_split_query(query))

	if r.empty():
		return Result.err(Error.Code.BASE_CONFIG_DATA_NOT_FOUND)

	return Result.ok(r.pop_back())

func find_data_set(query: String, new_value) -> Result:
	var split := _split_query(query)
	var r := _find_data(split)

	if r.empty():
		return Result.err(Error.Code.BASE_CONFIG_DATA_NOT_FOUND)

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
			return Result.err(Error.Code.BASE_CONFIG_UNHANDLED_FIND_SET_DATA_TYPE)

	return Result.ok()

func set_data(key: String, value):
	if get(key) != null:
		set(key, value)
	else:
		other[key] = value

#endregion
