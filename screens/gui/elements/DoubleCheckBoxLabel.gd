extends CheckBoxLabel

onready var second_check_box: CheckBox = $HBoxContainer/SecondCheckBox

var second_check_box_value: bool = false
var second_check_box_disabled: bool = false

var second_check_box_text: String

###############################################################################
# Builtin functions                                                           #
###############################################################################

func _ready() -> void:
	second_check_box.pressed = second_check_box_value
	second_check_box.disabled = second_check_box_disabled
	
	if second_check_box_text:
		second_check_box.text = second_check_box_text

###############################################################################
# Connections                                                                 #
###############################################################################

###############################################################################
# Private functions                                                           #
###############################################################################

###############################################################################
# Public functions                                                            #
###############################################################################


