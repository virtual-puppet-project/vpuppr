extends BaseElement

onready var label: Label = $HBoxContainer/Label
onready var toggle1: CheckButton = $HBoxContainer/HBoxContainer/CheckButton1
onready var toggle2: CheckButton = $HBoxContainer/HBoxContainer/CheckButton2

var toggle1_label: String
var toggle2_label: String

var toggle1_value := false
var toggle2_value := false

###############################################################################
# Builtin functions                                                           #
###############################################################################

func _ready() -> void:
	label.text = label_text
	toggle1.text = toggle1_label
	toggle2.text = toggle2_label
	toggle1.pressed = toggle1_value
	toggle2.pressed = toggle2_value
	
	toggle1.disabled = is_disabled
	toggle2.disabled = is_disabled
	
	toggle1.connect("toggled", self, "_on_toggled1")
	toggle2.connect("toggled", self, "_on_toggled2")

###############################################################################
# Connections                                                                 #
###############################################################################

func _on_toggled1(button_state: bool) -> void:
	_handle_event([event_name, label.text, toggle1.text.to_lower(), button_state])

func _on_toggled2(button_state: bool) -> void:
	_handle_event([event_name, label.text, toggle2.text.to_lower(), button_state])

func _on_bone_toggled(bone_name: String, _toggle_type: String, toggle_value: bool) -> void:
	if not toggle_value:
		return
	if bone_name != label.text:
		toggle2.set_pressed_no_signal(false)

func _on_head_bone(head_bone_name: String) -> void:
	if not is_ready:
		yield(self, "ready")
	
	if head_bone_name == label_text:
		toggle1.disabled = true
		toggle2.disabled = true
	else:
		toggle1.disabled = false
		toggle2.disabled = false

###############################################################################
# Private functions                                                           #
###############################################################################

###############################################################################
# Public functions                                                            #
###############################################################################

func get_value():
	return label.text

func set_value(_value) -> void:
	AppManager.log_message("Tried to set value on a double toggle")
