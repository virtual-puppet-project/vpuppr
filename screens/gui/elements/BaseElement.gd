class_name BaseElement
extends PanelContainer

# warning-ignore:unused_signal
signal event(args)

# The display name for the element
var label_text: String
# The corresponding signal in the SignalBroadcaster
var event_name: String
# The config data
var data_bind: String
# If the actual element should be editable
var is_disabled := false

var is_ready := false

var parent
var containing_view: Control

var setup_function: String = ""
var setup_data: Array

###############################################################################
# Builtin functions                                                           #
###############################################################################

func _ready() -> void:
	is_ready = true

	connect("ready", self, "_on_post_ready")

###############################################################################
# Connections                                                                 #
###############################################################################

func _on_post_ready() -> void:
	if (not setup_function.empty() and containing_view.has_method(setup_function)):
		containing_view.call(setup_function, self)

func _on_label_updated(label_name: String, value: String) -> void:
	if label_name != label_text:
		return

	var elem: Control = get("label")
	if elem:
		elem.text = value
		return
	
	elem = get("button")
	if elem:
		elem.text = value

func _on_value_updated(value) -> void:
	set_value(value)

###############################################################################
# Private functions                                                           #
###############################################################################

func _handle_event(event_value) -> void:
	match typeof(event_value):
		TYPE_ARRAY: # input and toggle
			if event_value.size() > 2:
				AppManager.sb.call("broadcast_%s" % event_value[0], event_value.slice(1, event_value.size() - 1))
			else:
				AppManager.sb.call("broadcast_%s" % event_value[0], event_value[1])
		TYPE_STRING:
			AppManager.sb.call("broadcast_%s" % event_value)
		_:
			AppManager.log_message("Unhandled gui event" % str(event_value), true)
	
	if not parent.current_edited_preset:
		AppManager.save_config()
	else:
		AppManager.save_config(parent.current_edited_preset)

###############################################################################
# Public functions                                                            #
###############################################################################

func get_value():
	AppManager.log_message("%s.get_value() not implemented" % self.name)
	return null

func set_value(_value) -> void:
	AppManager.log_message("%s.set_value() not implemented" % self.name)

func setup() -> void:
	if data_bind:
		# ConfigData
		var data = AppManager.cm.current_model_config.get(data_bind)
		if data != null:
			set_value(data)
			return
		
		# Metadata
		data = AppManager.cm.metadata_config.get(data_bind)
		if data != null:
			set_value(data)
			return
