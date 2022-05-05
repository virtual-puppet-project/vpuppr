class_name PubSub
extends AbstractManager

func _init() -> void:
	pass

func _setup_logger() -> void:
	logger = Logger.new("PubSub")

class ToggleToggled:
	"""
	Base class for toggle element data
	"""

	var toggle_name := ""
	var toggle_value := false
	
	func _init(p_toggle_name: String, p_toggle_value: bool):
		toggle_name = p_toggle_name
		toggle_value = p_toggle_value

class BoneToggled extends ToggleToggled:
	var toggle_type := ""

	func _init(p_toggle_name: String, p_toggle_type: String, p_toggle_value: bool).(p_toggle_name, p_toggle_value) -> void:
		toggle_type = p_toggle_type

class PropToggled extends ToggleToggled:
	pass

class PresetToggled extends ToggleToggled:
	pass

func create_signal(signal_name: String) -> Result:
	if signal_name.empty():
		return Result.err(Error.Code.PUB_SUB_INVALID_SIGNAL_NAME)
	if has_user_signal(signal_name):
		return Result.err(Error.Code.PUB_SUB_USER_SIGNAL_ALREADY_EXISTS)

	add_user_signal(signal_name)

	return Result.ok()

func register(o: Object, signal_name: String, payload: PubSubRegisterPayload = null) -> Result:
	"""
	Wrapper for subscribing (connecting) an object to the PubSub.

	An optional RegisterPayload can be defined to customize the connection args
	"""
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
func broadcast_logger_rebroadcast(message: String) -> void:
	emit_signal("logger_rebroadcast", message)

signal update_label_text(element_name, value)
func broadcast_update_label_text(element_name: String, value: String) -> void:
	"""
	Usually emitted on a button press.
	
	This is received by a GUI element that changes its label text depending whether
	or not the element_name matches its own.
	"""
	emit_signal("update_label_text", element_name, value)

signal model_loaded(model)
func broadcast_model_loaded(model: PuppetTrait) -> void:
	"""
	Indicates when it's okay to start applying tracking data
	"""
	emit_signal("model_loaded", model)
