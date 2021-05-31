class_name FeatureView
extends BaseView

const PROP_SELECTION_POPUP: Resource = preload("res://screens/gui/feature-view/PropSelectionPopup.tscn")
const BASE_PROP_SCRIPT_PATH: String = "res://entities/BaseProp.gd"

# Builtins
var main_light: Light
var world_environment: WorldEnvironment

# Props
var instanced_props: Dictionary = {} # String: PropData
var prop_to_move: Spatial

var is_left_clicking: bool = false
var should_move_prop: bool = false
var should_spin_prop: bool = false
var should_zoom_prop: bool = false

var mouse_move_strength: float = 0.002
var scroll_strength: float = 0.05

class PropData:
	var object: Node
	var data: Dictionary

	func _init(p_object: Node, p_data: Dictionary) -> void:
		object = p_object
		data = p_data

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
				prop_to_move.translate(
						Vector3(event.relative.x, -event.relative.y, 0.0) * mouse_move_strength)
			if should_spin_prop:
				prop_to_move.get_child(0).rotate_x(event.relative.y * mouse_move_strength)
				prop_to_move.get_child(0).rotate_y(event.relative.x * mouse_move_strength)
	if should_zoom_prop:
		if event.is_action("scroll_up"):
			prop_to_move.translate(Vector3(0.0, 0.0, scroll_strength))
		elif event.is_action("scroll_down"):
			prop_to_move.translate(Vector3(0.0, 0.0, -scroll_strength))

###############################################################################
# Connections                                                                 #
###############################################################################

func _on_apply_button_pressed() -> void:
	_apply_properties()

func _on_reset_button_pressed() -> void:
	_reset_properties()

func _on_gui_toggle_set(toggle_name: String) -> void:
	# Courtesy null check
	if instanced_props.has(toggle_name):
		_create_prop_info_display(toggle_name, instanced_props[toggle_name].data)
	else:
		AppManager.log_message("ToggleLabel %s not found in %s" % [toggle_name, self.name])

func _on_add_prop_button_pressed() -> void:
	var popup: BaseFilePopup = PROP_SELECTION_POPUP.instance()
	get_parent().add_child(popup)

	yield(popup, "file_selected")
	var prop_path = popup.file_to_load
	popup.queue_free()
	
	_create_prop(prop_path, Transform(), Transform())

func _on_delete_prop_button_pressed() -> void:
	var prop_name: String = right_container.inner.get_child(0).name
	instanced_props[prop_name].object.queue_free()
	instanced_props.erase(prop_name)
	for c in left_container.get_inner_children():
		if c.name == prop_name:
			c.queue_free()
			break
	yield(get_tree(), "idle_frame")
	right_container.clear_children()

###############################################################################
# Private functions                                                           #
###############################################################################

func _setup_left(config: Dictionary) -> void:
	if not AppManager.is_connected("gui_toggle_set", self, "_on_gui_toggle_set"):
		AppManager.connect("gui_toggle_set", self, "_on_gui_toggle_set")

	current_model = main_screen.model_display_screen.model
	main_light = main_screen.light_container.get_child(0)
	world_environment = main_screen.world_environment
	
	instanced_props.clear()

	if not config.empty():
		for key in config.keys():
			match key:
				"instanced_props":
					for p in config[key]:
						_create_prop(
							p["prop_path"],
							JSONUtil.dictionary_to_transform(p["parent_prop_transform"]),
							JSONUtil.dictionary_to_transform(p["child_prop_transform"])
						)
				main_light.name:
					var light_data: Dictionary = config[key]
					main_light.light_color = JSONUtil.dictionary_to_color(light_data["light_color"])
					main_light.light_energy = light_data["light_energy"]
					main_light.light_indirect_energy = light_data["light_indirect_energy"]
					main_light.light_specular = light_data["light_specular"]
					if light_data.has("shadow_enabled"):
						main_light.shadow_enabled = light_data["shadow_enabled"]
				world_environment.name:
					var env_data: Dictionary = config[key]
					world_environment.environment.ambient_light_color = JSONUtil.dictionary_to_color(env_data["ambient_light_color"])
					world_environment.environment.ambient_light_energy = env_data["ambient_light_energy"]
					world_environment.environment.ambient_light_sky_contribution = env_data["ambient_light_sky_contribution"]
	
	_generate_properties()

func _setup_right(_config: Dictionary) -> void:
	if not right_container.outer.get_node_or_null("prop_details"):
		right_container.add_to_outer(_create_element(ElementType.LABEL, "prop_details",
				"Prop Details"))

func _generate_properties(p_initial_properties: Dictionary = {}) -> void:
	left_container.clear_children()
	right_container.clear_children()
	
	left_container.add_to_inner(_create_element(ElementType.LABEL, "built_in_props",
			"Built-in Props"))

	# Main light
	left_container.add_to_inner(_create_element(ElementType.TOGGLE, main_light.name, "Main Light", false, true))

	# World environment
	left_container.add_to_inner(_create_element(ElementType.TOGGLE, world_environment.name, "Environment", false, true))

	instanced_props[main_light.name] = PropData.new(
		main_light,
		{
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
		}
	)

	instanced_props[world_environment.name] = PropData.new(
		world_environment,
		{
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
		}
	)

	# Custom props

	# Custom prop button
	left_container.add_to_inner(_create_element(ElementType.BUTTON, "custom_props",
		"Custom Props", "Add", {
			"object": self,
			"function_name": "_on_add_prop_button_pressed"
		}
	))
	for p in instanced_props.keys():
		if (p == main_light.name or p == world_environment.name):
			continue
		left_container.add_to_inner(_create_element(ElementType.TOGGLE, p, p, false, true))

func _create_prop(prop_path: String, parent_transform: Transform, 
		child_transform: Transform) -> void:
	var prop_parent: Spatial = Spatial.new()
	prop_parent.set_script(load(BASE_PROP_SCRIPT_PATH))

	var prop: Spatial
	match prop_path.get_extension():
		"tscn":
			prop = load(prop_path).instance()
		"glb":
			var gltf_loader: DynamicGLTFLoader = DynamicGLTFLoader.new()
			prop = gltf_loader.import_scene(prop_path, 1, 1)
			prop.name = prop_path.get_file().trim_suffix(prop_path.get_extension())
		"vrm":
			var import_vrm: ImportVRM = ImportVRM.new()
			prop = import_vrm.import_scene(prop_path, 1, 1000)
			prop.name = prop_path.get_file().trim_suffix(prop_path.get_extension())
		"png", "jpg", "jpeg":
			var texture: Texture = ImageTexture.new()
			var image: Image = Image.new()
			var error = image.load(prop_path)
			if error != OK:
				continue
			texture.create_from_image(image, 0)
			prop = Sprite3D.new()
			prop.texture = texture
			prop.name = prop_path.get_file().trim_suffix(prop_path.get_extension())
	if prop:
		prop_parent.name = prop.name
		prop_parent.add_child(prop)

		prop_parent.prop_path = prop_path
		prop_parent.transform = parent_transform
		prop.transform = child_transform

		main_screen.model_display_screen.add_child(prop_parent)

		# TODO add more ways to interact with custom props
		var prop_data: PropData = PropData.new(prop_parent, {})
		instanced_props[prop_parent.name] = prop_data
		left_container.add_to_inner(_create_element(ElementType.TOGGLE, prop_parent.name,
				prop_parent.name.capitalize(), false, true))
		
	else: # If the prop was not loaded properly, don't cause a memory leak
		prop_parent.free()

func _create_prop_info_display(prop_name: String, data: Dictionary) -> void:
	right_container.clear_children()
	
	right_container.add_to_inner(_create_element(ElementType.LABEL, prop_name, prop_name))

	right_container.add_to_inner(_create_element(ElementType.TOGGLE, "move_prop", "Move Prop", false, false))
	right_container.add_to_inner(_create_element(ElementType.TOGGLE, "spin_prop", "Spin Prop", false, false))
	right_container.add_to_inner(_create_element(ElementType.TOGGLE, "zoom_prop", "Zoom Prop", false, false))

	for key in data.keys():
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
		
		right_container.add_to_inner(_create_element(
			element_type,
			key,
			key.capitalize(),
			data[key]["value"],
			data[key]["type"]
		))
	
	right_container.add_to_inner(_create_element(ElementType.BUTTON, "delete_prop",
			"Delete Prop", "Send it", {
				"object": self,
				"function_name": "_on_delete_prop_button_pressed"
			}))

func _apply_properties() -> void:
	should_move_prop = false
	should_spin_prop = false
	should_zoom_prop = false
	for c in right_container.get_inner_children():
		if c is CenteredLabel:
			if instanced_props[c.get_value()].object is Spatial:
				prop_to_move = instanced_props[c.get_value()].object
		else:
			match c.name:
				"move_prop":
					if c.get_value():
						should_move_prop = true
				"spin_prop":
					if c.get_value():
						should_spin_prop = true
				"zoom_prop":
					if c.get_value():
						should_zoom_prop = true
				"delete_prop", "prop_details":
					pass
				_:
					prop_to_move.set(c.name, c.get_value())
				

func _reset_properties() -> void:
	pass

###############################################################################
# Public functions                                                            #
###############################################################################

func save() -> Dictionary:
	var result: Dictionary = {}

	result["instanced_props"] = []
	for i in instanced_props.keys():
		if i == main_light.name:
			var ml: Dictionary = {}
			ml["light_color"] = JSONUtil.color_to_dictionary(main_light.light_color)
			ml["light_energy"] = main_light.light_energy
			ml["light_indirect_energy"] = main_light.light_indirect_energy
			ml["light_specular"] = main_light.light_specular
			ml["shadow_enabled"] = main_light.shadow_enabled

			result[main_light.name] = ml
		elif i == world_environment.name:
			var we: Dictionary = {}
			we["ambient_light_color"] = JSONUtil.color_to_dictionary(world_environment.environment.ambient_light_color)
			we["ambient_light_energy"] = world_environment.environment.ambient_light_energy
			we["ambient_light_sky_contribution"] = world_environment.environment.ambient_light_sky_contribution

			result[world_environment.name] = we
		elif instanced_props[i].object.has_method("save"):
			result["instanced_props"].append(instanced_props[i].object.save())

	return result
