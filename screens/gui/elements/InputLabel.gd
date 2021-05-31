class_name InputLabel
extends BaseMenuItem

onready var line_edit: LineEdit = $MarginContainer/HBoxContainer/LineEdit

var line_edit_type = TYPE_STRING
var line_edit_text: String = "changeme"

###############################################################################
# Builtin functions                                                           #
###############################################################################

func _ready() -> void:
	line_edit.text = line_edit_text

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
	match line_edit_type:
		TYPE_STRING:
			return line_edit.text
		TYPE_REAL:
			return float(line_edit.text)
		TYPE_INT:
			return int(line_edit.text)
