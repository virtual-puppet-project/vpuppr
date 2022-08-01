class_name TempCacheManager
extends AbstractManager

class CleanupBuilder:
	# TODO adding a proper type here causes a memory leak
	var parent: Reference
	var watched_key := ""

	func _init(p_parent: Reference, p_watched_key: String) -> void:
		parent = p_parent
		watched_key = p_watched_key

	func _notification(what: int) -> void:
		match what:
			NOTIFICATION_PREDELETE:
				parent = null

	# TODO this implementation is gross
	func cleanup_on_signal(object: Object, signal_name: String) -> CleanupBuilder:
		if not parent._cleanup_mappings.has(object):
			parent._cleanup_mappings[object] = {}

		if not parent._cleanup_mappings[object].has(signal_name):
			parent._cleanup_mappings[object][signal_name] = []

		parent._cleanup_mappings[object][signal_name].append(watched_key)

		if not object.is_connected(signal_name, parent, "_on_cleanup"):
			object.connect(signal_name, parent, "_on_cleanup", [parent._cleanup_mappings[object][signal_name]])

		return self

	func cleanup_on_pull() -> CleanupBuilder:
		parent._cleanup_on_pull.append(watched_key)

		return self

signal pulled(key_name)

## Keys that should be cleaned up when calling `pull`
## @type: Array<String>
var _cleanup_on_pull := []
var _cleanup_mappings := {}
## @type: Dictionary<String, Variant>
var _cache := {}

#-----------------------------------------------------------------------------#
# Builtin functions                                                           #
#-----------------------------------------------------------------------------#

func _init() -> void:
	pass

func _setup_logger() -> void:
	logger = Logger.new("TempCacheManager")

#-----------------------------------------------------------------------------#
# Connections                                                                 #
#-----------------------------------------------------------------------------#

func _on_cleanup(key) -> void:
	match typeof(key):
		TYPE_ARRAY:
			for key_name in key:
				erase(key_name)

			key.clear()
		TYPE_STRING:
			if key in _cleanup_on_pull:
				erase(key)
				_cleanup_on_pull.erase(key)
		_:
			logger.error("Cannot cleanup key: %s" % str(key))

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
# func push(key: String, value) -> void:
# 	_cache[key] = value

func push(key: String, value) -> CleanupBuilder:
	_cache[key] = value

	return CleanupBuilder.new(self, key)

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

	emit_signal("pulled", key)

	if ret != null:
		return Safely.ok(ret)
	else:
		return Safely.err(Error.Code.TEMP_CACHE_MANAGER_KEY_NOT_FOUND, key)
