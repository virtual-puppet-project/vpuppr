extends BaseElement

const DEBOUNCE_TIME: float = 0.5

onready var label: Label = $HBoxContainer/Label
onready var line_edit: LineEdit = $HBoxContainer/LineEdit

var data_type: String

var debounce_counter: float = 0
var should_emit := false

###############################################################################
# Builtin functions                                                           #
###############################################################################

func _ready() -> void:
	label.text = label_text
	
	line_edit.editable = not is_disabled
	
	line_edit.connect("text_entered", self, "_on_text_entered")
	line_edit.connect("text_changed", self, "_on_text_changed")

func _process(delta: float) -> void:
	if should_emit:
		if debounce_counter < DEBOUNCE_TIME:
			debounce_counter += delta
		else:
			debounce_counter = 0.0
			should_emit = false
			_emit_event(line_edit.text)

###############################################################################
# Connections                                                                 #
###############################################################################

func _on_text_entered(text: String) -> void:
	_handle_event(text)

func _on_text_changed(_text: String) -> void:
	should_emit = true

###############################################################################
# Private functions                                                           #
###############################################################################

func _emit_event(text: String) -> void:
	if text.empty():
		return
	var result
	if data_type:
		match data_type:
			"string", "String":
				result = text
			"float":
				if not text.is_valid_float():
					return
				result = float(text)
			"integer", "int":
				if not text.is_valid_integer():
					return
				result = int(text)
			_:
				return
	_handle_event([event_name, result])

###############################################################################
# Public functions                                                            #
###############################################################################

func get_value():
	return line_edit.text

func set_value(value) -> void:
	line_edit.text = str(value)
