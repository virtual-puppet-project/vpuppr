extends Control

var controller
var receiver

func setup_controller(element: Control) -> void:
	controller = element

	var parent = controller.parent

	controller.clear_details()

	if not AppManager.sb.is_connected("custom_prop_toggle_created", self, "_on_custom_prop_toggle_created"):
		AppManager.sb.connect("custom_prop_toggle_created", self, "_on_custom_prop_toggle_created")
	
	for prop_name in AppManager.cm.current_model_config.instanced_props.keys():
		var prop_data: Reference = load("res://screens/gui/PropData.gd").new()
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

		prop_data.toggle.prop_name = prop_data.prop_name
		
		AppManager.main.model_display_screen.props.call_deferred("add_child", prop_data.prop)
		controller.vbox.call_deferred("add_child", prop_data.toggle)
		parent.props[prop_name] = prop_data

func setup_receiver(element: Control) -> void:
	receiver = element

	if not AppManager.sb.is_connected("prop_toggled", self, "_load_prop_information"):
		AppManager.sb.connect("prop_toggled", self, "_load_prop_information")
	if not AppManager.sb.is_connected("delete_prop", receiver, "_cleanup"):
		AppManager.sb.connect("delete_prop", receiver, "_cleanup")

func _on_custom_prop_toggle_created(value: BaseElement) -> void:
	controller.vbox.call_deferred("add_child", value)

func _load_prop_information(prop_name: String, is_visible: bool) -> void:
	receiver.clear_details()

	var parent = receiver.parent
	
	if not is_visible:
		return

	yield(get_tree(), "idle_frame")

	if parent.props.has(prop_name):
		var data: Reference = parent.props[prop_name]
		_generate_prop_manipulation_elements(data.prop_name)
	elif prop_name == "Main Light":
		yield(_generate_builtin_prop_elements("main_light"), "completed")
	elif prop_name == "Environment":
		yield(_generate_builtin_prop_elements("world_environment"), "completed")
	else:
		AppManager.log_message("Unhandled prop_name: %s" % prop_name, true)

func _generate_prop_manipulation_elements(prop_name: String) -> void:
	var parent = receiver.parent

	var name_elem: BaseElement = parent.generate_ui_element(parent.XmlConstants.LABEL, {
		"name": prop_name
	})
	receiver.vbox.call_deferred("add_child", name_elem)

	var move_elem: BaseElement = parent.generate_ui_element(parent.XmlConstants.TOGGLE, {
		"name": "Move",
		"event": "move_prop"
	})
	receiver.vbox.call_deferred("add_child", move_elem)

	var rotate_elem: BaseElement = parent.generate_ui_element(parent.XmlConstants.TOGGLE, {
		"name": "Rotate",
		"event": "rotate_prop"
	})
	receiver.vbox.call_deferred("add_child", rotate_elem)

	var zoom_elem: BaseElement = parent.generate_ui_element(parent.XmlConstants.TOGGLE, {
		"name": "Zoom",
		"event": "zoom_prop"
	})
	receiver.vbox.call_deferred("add_child", zoom_elem)

	var delete_elem: BaseElement = parent.generate_ui_element(parent.XmlConstants.BUTTON, {
		"name": "Delete Prop",
		"event": "delete_prop"
	})
	receiver.vbox.call_deferred("add_child", delete_elem)

func _generate_builtin_prop_elements(builtin_name: String) -> void:
	var parent = receiver.parent
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
				AppManager.log_message("Unhandled type: %d" % builtin_type, true)

		var elem: BaseElement = parent.generate_ui_element(xml_type, {
			"name": key,
			"event": builtin_name,
			"type": data_type
		})

		receiver.vbox.call_deferred("add_child", elem)

		yield(elem, "ready")

		elem.set_value(AppManager.cm.current_model_config.get(builtin_name)[key])
