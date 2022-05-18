class_name PubSub
extends AbstractManager

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
		return Result.err(Error.Code.PUB_SUB_INVALID_SIGNAL_NAME)
	if has_user_signal(signal_name):
		return Result.err(Error.Code.PUB_SUB_USER_SIGNAL_ALREADY_EXISTS)

	add_user_signal(signal_name)

	return Result.ok()

## Wrapper for subscribing (connecting) an object to the PubSub
##
## @param: o: Object - The object that will have its callback called
## @param: signal_name: String - The signal to subscribe to on the PubSub
## @param: payload: Variant - The payload to use
## Can be a: String, Array, or Dictionary
func subscribe(o: Object, signal_name: String, payload = null) -> Result:
	if not has_user_signal(signal_name):
		return Result.err(Error.Code.SIGNAL_DOES_NOT_EXIST)

	var args := []
	var callback := ""

	if payload != null:
		var parsed_payload := _parse_register_payload(payload)

		args.append_array(parsed_payload.get("args", []))
		callback = parsed_payload.get("callback", "")

	if connect(
		signal_name,
		o,
		"_on_%s" % signal_name if callback.empty() else callback,
		args
	) != OK:
		return Result.err(Error.Code.CONNECT_FAILED)

	return Result.ok()

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

## Emits a signal with the given data with an optional data id if the data
## is a collection
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
		return Result.err(Error.Code.PUB_SUB_SIGNAL_NOT_FOUND, signal_name)

	emit_signal(signal_name, SignalPayload.new(signal_name, data, id))
	
	return Result.ok()

signal logger_rebroadcast(message)
## Rebroadcasts logger messages
##
## @param: message: String - The message
func broadcast_logger_rebroadcast(message: String) -> void:
	emit_signal("logger_rebroadcast", message)

signal model_loaded(model)
## Indicates when it's okay to start applying tracking data
##
## @param: model: PuppetTrait - The model that was loaded
func broadcast_model_loaded(model: PuppetTrait) -> void:
	emit_signal("model_loaded", model)
