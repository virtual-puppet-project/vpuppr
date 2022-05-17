class_name PubSubRegisterPayload
extends Reference

## The connect args
var args := []
## The callback function to use
var callback := ""

## There are 3 supported arguments for init
## 1. Dictionary - {"args": [connect, args], "callback": "callback_func"}
## 2. Array - [connect, args]
## 3. String - "callback_func"
func _init(v = null) -> void:
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
