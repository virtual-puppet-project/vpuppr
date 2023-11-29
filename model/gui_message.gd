class_name GUIMessage
extends RefCounted

enum {
	NONE = 0,
	
	SETTING_CHANGED, ## A setting field was changed consisting of a property key and propery value. Should be converted using [method to_data_update].
	DATA_UPDATE, ## Config should be changed consisting of an index path and [Dictionary] key-value payload.
	
	TRACKER_START,
	TRACKER_STOP,
	TRACKER_STOP_ALL,
	
	REQUEST_UPDATE,
	
	FLY_CAMERA,
	
	CUSTOM,
}

var caller: Object = null
var action := NONE
var key: Variant = null
var value: Variant = null

#-----------------------------------------------------------------------------#
# Builtin functions
#-----------------------------------------------------------------------------#

func _init(p_caller: Object, p_action: int, p_key: Variant = null, p_value: Variant = null) -> void:
	caller = p_caller
	@warning_ignore("int_as_enum_without_cast")
	action = p_action
	key = p_key
	value = p_value

func _to_string() -> String:
	return JSON.stringify({
		caller = caller.name if caller.has("name") else "Object",
		action = action,
		key = key,
		value = value
	})

#-----------------------------------------------------------------------------#
# Private functions
#-----------------------------------------------------------------------------#

#-----------------------------------------------------------------------------#
# Public functions
#-----------------------------------------------------------------------------#

func to_data_update(new_key: String, field_name: String, field_value: Variant) -> GUIMessage:
	if action != SETTING_CHANGED:
		AM.logger.error("Expected SETTING_CHANGED, got {action} while converting to DATA_UPDATE".format({
			action = action
		}))
		return null
	
	return GUIMessage.new(caller, DATA_UPDATE, new_key, {key = field_name, value = field_value})
