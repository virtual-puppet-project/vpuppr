class_name BaseSidebar
extends Control

enum ElementType { INPUT, CHECK_BOX, TOGGLE }

const CHECK_BOX_LABEL: Resource = preload("res://screens/gui/elements/CheckBoxLabel.tscn")
const INPUT_LABEL: Resource = preload("res://screens/gui/elements/InputLabel.tscn")
const TOGGLE_LABEL: Resource = preload("res://screens/gui/elements/ToggleLabel.tscn")

onready var v_box_container: VBoxContainer = $Control/MarginContainer/VBoxContainer/ScrollContainer/VBoxContainer

onready var main_screen: MainScreen = get_tree().root.get_node_or_null("MainScreen")
var current_model: BasicModel

###############################################################################
# Builtin functions                                                           #
###############################################################################

func _ready() -> void:
	AppManager.connect("model_loaded", self, "_on_model_loaded")

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

###############################################################################
# Private functions                                                           #
###############################################################################

func _setup() -> void:
	push_error("Not yet implemented")

func _create_element(element_type: int, element_name: String, element_label_text: String, element_value, additional_param = null) -> void:
	var result: Node
	match element_type:
		ElementType.INPUT:
			if additional_param != null:
				result = INPUT_LABEL.instance()
				result.line_edit_text = element_value
				result.line_edit_type = additional_param
			else:
				AppManager.push_log("%s needs additional_param for input type" % element_name)
				push_error("%s needs additional_param for input type" % element_name)
				return
		ElementType.CHECK_BOX:
			result = CHECK_BOX_LABEL.instance()
			result.check_box_value = element_value
		ElementType.TOGGLE:
			result = TOGGLE_LABEL.instance()
			result.toggle_button_value = element_value
			result.is_linked_to_other_toggles = additional_param
		_:
			push_error("Unhandled element type")

	result.name = element_name
	result.label_text = element_label_text
	
	v_box_container.add_child(result)

###############################################################################
# Public functions                                                            #
###############################################################################
