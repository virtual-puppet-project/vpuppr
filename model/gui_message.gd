class_name GUIMessage
extends RefCounted

enum {
	NONE = 0,
	
	DATA_UPDATE,
	
	TRACKER_START,
	TRACKER_STOP,
	TRACKER_STOP_ALL,
	
	REFRESH,
	
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

#-----------------------------------------------------------------------------#
# Private functions
#-----------------------------------------------------------------------------#

#-----------------------------------------------------------------------------#
# Public functions
#-----------------------------------------------------------------------------#
