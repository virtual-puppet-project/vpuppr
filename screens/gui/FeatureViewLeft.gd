extends BaseSidebar

var initial_properties: Dictionary

var main_light: Light

var light_color: Color = Color.white
var light_energy: float = 1.0
var light_indirect_energy: float = 1.0
var light_specular: float = 0.0

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
	for child in v_box_container.get_children():
		child.free()

	# Light values
	_create_element(ElementType.LABEL, "main_light_label", "Main Light")
	_create_element(ElementType.COLOR_PICKER, "light_color", "Light Color", main_light.light_color)
	_create_element(ElementType.INPUT, "light_energy", "Light Energy", main_light.light_energy, TYPE_REAL)
	_create_element(ElementType.INPUT, "light_indirect_energy", "Light Indirect Energy", main_light.light_indirect_energy, TYPE_REAL)
	_create_element(ElementType.INPUT, "light_specular", "Light Specular", main_light.light_specular, TYPE_REAL)

	# Environment values
	

func _apply_properties() -> void:
	for c in v_box_container.get_children():
		var value = c.get_value()
		match c.name:
			"light_color":
				main_light.light_color = value
			"light_energy":
				main_light.light_energy = value
			"light_indirect_energy":
				main_light.light_indirect_energy = value
			"light_specular":
				main_light.light_specular = value

func _setup() -> void:
	current_model = main_screen.model_display_screen.model
	main_light = main_screen.light_container.get_child(0)

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


