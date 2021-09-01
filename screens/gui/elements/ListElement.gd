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

# Features

func _on_custom_prop_toggle_created(value: BaseElement) -> void:
	vbox.call_deferred("add_child", value)

func _load_prop_information(prop_name: String, is_visible: bool) -> void:
	for c in vbox.get_children():
		c.queue_free()
	
	if not is_visible:
		return

	yield(get_tree(), "idle_frame")

	if parent.PROPS.has(prop_name):
		var data: Reference = parent.PROPS[prop_name]
		_generate_prop_manipulation_elements(data.prop_name)
	elif prop_name == "Main Light":
		# _generate_prop_manipulation_elements(prop_name)
		yield(_generate_builtin_prop_elements("main_light"), "completed")
	elif prop_name == "Environment":
		yield(_generate_builtin_prop_elements("world_environment"), "completed")
	else:
		AppManager.log_message("Unhandled prop_name: %s" % prop_name, true)

# Presets

func _load_preset_information(preset_name: String, is_visible: bool) -> void:
	for c in vbox.get_children():
		c.queue_free()

	if not is_visible:
		return

	yield(get_tree(), "idle_frame")

###############################################################################
# Private functions                                                           #
###############################################################################

func _generate_prop_manipulation_elements(prop_name: String) -> void:
	var name_elem: BaseElement = parent.generate_ui_element(parent.XmlConstants.LABEL, {
		"name": prop_name
	})
	vbox.call_deferred("add_child", name_elem)

	var move_elem: BaseElement = parent.generate_ui_element(parent.XmlConstants.TOGGLE, {
		"name": "Move",
		"event": "move_prop"
	})
	vbox.call_deferred("add_child", move_elem)

	var rotate_elem: BaseElement = parent.generate_ui_element(parent.XmlConstants.TOGGLE, {
		"name": "Rotate",
		"event": "rotate_prop"
	})
	vbox.call_deferred("add_child", rotate_elem)

	var zoom_elem: BaseElement = parent.generate_ui_element(parent.XmlConstants.TOGGLE, {
		"name": "Zoom",
		"event": "zoom_prop"
	})
	vbox.call_deferred("add_child", zoom_elem)

func _generate_builtin_prop_elements(builtin_name: String) -> void:
	for key in AppManager.cm.current_model_config.get(builtin_name).keys():
		var builtin_type = typeof(AppManager.cm.current_model_config.get(builtin_name)[key])
		var xml_type: String
		var data_type: String = ""
		match builtin_type:
			TYPE_REAL:
				xml_type = parent.XmlConstants.PROP_INPUT
				data_type = "float"
			TYPE_COLOR:
				xml_type = parent.XmlConstants.PROP_COLOR_PICKER
			TYPE_BOOL:
				xml_type = parent.XmlConstants.PROP_TOGGLE
			TYPE_STRING:
				xml_type = parent.XmlConstants.PROP_INPUT
				data_type = "string"
			_:
				AppManager.log_mesasge("Unhandled type: %d" % builtin_type, true)

		var elem: BaseElement = parent.generate_ui_element(xml_type, {
			"name": key,
			"event": builtin_name,
			"type": data_type
		})

		vbox.call_deferred("add_child", elem)

		yield(elem, "ready")

		# TODO temporary fix?
		if xml_type == parent.XmlConstants.PROP_TOGGLE:
			elem.toggle.disconnect("toggled", elem, "_on_toggled")
		elem.set_value(AppManager.cm.current_model_config.get(builtin_name)[key])
		if xml_type == parent.XmlConstants.PROP_TOGGLE:
			elem.toggle.connect("toggled", elem, "_on_toggled")

###############################################################################
# Public functions                                                            #
###############################################################################

func get_value():
	return vbox.get_children()

func set_value(_value) -> void:
	AppManager.log_message("Tried to set value on a List element", true)

# Override base setup() function
func setup() -> void:
	if not data_bind:
		return
	match data_bind:
		"mapped_bones":
			for bone_i in parent.model.skeleton.get_bone_count():
				var bone_name: String = parent.model.skeleton.get_bone_name(bone_i)
				var elem: BaseElement = parent.generate_ui_element(
					parent.XmlConstants.DOUBLE_TOGGLE,
					{
						"name": bone_name,
						"event": "bone_toggled"
					}
				)
				elem.toggle1_label = parent.DoubleToggleConstants.TRACK
				if bone_name in AppManager.cm.current_model_config.mapped_bones:
					elem.toggle1_value = true

				elem.toggle2_label = parent.DoubleToggleConstants.POSE
				
				vbox.call_deferred("add_child", elem)
		"instanced_props":
			if not AppManager.sb.is_connected("custom_prop_toggle_created", self, "_on_custom_prop_toggle_created"):
				AppManager.sb.connect("custom_prop_toggle_created", self, "_on_custom_prop_toggle_created")
			
			for prop_name in AppManager.cm.current_model_config.instanced_props.keys():
				var prop_data: Reference = PropData.new()
				prop_data.load_from_dict(
					AppManager.cm.current_model_config.instanced_props[prop_name]
				)

				prop_data.prop = parent.create_prop(
					prop_data.prop_path,
					prop_data.parent_transform,
					prop_data.child_transform
				)

				prop_data.toggle = parent.generate_ui_element(
					parent.XmlConstants.PROP_TOGGLE,
					{
						"name": prop_data.prop_name,
						"event": "prop_toggled"
					}
				)
				
				AppManager.sb.connect("prop_toggled", prop_data.toggle, "_on_prop_toggled")
				
				AppManager.main.model_display_screen.call_deferred("add_child", prop_data.prop)
				vbox.call_deferred("add_child", prop_data.toggle)
				parent.PROPS[prop_name] = prop_data
		"config_data":
			for preset_name in AppManager.cm.metadata_config.config_data.keys():
				var config = AppManager.cm.load_config(AppManager.cm.metadata_config.data[preset_name])

				var preset_data: Reference = PresetData.instance()

				preset_data.config_name = config.config_name
				preset_data.description = config.description
				preset_data.hotkey = config.hotkey
				preset_data.notes = config.notes
				preset_data.is_default_for_model = config.is_default_for_model

				var preset_toggle = parent.generate_ui_element(
					parent.XmlConstants.PRESET_TOGGLE,
					{
						"name": preset_data.config_name,
						"event": "preset_toggled"
					}
				)

				# TODO finish adding toggles
		_:
			AppManager.log_message("Unhandled data bind: %s" % data_bind, true)
