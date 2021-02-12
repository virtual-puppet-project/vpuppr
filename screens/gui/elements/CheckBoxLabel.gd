class_name CheckBoxLabel
extends MarginContainer

onready var label: Label = $HBoxContainer/Label
onready var check_box: CheckBox = $HBoxContainer/CheckBox

var label_text: String = "changeme"

var check_box_value: bool = false
var check_box_disabled: bool = false
var check_box_text: String

###############################################################################
# Builtin functions                                                           #
###############################################################################

func _ready() -> void:
	label.text = label_text
	
	check_box.pressed = check_box_value
	check_box.disabled = check_box_disabled
	
	if check_box_text:
		check_box.text = check_box_text

###############################################################################
# Connections                                                                 #
###############################################################################

###############################################################################
# Private functions                                                           #
###############################################################################

###############################################################################
# Public functions                                                            #
###############################################################################


