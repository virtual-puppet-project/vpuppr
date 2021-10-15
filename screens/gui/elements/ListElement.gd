extends BaseElement

const PropData: Resource = preload("res://screens/gui/PropData.gd")
const PresetData: Resource = preload("res://screens/gui/PresetData.gd")

onready var label: Label = $VBoxContainer/Label
onready var vbox: VBoxContainer = $VBoxContainer

###############################################################################
# Builtin functions                                                           #
###############################################################################

func _ready() -> void:
	label.text = label_text

###############################################################################
# Connections                                                                 #
###############################################################################

func _cleanup() -> void:
	clear_details()

###############################################################################
# Private functions                                                           #
###############################################################################

###############################################################################
# Public functions                                                            #
###############################################################################

func clear_details() -> void:
	var is_first: bool = true

	for c in vbox.get_children():
		if is_first:
			is_first = false
			continue
		c.queue_free()

func get_value():
	return vbox.get_children()

func set_value(_value) -> void:
	AppManager.log_message("Skipping set_value on %s" % name)
	pass
