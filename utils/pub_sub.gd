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
## An optional RegisterPayload ca be defined to customize the connection args
##
## @param: o: Object - The object that will have its callback called
## @param: signal_name: String - The signal to subscribe to on the PubSub
## @param: payload: PubSubRegisterPayload - The register payload to use
func register(o: Object, signal_name: String, payload: PubSubRegisterPayload = null) -> Result:
	if not has_user_signal(signal_name):
		return Result.err(Error.Code.SIGNAL_DOES_NOT_EXIST)

	var args := []
	var callback := ""

	if payload != null:
		args.append_array(payload.args)
		callback = payload.callback

	if connect(
		signal_name,
		o,
		"_on_%s" % signal_name if callback.empty() else callback,
		args
	) != OK:
		return Result.err(Error.Code.CONNECT_FAILED)

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
