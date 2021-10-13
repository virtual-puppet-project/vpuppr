extends BaseElement

onready var line_edit: LineEdit = $HBoxContainer/LineEdit
onready var button: Button = $HBoxContainer/Button

###############################################################################
# Builtin functions                                                           #
###############################################################################

func _ready() -> void:
	line_edit.placeholder_text = label_text
	
	line_edit.editable = not is_disabled
	button.disabled = is_disabled
	
	button.connect("pressed", self, "_on_button_pressed")

###############################################################################
# Connections                                                                 #
###############################################################################

func _on_button_pressed() -> void:
	_handle_event([event_name, line_edit.text])

###############################################################################
# Private functions                                                           #
###############################################################################

###############################################################################
# Public functions                                                            #
###############################################################################

func get_value():
	return line_edit.pressed

func set_value(value) -> void:
	line_edit.pressed = value
