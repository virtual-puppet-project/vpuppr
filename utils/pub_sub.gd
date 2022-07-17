class_name PubSub
extends AbstractManager

## PubSub (Publish Subscribe) handler
##
## Data can be published in 2 ways
## 1. Calling `publish` which will either emit the signal directly or wrap data in a `SignalPayload`
## 2. Directly emitting a signal
##
## Option 1 should be preferred

func _init() -> void:
	pass

func _setup_logger() -> void:
	logger = Logger.new("PubSub")

## Creates a user signal to be stored on the PubSub
##
## @param: signal_name: String - The signal to create
##
## @return: Result<int> - The error code
func create_signal(signal_name: String) -> Result:
	if signal_name.empty():
		return Safely.err(Error.Code.PUB_SUB_INVALID_SIGNAL_NAME)
	if has_user_signal(signal_name):
		return Safely.err(Error.Code.PUB_SUB_USER_SIGNAL_ALREADY_EXISTS)

	add_user_signal(signal_name)

	return Safely.ok()

## Wrapper for subscribing (connecting) an object to the PubSub
##
## @param: o: Object - The object that will have its callback called
## @param: signal_name: String - The signal to subscribe to on the PubSub
## @param: payload: Variant - The payload to use
## Can be a: String, Array, or Dictionary
func subscribe(o: Object, signal_name: String, payload = null) -> Result:
	if not has_user_signal(signal_name) and not has_signal(signal_name):
		return Safely.err(Error.Code.SIGNAL_DOES_NOT_EXIST)

	var args := []
	var callback := ""

	if payload != null:
		var parsed_payload := _parse_register_payload(payload)

		args.append_array(parsed_payload.get("args", []))
		callback = parsed_payload.get("callback", "")

	if is_connected(signal_name, o, "_on_%s" % signal_name if callback.empty() else callback):
		return Safely.ok()

	var err: int = connect(
		signal_name,
		o,
		"_on_%s" % signal_name if callback.empty() else callback,
		args
	)

	if err == ERR_INVALID_PARAMETER:
		return Safely.err(Error.Code.PUB_SUB_ALREADY_CONNECTED, signal_name)

	if err != OK:
		return Safely.err(Error.Code.CONNECT_FAILED)

	return Safely.ok()

## Parses a payload for the `register` function
##
## @param: data: Variant - A String, Array, or Dictionary
## - String: interpreted as a callback
## - Array: interpreted as connect args
## - Dictionary: interpreted as possibly containing a callback and connect args
##
## @return: Dictionary - Contains an `args` and `callback` key whether or
## not they actually exist
func _parse_register_payload(data) -> Dictionary:
	var r := {}

	match typeof(data):
		TYPE_DICTIONARY:
			r["args"] = data.get("args", [])

			r["callback"] = data.get("callback", "")
		TYPE_ARRAY:
			r["args"] = data
		TYPE_STRING:
			r["callback"] = data
		_:
			AM.logger.error("Unhandled PubSub Payload param")

	return r

## Emits a signal with the given data with an optional data id. Falls back to calling
## `publish_generic` if the signal is not recognized by the PubSub
##
## @see: `SignalPayload`
##
## @param: signal_name: String - The name of the signal to emit on
## @param: data: Variant - The data to pass along with the `SignalPayload`
## @param: id: Variant - The id to be used with the `SignalPayload`
##
## @return: Result<int> - The error code
func publish(signal_name: String, data, id = null) -> Result:
	if not has_user_signal(signal_name) or not has_signal(signal_name):
		return publish_generic(signal_name, data, id)

	emit_signal(signal_name, SignalPayload.new(signal_name, data, id))
	
	return Safely.ok()

signal event_published(data)
## Emits a generic `event_published` signal with the given data
##
## @see: `SignalPayload`
##
## @param: signal_name: String - The name of the signal to pass along with the payload
## @param: data: Variant - The data to pass along with the payload
## @param: id: Variant - The id to be used with the `SignalPayload`
##
## @return: Result<int> - The error code
func publish_generic(signal_name: String, data, id = null) -> Result:
	emit_signal("event_published", SignalPayload.new(signal_name, data, id))
	
	return Safely.ok()
