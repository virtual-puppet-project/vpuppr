extends BaseSidebar

const PROP_DETAILS_META_KEY: String = "prop_details"

var initial_properties: Dictionary

var feature_view_right: WeakRef

var main_light: Light

var instanced_props: Dictionary = {

}

# Prop movement
var prop_to_move: Spatial
var is_left_clicking: bool = false
var should_move_prop: bool = false
var should_spin_prop: bool = false
var should_zoom_prop: bool = false

export var zoom_strength: float = 0.05
export var mouse_move_strength: float = 0.002

###############################################################################
# Builtin functions                                                           #
###############################################################################

func _ready() -> void:
	_setup()

func _unhandled_input(event: InputEvent) -> void:
	if event.is_action_pressed("left_click"):
		is_left_clicking = true
	elif event.is_action_released("left_click"):
		is_left_clicking = false
	
	if is_left_clicking:
		if event is InputEventMouseMotion:
			if should_move_prop:
				prop_to_move.translate(Vector3(event.relative.x, -event.relative.y, 0.0) * mouse_move_strength)
			if should_spin_prop:
				prop_to_move.get_child(0).rotate_x(event.relative.y * mouse_move_strength)
				prop_to_move.get_child(0).rotate_y(event.relative.x * mouse_move_strength)
	if should_zoom_prop:
		if event.is_action("scroll_up"):
			prop_to_move.translate(Vector3(0.0, 0.0, zoom_strength))
		elif event.is_action("scroll_down"):
			prop_to_move.translate(Vector3(0.0, 0.0, -zoom_strength))

###############################################################################
# Connections                                                                 #
###############################################################################

func _on_apply_button_pressed() -> void:
	# _apply_properties()
	pass

func _on_reset_button_pressed() -> void:
	_generate_properties(initial_properties)

func _on_gui_toggle_set(toggle_name: String) -> void:
	# Courtesy null check
	var toggle_label: ToggleLabel = v_box_container.get_node_or_null(toggle_name)
	if toggle_label:
		if toggle_label.toggle_button.pressed:
			feature_view_right.get_ref().receive_element_selected(toggle_label.get_meta(PROP_DETAILS_META_KEY))
	else:
		AppManager.push_log("ToggleLabel %s not found in %s" % [toggle_name, self.name])

func _on_add_prop_button_pressed() -> void:
	# TODO testing
	var test_prop = load("res://entities/VisualizationRectangle.tscn").instance()
	main_screen.model_display_screen.add_child(test_prop)

	var prop_parent: Spatial = Spatial.new()
	# After the prop gets added, the SceneTree should automatically change the name if there is a name collision
	prop_parent.name = test_prop.name
	main_screen.model_display_screen.add_child(prop_parent)
	main_screen.model_display_screen.remove_child(test_prop)
	prop_parent.add_child(test_prop)

	instanced_props[prop_parent.name.capitalize().to_lower().replace(" ", "_")] = prop_parent

	_create_custom_toggle(prop_parent.name, prop_parent.name.capitalize(), {
		"name": "%s" % prop_parent.name
	})

###############################################################################
# Private functions                                                           #
###############################################################################

func _generate_properties(p_initial_properties: Dictionary = Dictionary()) -> void:
	for child in v_box_container.get_children():
		child.free()

	# Built ins
	_create_element(ElementType.LABEL, "built_in_props", "Built-in Props")
	
	# Main light
	_create_custom_toggle("main_light", "Main Light", {
		"name": "main_light",
		"light_color": {
			"type": TYPE_COLOR,
			"value": main_light.light_color
		},
		"light_energy": {
			"type": TYPE_REAL,
			"value": main_light.light_energy
		},
		"light_indirect_energy": {
			"type": TYPE_REAL,
			"value": main_light.light_indirect_energy
		},
		"light_specular": {
			"type": TYPE_REAL,
			"value": main_light.light_specular
		}
	})

	# Environment values
	# TODO add env stuff?

	# Custom props
	_create_element(ElementType.BUTTON, "custom_props", "Custom Props", "Add", {
		"object": self,
		"function_name": "_on_add_prop_button_pressed"
	})

func _apply_properties() -> void:
	pass

func _setup() -> void:
	AppManager.connect("gui_toggle_set", self, "_on_gui_toggle_set")

	current_model = main_screen.model_display_screen.model
	main_light = main_screen.light_container.get_child(0)

	instanced_props["main_light"] = main_light

	_generate_properties()

	# Store initial properties
	for child in v_box_container.get_children():
		if child.get("check_box"):
			initial_properties[child.name] = child.check_box.pressed
		elif child.get("line_edit"):
			initial_properties[child.name] = child.line_edit.text

# TODO setting data on the meta property doesn't seem like a good idea
func _create_custom_toggle(element_name: String, display_name: String, data: Dictionary) -> void:
	"""
	Assigns data to the node's meta
	
	data is in the format:
	{
		"name": string, <-- must correspond to the actual node name
		"property_name": {
			"type": int, <-- uses builtin type enums
			"value": some_value
		},
		...
	}
	"""
	var toggle_label: ToggleLabel = TOGGLE_LABEL.instance()
	toggle_label.name = element_name
	toggle_label.label_text = display_name

	toggle_label.set_meta(PROP_DETAILS_META_KEY, data)

	v_box_container.add_child(toggle_label)

###############################################################################
# Public functions                                                            #
###############################################################################

func apply_properties(data: Dictionary) -> void:
	"""
	data is in format:
	{
		"name": node_name,
		"node_property": node_value
	}
	"""
	if instanced_props.has(data["name"]):
		# TODO this is gross
		prop_to_move = instanced_props[data["name"]]
		if data["move_prop"]:
			should_move_prop = true
		else:
			should_move_prop = false
		if data["spin_prop"]:
			should_spin_prop = true
		else:
			should_spin_prop = false
		if data["zoom_prop"]:
			should_zoom_prop = true
		else:
			should_zoom_prop = false

		for key in data.keys():
			if key != "name":
				instanced_props[data["name"]].set(key, data[key])
	else:
		AppManager.push_log("%s doesn't exist in %s" % [data["name"], self.name])
