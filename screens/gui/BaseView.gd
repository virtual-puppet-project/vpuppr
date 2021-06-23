class_name BaseView
extends Control

enum ElementType { NONE = 0, LABEL, INPUT, CHECK_BOX, TOGGLE, COLOR_PICKER, BUTTON }

const CENTERED_LABEL: Resource = preload("res://screens/gui/elements/CenteredLabel.tscn")
const CHECK_BOX_LABEL: Resource = preload("res://screens/gui/elements/CheckBoxLabel.tscn")
const INPUT_LABEL: Resource = preload("res://screens/gui/elements/InputLabel.tscn")
const TOGGLE_LABEL: Resource = preload("res://screens/gui/elements/ToggleLabel.tscn")
const COLOR_PICKER_LABEL: Resource = preload("res://screens/gui/elements/ColorPickerLabel.tscn")
const BUTTON_LABEL: Resource = preload("res://screens/gui/elements/ButtonLabel.tscn")

onready var left_container: BaseContainer = $LeftContainer
onready var right_container: BaseContainer = $RightContainer

onready var main_screen: MainScreen = get_tree().root.get_node("MainScreen")
var current_model: BasicModel

###############################################################################
# Builtin functions                                                           #
###############################################################################

func _ready() -> void:
	AppManager.connect("model_loaded", self, "_on_model_loaded")

	# Setup stubs
	AppManager.connect("properties_applied", self, "_on_apply_button_pressed")
	AppManager.connect("properties_reset", self, "_on_reset_button_pressed")

###############################################################################
# Connections                                                                 #
###############################################################################

func _on_model_loaded() -> void:
	_setup()

func _on_apply_button_pressed() -> void:
	push_error("Not yet implemented")

func _on_reset_button_pressed() -> void:
	push_error("Not yet implemented")

func _on_gui_toggle_set(toggle_name: String, view_name: String) -> void:
	if view_name != self.name:
		return
	for child in left_container.get_inner_children():
		if not child.get("toggle_button"):
			continue
		
		if toggle_name != child.name:
			child.toggle_button.pressed = false

# Callback to update the text value of a an assioated `LineEdit` objected
# contained within a `MarginContainer`
# value: int - The value returned by `Range.change_value)
# text_box: MarginContainer - The MarginContainer that holds the LineEdit
#	object to update
func _on_hslider_changed(value: int, text_box: MarginContainer) -> void:
	text_box.line_edit.text = str(float(value)/1000)

func _on_hslider_text_changed(text: String, slider: HSlider, text_box: LineEdit) -> void:
	slider.value = int(text)
	# Stop cursor from resetting to start of line
	text_box.set_cursor_position(text.length())

###############################################################################
# Private functions                                                           #
###############################################################################

func _setup() -> void:
	current_model = main_screen.model_display_screen.model

	var loaded_config: Dictionary = AppManager.get_sidebar_config_safe(self.name)
	
	_setup_left(loaded_config)

	_setup_right(loaded_config)

func _setup_left(_config: Dictionary) -> void:
	push_error("Not yet implemented")

func _setup_right(_config: Dictionary) -> void:
	push_error("Not yet implemented")

func _create_element(element_type: int, element_name: String, element_label_text: String, element_value = null, additional_param = null) -> Control:
	var result: Control
	match element_type:
		ElementType.LABEL:
			result = CENTERED_LABEL.instance()
		ElementType.INPUT:
			if additional_param != null:
				result = INPUT_LABEL.instance()
				result.line_edit_text = element_value
				result.line_edit_type = additional_param
			else:
				AppManager.log_message("%s needs additional_param for input type" % element_name, true)
		ElementType.CHECK_BOX:
			result = CHECK_BOX_LABEL.instance()
			result.check_box_value = element_value
		ElementType.TOGGLE:
			result = TOGGLE_LABEL.instance()
			result.toggle_button_value = element_value
			result.is_linked_to_other_toggles = additional_param
			result.linked_screen_name = self.name
		ElementType.COLOR_PICKER:
			result = COLOR_PICKER_LABEL.instance()
			(result as ColorPickerLabel).color_picker_color = element_value
		ElementType.BUTTON:
			result = BUTTON_LABEL.instance()
			(result as ButtonLabel).button_text = element_value
			if typeof(additional_param) == TYPE_DICTIONARY:
				(result as ButtonLabel).link_to_function(additional_param["object"], additional_param["function_name"])
			else:
				AppManager.log_message("%s needs additional_param for button values" % element_name, true)
		_:
			push_error("Unhandled element type")

	result.name = element_name
	result.label_text = element_label_text
	
	return result

###############################################################################
# Public functions                                                            #
###############################################################################

func setup_from_preset(data: Dictionary) -> void:
	current_model = main_screen.model_display_screen.model

	_setup_left(data)

	_setup_right(data)

func save() -> Dictionary:
	var result: Dictionary = {}
	AppManager.log_message("save not yet implemented for %s" % self.name) 
	return result
