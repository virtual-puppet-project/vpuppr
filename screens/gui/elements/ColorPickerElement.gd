extends BaseElement

onready var label: Label = $HBoxContainer/Label
onready var color_picker: ColorPicker = $HBoxContainer/ColorPicker

###############################################################################
# Builtin functions                                                           #
###############################################################################

func _ready() -> void:
	label.text = label_text

	color_picker.connect("color_changed", self, "_on_color_changed")

###############################################################################
# Connections                                                                 #
###############################################################################

func _on_color_changed(color: Color) -> void:
	# emit_signal("event", [event_name, color])
	_handle_event([event_name, color])

###############################################################################
# Private functions                                                           #
###############################################################################

###############################################################################
# Public functions                                                            #
###############################################################################

func get_value():
	return color_picker.color

func set_value(value) -> void:
	color_picker.color = value
