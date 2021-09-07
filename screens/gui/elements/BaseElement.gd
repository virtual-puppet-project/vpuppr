class_name BaseElement
extends PanelContainer

signal event(args)

# The display name for the element
var label_text: String
# The corresponding signal in the SignalBroadcaster
var event_name: String
# The config data
var data_bind: String
# If the actual element should be editable
var is_disabled := false

var parent

###############################################################################
# Builtin functions                                                           #
###############################################################################

###############################################################################
# Connections                                                                 #
###############################################################################

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
			if data_bind == "should_track_eye":
				print("%s : %s" % [event_name, data])
			return
		
		# Metadata
		data = AppManager.cm.metadata_config.get(data_bind)
		if data != null:
			set_value(data)
			return
