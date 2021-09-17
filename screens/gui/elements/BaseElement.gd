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

###############################################################################
# Builtin functions                                                           #
###############################################################################

func _ready() -> void:
	is_ready = true

###############################################################################
# Connections                                                                 #
###############################################################################

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
