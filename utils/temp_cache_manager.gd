class_name TempCacheManager
extends AbstractManager

var _cache := {}

#-----------------------------------------------------------------------------#
# Builtin functions                                                           #
#-----------------------------------------------------------------------------#

func _init() -> void:
	pass

func _setup_logger() -> void:
	logger = Logger.new("TempCacheManager")

func _setup_singleton() -> void:
	__SELF__["TempCacheManager"] = self

static func get_singleton(_x = "") -> AbstractManager:
	return .get_singleton("TempCacheManager")

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

		if val.is_class("Node") and is_instance_valid(val) and not val.is_queued_for_deletion():
			val.queue_free()

	_cache.clear()

## Push a value to the cache under the given key
##
## @param: key: String - The key to store the value under
## @param: value: Variant - The value to cache
func push(key: String, value) -> void:
	_cache[key] = value

## Pull a value from the cache, null-safe
##
## @param: key: String - The key to grab a value from
##
## @return: Variant - The cached value, if it exists
func pull(key: String):
	var val = _cache.get(key, null)
	if val == null:
		logger.error("No value found in cache for key %s" % key)

	return val
