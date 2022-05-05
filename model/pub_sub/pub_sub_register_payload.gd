class_name PubSubRegisterPayload
extends Reference

var args := []
var callback := ""

func _init(v = null) -> void:
	"""
	There are 3 supported arguments for init
	1. Dictionary - {"args": [connect args], "callback": "value"}
	2. Array - [connect args]
	3. String - custom_callback
	"""
	if v == null:
		return

	match typeof(v):
		TYPE_DICTIONARY:
			args = v.get("args", [])
			if not args.empty():
				args = args.duplicate(true)

				callback = v.get("callback", "")
		TYPE_ARRAY:
			args = v.duplicate(true)
		TYPE_STRING:
			callback = v
		_:
			AM.logger.error("Unhandled PubSub Payload param")
			return
