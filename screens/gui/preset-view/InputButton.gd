extends MarginContainer

onready var line_edit: LineEdit = $MarginContainer/HBoxContainer/LineEdit
onready var save_button: Button = $MarginContainer/HBoxContainer/SaveButton

var save_button_disabled: bool = false
var save_button_text: String

###############################################################################
# Builtin functions                                                           #
###############################################################################

func _ready() -> void:
	save_button.disabled = save_button_disabled
	
	if save_button_text:
		save_button.text = save_button_text

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
	AppManager.log_message("Tried to get value on %s, access the name property instead" % self.name)
