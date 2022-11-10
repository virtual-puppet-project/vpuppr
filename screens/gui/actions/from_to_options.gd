extends VBoxContainer

enum Type {
	NONE, FROM, TO
}

signal from_changed(value)
signal to_changed(value)

#-----------------------------------------------------------------------------#
# Builtin functions                                                           #
#-----------------------------------------------------------------------------#

# TODO need a way to read from config
func _ready() -> void:
	$From/LineEdit.connect("text_changed", self, "_on_line_edit_text_changed", [Type.FROM])
	$To/LineEdit.connect("text_changed", self, "_on_line_edit_text_changed", [Type.TO])

#-----------------------------------------------------------------------------#
# Connections                                                                 #
#-----------------------------------------------------------------------------#

func _on_line_edit_text_changed(text: String, type: int) -> void:
	if not text.is_valid_float():
		return
	match type:
		Type.FROM:
			emit_signal("from_changed", text.to_float())
		Type.TO:
			emit_signal("to_changed", text.to_float())

#-----------------------------------------------------------------------------#
# Private functions                                                           #
#-----------------------------------------------------------------------------#

#-----------------------------------------------------------------------------#
# Public functions                                                            #
#-----------------------------------------------------------------------------#
