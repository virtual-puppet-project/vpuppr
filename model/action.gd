class_name Action
extends Reference

enum Type {
	NONE = 0,
	
	BOOMERANG,
	LOCK,
	GOTO_LOCK
}

var name := ""

## The hotkeys associated with this action
##
## @type: Array<String>
var hotkeys := []

var type: int = Type.NONE

## The key to broadcast the action update on.
## Maps back to signal_name in SignalPayload
var pub_sub_key := ""

var from_value
var to_value

var tween_time: float = 0.0
var tween_transition: int = Tween.TRANS_LINEAR
var tween_easing: int = Tween.EASE_IN_OUT

func is_complete() -> bool:
	return not hotkeys.empty() and type != Type.NONE

func get_as_dict() -> Dictionary:
	return {
		"name": name,
		
		"hotkeys": hotkeys,
		
		"type": type,
		
		"pub_sub_key": pub_sub_key,
		
		"from_value": from_value,
		"to_value": to_value,
		
		"tween_time": tween_time,
		"tween_transition": tween_transition,
		"tween_easing": tween_easing
	}

func parse_dict(data: Dictionary) -> void:
	for key in data.keys():
		set(key, data[key])
