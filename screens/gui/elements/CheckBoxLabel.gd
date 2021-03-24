class_name CheckBoxLabel
extends BaseMenuItem

onready var check_box: CheckBox = $HBoxContainer/CheckBox

var check_box_value: bool = false
var check_box_disabled: bool = false
var check_box_text: String

###############################################################################
# Builtin functions                                                           #
###############################################################################

func _ready() -> void:
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

func get_value() -> bool:
	return check_box.pressed
