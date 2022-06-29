class_name TempCacheManager
extends AbstractManager

const TEMP_CACHE_MANAGER_NAME := "TempCacheManagerName"

var _cache := {}

#-----------------------------------------------------------------------------#
# Builtin functions                                                           #
#-----------------------------------------------------------------------------#

func _init() -> void:
	pass

func _setup_logger() -> void:
	logger = Logger.new(TEMP_CACHE_MANAGER_NAME)

#-----------------------------------------------------------------------------#
# Connections                                                                 #
#-----------------------------------------------------------------------------#

#-----------------------------------------------------------------------------#
# Private functions                                                           #
#-----------------------------------------------------------------------------#

#-----------------------------------------------------------------------------#
# Public functions                                                            #
#-----------------------------------------------------------------------------#

## Clear the cache. If any values are `Nodes`, they have `queue_free` called on
## them if applicable
##
## @return: void
func clear() -> void:
	for key in _cache:
		var val = _cache[key]

		if val is Object and val.is_class("Node") and is_instance_valid(val) and not val.is_queued_for_deletion():
			val.queue_free()

	_cache.clear()

## Erases a given key from the cache
##
## @param: key: String - The key to erase
func erase(key: String) -> void:
	_cache.erase(key)

## Push a value to the cache under the given key
##
## @param: key: String - The key to store the value under
## @param: value: Variant - The value to cache
func push(key: String, value) -> void:
	_cache[key] = value

## Pull a value from the cache, null-safe. Null is returned if no value is found
## for the given key.
##
## @note: Does _not_ return Error.Code.NULL_VALUE if no key is found
##
## @param: key: String - The key to grab a value from
##
## @return: Variant - The cached value, if it exists
func pull(key: String, default_value = null) -> Result:
	var ret = _cache.get(key, default_value)
	if ret != null:
		return Result.ok(ret)
	else:
		return Result.err(Error.Code.TEMP_CACHE_MANAGER_KEY_NOT_FOUND, key)
