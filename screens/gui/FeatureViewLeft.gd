extends BaseSidebar

# Prop details are stored on the meta key and are sent to FeatureViewRight
const PROP_DETAILS_META_KEY: String = "prop_details"

const BASE_PROP_SCRIPT_PATH: String = "res://entities/BaseProp.gd"

var initial_properties: Dictionary

var feature_view_right: WeakRef

# Builtins
var main_light: Light
onready var world_environment: WorldEnvironment

var instanced_props: Dictionary = {}

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
		AppManager.log_message("ToggleLabel %s not found in %s" % [toggle_name, self.name])

func _on_add_prop_button_pressed() -> void:
	# TODO testing
	_create_prop("res://entities/local/hot-tub/HotTub.tscn", Transform(), Transform())

###############################################################################
# Private functions                                                           #
###############################################################################

func _generate_properties(p_initial_properties: Dictionary = Dictionary()) -> void:
	for child in v_box_container.get_children():
		child.free()

	# Built ins
	_create_element(ElementType.LABEL, "built_in_props", "Built-in Props")
	
	# Main light
	_create_custom_toggle(main_light.name, "Main Light", {
		"name": main_light.name,
		# Light
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
		},
		# Shadow
		"shadow_enabled": {
			"type": TYPE_BOOL,
			"value": main_light.shadow_enabled
		}
	})

	# World Environment
	_create_custom_toggle(world_environment.name, "World Environment", {
		"name": world_environment.name,
		# Ambient light
		"ambient_light_color": {
			"type": TYPE_COLOR,
			"value": world_environment.environment.ambient_light_color
		},
		"ambient_light_energy": {
			"type": TYPE_REAL,
			"value": world_environment.environment.ambient_light_energy
		},
		"ambient_light_contribution": {
			"type": TYPE_REAL,
			"value": world_environment.environment.ambient_light_sky_contribution
		}
	})

	instanced_props[main_light.name] = main_light
	instanced_props[world_environment.name] = world_environment.environment

	# Custom props
	# TODO extend to allow for all kinds of props
	_create_element(ElementType.BUTTON, "custom_props", "Custom Props", "Add", {
		"object": self,
		"function_name": "_on_add_prop_button_pressed"
	})
	for p in instanced_props.keys():
		if (p == main_light.name or p == world_environment.name):
			continue
		_create_custom_toggle(instanced_props[p].name, instanced_props[p].name.capitalize(), {
			"name": "%s" % instanced_props[p].name
		})

func _apply_properties() -> void:
	pass

func _setup() -> void:
	AppManager.connect("gui_toggle_set", self, "_on_gui_toggle_set")

	current_model = main_screen.model_display_screen.model
	main_light = main_screen.light_container.get_child(0)
	world_environment = main_screen.world_environment

	var loaded_config: Dictionary = AppManager.get_sidebar_config_safe(self.name)
	if not loaded_config.empty():
		for key in loaded_config.keys():
			match key:
				"instanced_props":
					for p in loaded_config[key]:
						_create_prop(
							p["prop_path"],
							JSONUtil.dictionary_to_transform(p["parent_prop_transform"]),
							JSONUtil.dictionary_to_transform(p["child_prop_transform"]),
							false
						)
				main_light.name: # TODO could potential break if there's a mismatch between save data and node name
					var light_dictionary: Dictionary = loaded_config[main_light.name]
					main_light.light_color = JSONUtil.dictionary_to_color(light_dictionary["light_color"])
					main_light.light_energy = light_dictionary["light_energy"]
					main_light.light_indirect_energy = light_dictionary["light_indirect_energy"]
					main_light.light_specular = light_dictionary["light_specular"]
					if light_dictionary.has("shadow_enabled"):
						main_light.shadow_enabled = light_dictionary["shadow_enabled"]
	
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

func _create_prop(prop_path: String, parent_transform: Transform, child_transform: Transform, should_create_toggle: bool = true) -> void:
	var prop_parent: Spatial = Spatial.new()
	prop_parent.set_script(load(BASE_PROP_SCRIPT_PATH))

	var prop: Spatial
	match prop_path.get_extension():
		"tscn":
			prop = load(prop_path).instance()
		"glb":
			AppManager.log_message("Loading in .glb props is not current supported @ %s" % self.name)

	if prop:
		prop_parent.name = prop.name
		prop_parent.add_child(prop)

		prop_parent.prop_path = prop_path
		prop_parent.transform = parent_transform
		prop.transform = child_transform

		main_screen.model_display_screen.add_child(prop_parent)
		instanced_props[prop_parent.name] = prop_parent

		if should_create_toggle:
			_create_custom_toggle(prop_parent.name, prop_parent.name.capitalize(), {
				"name": "%s" % prop_parent.name
			})
	else: # If the prop was not loaded properly, don't cause a memory leak
		prop_parent.free()

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
	if (data.empty() or not data.has("name")):
		return
	if instanced_props.has(data["name"]):
		# TODO this is gross
		if instanced_props[data["name"]] is Spatial:
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
		AppManager.log_message("%s doesn't exist in %s" % [data["name"], self.name])

func save() -> Dictionary:
	var result: Dictionary = {}

	result["instanced_props"] = []
	for p in instanced_props.keys():
		if p == main_light.name:
			var light_dictionary: Dictionary = {}
			light_dictionary["light_color"] = JSONUtil.color_to_dictionary(main_light.light_color)
			light_dictionary["light_energy"] = main_light.light_energy
			light_dictionary["light_indirect_energy"] = main_light.light_indirect_energy
			light_dictionary["light_specular"] = main_light.light_specular
			light_dictionary["shadow_enabled"] = main_light.shadow_enabled
			
			result[main_light.name] = light_dictionary
		elif instanced_props[p].has_method("save"):
			result["instanced_props"].append(instanced_props[p].save())

	return result
