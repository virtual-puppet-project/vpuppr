extends BaseElement

onready var label: Label = $HBoxContainer/Label
onready var line_edit: LineEdit = $HBoxContainer/LineEdit

var prop_name: String
var data_type: String

###############################################################################
# Builtin functions                                                           #
###############################################################################

func _ready() -> void:
	label.text = label_text
	
	line_edit.connect("text_entered", self, "_on_text_entered")

###############################################################################
# Connections                                                                 #
###############################################################################

func _on_text_entered(text: String) -> void:
	var result
	if data_type:
		match data_type:
			"string", "String":
				result = text
			"float":
				if not text.is_valid_float():
					AppManager.log_message("%s is not valid float" % text, true)
					return
				result = float(text)
			"integer", "int":
				if not text.is_valid_integer():
					AppManager.log_message("%s is not valid integer" % text, true)
					return
				result = int(text)
			_:
				AppManager.log_message("Unhandled data type: %s" % data_type, true)
				return
	_handle_event([event_name, prop_name, result])

###############################################################################
# Private functions                                                           #
###############################################################################

###############################################################################
# Public functions                                                            #
###############################################################################

func get_value():
	return line_edit.text

func set_value(value) -> void:
	line_edit.text = str(value)
