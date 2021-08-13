extends BaseElement

onready var label: Label = $HBoxContainer/Label
onready var line_edit: LineEdit = $HBoxContainer/LineEdit

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
	emit_signal("event", [event_name, text])

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
