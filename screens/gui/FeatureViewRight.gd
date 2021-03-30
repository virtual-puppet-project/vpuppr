extends BaseSidebar

var initial_properties: Dictionary

###############################################################################
# Builtin functions                                                           #
###############################################################################

func _ready() -> void:
	_setup()

###############################################################################
# Connections                                                                 #
###############################################################################

func _on_apply_button_pressed() -> void:
	_apply_properties()

func _on_reset_button_pressed() -> void:
	_generate_properties(initial_properties)

###############################################################################
# Private functions                                                           #
###############################################################################

func _generate_properties(p_initial_properties: Dictionary = Dictionary()) -> void:
	_create_element(ElementType.LABEL, "props", "Props")
	pass

func _apply_properties() -> void:
	pass

func _setup() -> void:
	current_model = main_screen.model_display_screen.model

	_generate_properties()

	# Store initial properties
	for child in v_box_container.get_children():
		if child.get("check_box"):
			initial_properties[child.name] = child.check_box.pressed
		elif child.get("line_edit"):
			initial_properties[child.name] = child.line_edit.text

###############################################################################
# Public functions                                                            #
###############################################################################


