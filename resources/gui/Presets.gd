extends Control

var controller
var receiver

func setup_controller(element: Control) -> void:
    controller = element

    var parent = controller.parent

    controller.clear_details()
    
    if not AppManager.sb.is_connected("preset_toggle_created", self, "_on_preset_toggle_created"):
        AppManager.sb.connect("preset_toggle_created", self, "_on_preset_toggle_created")
    for preset_name in AppManager.cm.metadata_config.config_data.keys():
        var config = AppManager.cm.load_config_for_preset(AppManager.cm.metadata_config.config_data[preset_name])

        var preset_toggle = parent.generate_ui_element(
            parent.XmlConstants.PRESET_TOGGLE,
            {
                "name": config.config_name,
                "event": "preset_toggled"
            }
        )

        preset_toggle.preset_name = preset_name

        parent.presets[preset_name] = preset_toggle
        AppManager.sb.connect("preset_toggled", preset_toggle, "_on_preset_toggled")

        controller.vbox.call_deferred("add_child", preset_toggle)

func setup_receiver(element: Control) -> void:
    receiver = element

    if not AppManager.sb.is_connected("preset_toggled", self, "_load_preset_information"):
        AppManager.sb.connect("preset_toggled", self, "_load_preset_information")
    if not AppManager.sb.is_connected("delete_preset", receiver, "_cleanup"):
        AppManager.sb.connect("delete_preset", receiver, "_cleanup")

func _on_preset_toggle_created(value: BaseElement) -> void:
    controller.vbox.call_deferred("add_child", value)

func _load_preset_information(preset_name: String, is_visible: bool) -> void:
    receiver.clear_details()

    if not is_visible:
        return

    yield(get_tree(), "idle_frame")

    if AppManager.cm.metadata_config.config_data.has(preset_name):
        yield(_generate_preset_elements(), "completed")
    else:
        AppManager.log_message("Unhandled preset_name: %s" % preset_name, true)

func _generate_preset_elements() -> void:
    var parent = receiver.parent

    var config_name_elem: BaseElement = parent.generate_ui_element(parent.XmlConstants.INPUT, {
        "name": "Config name",
        "data": "config_name",
        "type": "string",
        "event": "config_name"
    })
    receiver.vbox.call_deferred("add_child", config_name_elem)
    yield(config_name_elem, "ready")
    config_name_elem.set_value(parent.current_edited_preset.config_name)

    var description_elem: BaseElement = parent.generate_ui_element(parent.XmlConstants.INPUT, {
        "name": "Description",
        "data": "description",
        "type": "string",
        "event": "description"
    })
    receiver.vbox.call_deferred("add_child", description_elem)
    yield(description_elem, "ready")
    description_elem.set_value(parent.current_edited_preset.description)

    var hotkey_elem: BaseElement = parent.generate_ui_element(parent.XmlConstants.INPUT, {
        "name": "Hotkey",
        "data": "hotkey",
        "type": "string",
        "event": "hotkey"
    })
    receiver.vbox.call_deferred("add_child", hotkey_elem)
    yield(hotkey_elem, "ready")
    hotkey_elem.set_value(parent.current_edited_preset.hotkey)

    var notes_elem: BaseElement = parent.generate_ui_element(parent.XmlConstants.INPUT, {
        "name": "Notes",
        "data": "notes",
        "type": "string",
        "event": "notes"
    })
    receiver.vbox.call_deferred("add_child", notes_elem)
    yield(notes_elem, "ready")
    notes_elem.set_value(parent.current_edited_preset.notes)

    var is_default_for_model_elem: BaseElement = parent.generate_ui_element(parent.XmlConstants.TOGGLE, {
        "name": "Is default for model",
        "data": "is_default_for_model",
        "event": "is_default_for_model"
    })
    receiver.vbox.call_deferred("add_child", is_default_for_model_elem)
    yield(is_default_for_model_elem, "ready")
    is_default_for_model_elem.set_value(parent.current_edited_preset.is_default_for_model)
    
    var load_elem: BaseElement = parent.generate_ui_element(parent.XmlConstants.BUTTON, {
        "name": "Load Preset",
        "event": "load_preset"
    })
    receiver.vbox.call_deferred("add_child", load_elem)

    var delete_elem: BaseElement = parent.generate_ui_element(parent.XmlConstants.BUTTON, {
        "name": "Delete Preset",
        "event": "delete_preset"
    })
    receiver.vbox.call_deferred("add_child", delete_elem)
