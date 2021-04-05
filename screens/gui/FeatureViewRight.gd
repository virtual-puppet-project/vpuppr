extends BaseSidebar

const TITLE_TEXT: String = "prop_details"
const ELEMENT_NAME_KEY: String = "element_name"

var initial_properties: Dictionary

var feature_view_left: WeakRef

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
	_create_element(ElementType.LABEL, "prop_details", "Prop Details")

func _apply_properties() -> void:
	var data: Dictionary = {}

	for c in v_box_container.get_children():
		if c.name == TITLE_TEXT:
			continue
		
		if c.name == ELEMENT_NAME_KEY:
			data["name"] = c.label_text.to_lower().replace(" ", "_") # TODO this is gross
		else:
			data[c.name] = c.get_value()

	feature_view_left.get_ref().apply_properties(data)

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

func receive_element_selected(data: Dictionary) -> void:
	for c in v_box_container.get_children():
		if c.name != TITLE_TEXT:
			c.free()

	_create_element(ElementType.LABEL, ELEMENT_NAME_KEY, data["name"].capitalize())

	_create_element(ElementType.TOGGLE, "move_prop", "Move Prop", false, false)
	_create_element(ElementType.TOGGLE, "spin_prop", "Spin Prop", false, false)
	_create_element(ElementType.TOGGLE, "zoom_prop", "Zoom Prop", false, false)
	
	for key in data.keys():
		if key == "name":
			continue
		var element_type: int
		match data[key]["type"]:
			TYPE_STRING:
				element_type = ElementType.INPUT
			TYPE_REAL:
				element_type = ElementType.INPUT
			TYPE_COLOR:
				element_type = ElementType.COLOR_PICKER
			TYPE_BOOL:
				element_type = ElementType.CHECK_BOX
		
		_create_element(
			element_type,
			key,
			key.capitalize(),
			data[key]["value"],
			data[key]["type"]
		)

func save() -> Dictionary:
	# Empty return since this view doesn't carry any data
	return {}
