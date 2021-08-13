class_name BaseElement
extends PanelContainer

signal event(args)

var label_text: String
var event_name: String

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

func set_value(value) -> void:
	AppManager.log_message("%s.set_value() not implemented" % self.name)
