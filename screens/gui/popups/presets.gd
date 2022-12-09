extends BaseTreeLayout

class PresetsPage extends ScrollContainer:
	class PageElement extends HBoxContainer:
		var element: Control
		
		func _init(element_name: String, initial_value, data: Dictionary = {
			"element_type": "LineEdit",
			"set_property": "text",
			"expand_vertically": false
		}) -> void:
			ControlUtil.h_expand_fill(self)

			var label := Label.new()
			ControlUtil.h_expand_fill(label)
			label.text = element_name

			add_child(label)

			element = ClassDB.instance(data.element_type)
			ControlUtil.h_expand_fill(element)
			element.set(data.set_property, initial_value)
			if data.get("expand_vertically", false):
				ControlUtil.v_expand_fill(self)
				ControlUtil.v_expand_fill(element)

			add_child(element)

	enum Actions {
		NONE = 0,

		LOAD,
		DELETE
	}

	const LISTEN_VALUES := [
		"config_name",
		"description",
		"hotkey",
		"notes",
		"is_default_for_model"
	]

	var logger: Logger

	var model_config: ModelConfig

	var name_element: PageElement
	var description_element: PageElement
	var hotkey_element: PageElement
	var notes_element: PageElement
	var default_for_model_element: PageElement
	
	var load_button: Button
	var delete_button: Button
	
	var is_trying_to_save := false

	func _init(page_name: String, config_string: String, p_logger: Logger) -> void:
		logger = p_logger

		model_config = ModelConfig.new()
		var res: Result = Safely.wrap(model_config.from_string(config_string))
		if res.is_err():
			logger.error(res)
			return

		ControlUtil.h_expand_fill(self)
		name = page_name

		var list := VBoxContainer.new()
		ControlUtil.all_expand_fill(list)

		add_child(list)

		#region Config values

		name_element = PageElement.new(tr("DEFAULT_GUI_PRESETS_CONFIG_NAME_LABEL"), model_config.config_name)
		list.add_child(name_element)
		name_element.element.connect("text_entered", self, "_on_line_edit_text_entered", ["config_name"])
		name_element.element.connect("text_changed", self, "_on_line_edit_text_changed", ["config_name"])

		description_element = PageElement.new(tr("DEFAULT_GUI_PRESETS_DESCRIPTION_LABEL"), model_config.description)
		list.add_child(description_element)
		description_element.element.connect("text_entered", self, "_on_line_edit_text_entered", ["description"])
		description_element.element.connect("text_changed", self, "_on_line_edit_text_changed", ["description"])

		hotkey_element = PageElement.new(tr("DEFAULT_GUI_PRESETS_HOTKEY_LABEL"), model_config.hotkey)
		list.add_child(hotkey_element)
		hotkey_element.element.connect("text_entered", self, "_on_line_edit_text_entered", ["hotkey"])
		hotkey_element.element.connect("text_changed", self, "_on_line_edit_text_changed", ["hotkey"])

		notes_element = PageElement.new(tr("DEFAULT_GUI_PRESETS_NOTES_LABEL"), model_config.notes, {
			"element_type": "TextEdit",
			"set_property": "text",
			"expand_vertically": true
		})
		list.add_child(notes_element)
		notes_element.element.connect("text_changed", self, "_on_text_edit_text_changed", [notes_element.element, "notes"])

		default_for_model_element = PageElement.new(tr("DEFAULT_GUI_PRESETS_IS_DEFAULT_FOR_MODEL_LABEL"), model_config.is_default_for_model, {
			"element_type": "CheckButton",
			"set_property": "pressed"
		})
		list.add_child(default_for_model_element)
		default_for_model_element.element.connect("toggled", self, "_on_check_button_toggled", ["is_default_for_model"])

		#endregion
		
		var button_container := HBoxContainer.new()
		
		load_button = Button.new()
		ControlUtil.h_expand_fill(load_button)
		load_button.text = tr("DEFAULT_GUI_PRESETS_LOAD_BUTTON")
		button_container.add_child(load_button)
		load_button.connect("pressed", self, "_on_button_pressed", [Actions.LOAD])
		
		delete_button = Button.new()
		ControlUtil.h_expand_fill(delete_button)
		delete_button.text = tr("DEFAULT_GUI_PRESETS_DELETE_BUTTON")
		button_container.add_child(delete_button)
		delete_button.connect("pressed", self, "_on_button_pressed", [Actions.DELETE])
		
		list.add_child(button_container)

		for i in LISTEN_VALUES:
			AM.ps.subscribe(self, i, "_on_config_updated")

	func _on_line_edit_text_entered(text: String, signal_name: String) -> void:
		_on_line_edit_text_changed(text, signal_name)

	func _on_line_edit_text_changed(text: String, signal_name: String) -> void:
		if text.empty():
			return

		model_config.set_data(signal_name, text)
		_try_save()

	func _on_text_edit_text_changed(text_edit: TextEdit, signal_name: String) -> void:
		var text := text_edit.text
		if text.empty():
			return

		model_config.set_data(signal_name, text)
		_try_save()

	func _on_check_button_toggled(value: bool, signal_name: String) -> void:
		model_config.set_data(signal_name, value)
		_try_save()

	func _on_config_updated(payload: SignalPayload) -> void:
		if not payload is SignalPayload:
			return
		if payload.id != name:
			return

		match payload.signal_name:
			"config_name":
				name_element.element.text = payload.data
				name_element.element.caret_position = payload.data.length()
			"description":
				description_element.element.text = payload.data
				description_element.element.caret_position = payload.data.length()
			"hotkey":
				hotkey_element.element.text = payload.data
				hotkey_element.element.caret_position = payload.data.length()
			"notes":
				var te: TextEdit = notes_element.element
				var current_line: int = te.cursor_get_line()
				var current_col: int = te.cursor_get_column()
				te.text = payload.data
				te.cursor_set_line(current_line)
				te.cursor_set_column(current_col)
			"is_default_for_model":
				default_for_model_element.element.set_pressed_no_signal(payload.data)

	func _on_button_pressed(action_type: int) -> void:
		match action_type:
			Actions.LOAD:
				var configs: Dictionary = AM.cm.get_data("model_configs")
				AM.ps.publish(Globals.RELOAD_RUNNER, configs[model_config.config_name])
			Actions.DELETE:
				var config_name = AM.cm.get_data("config_name")
				if config_name == name:
					logger.error("Config is currently in use")
					return
				
				var model_configs: Dictionary = AM.cm.get_data("model_configs")
				FileUtil.remove_file_at_path(model_configs[name])

				AM.ps.publish("model_configs", null, name)
			_:
				logger.error("Unhandled action %s" % action_type)
				return

	func _try_save() -> void:
		if is_trying_to_save:
			return
		
		is_trying_to_save = true
		yield(get_tree().create_timer(0.2), "timeout")
		is_trying_to_save = false

		AM.cm.save_data(model_config.config_name, model_config.to_string())

#-----------------------------------------------------------------------------#
# Builtin functions                                                           #
#-----------------------------------------------------------------------------#

func _setup_logger() -> void:
	logger = Logger.new(self)

func _setup() -> Result:
	_set_tree($Left/Tree)
	tree.connect("item_selected", self, "_on_item_selected")

	tree.hide_root = true
	var root: TreeItem = tree.create_item()

	_initial_page = AM.cm.get_data("config_name")
	var res: Result = _add_page(root, _initial_page, AM.cm.model_config.to_string(), true)
	if res.is_err():
		return Safely.err(Error.Code.GUI_SETUP_ERROR, "Unable to create preset page for %s" % _initial_page)

	var model_configs: Dictionary = AM.cm.get_data("model_configs")
	for config_name in model_configs.keys():
		if config_name == _initial_page:
			continue

		var config_path: String = model_configs[config_name]
		var file := File.new()
		if file.open(config_path, File.READ) != OK:
			logger.error("Unable to read config at %s" % config_path)
			continue

		res = _add_page(root, config_name, file.get_as_text())
		if res.is_err():
			logger.error("Unable to create preset page for %s, skipping" % config_name)
			continue

	_toggle_page(_initial_page)

	var new_preset_line_edit: LineEdit = $Left/HBoxContainer/LineEdit
	var new_preset_button: Button = $Left/HBoxContainer/Save

	new_preset_line_edit.connect("text_changed", self, "_on_new_preset_text_changed", [
		new_preset_button
	])
	new_preset_button.connect("pressed", self, "_on_new_preset_button_pressed", [
		new_preset_line_edit
	])
	_on_new_preset_text_changed(new_preset_line_edit.text, new_preset_button)

	AM.ps.subscribe(self, "model_configs", "_on_event_published")
	
	return Safely.ok()

#-----------------------------------------------------------------------------#
# Connections                                                                 #
#-----------------------------------------------------------------------------#

func _on_event_published(payload: SignalPayload) -> void:
	match payload.signal_name:
		"model_configs":
			var changed_config_name: String = payload.id
			if changed_config_name in payload.data:
				var config_path: String = payload.get_changed()
				var file := File.new()
				if file.open(config_path, File.READ) != OK:
					logger.error("Unable to read config at %s" % config_path)
					return
				
				var res := Safely.wrap(_add_page(tree.get_root(), changed_config_name, file.get_as_text(), true))
				if res.is_err():
					logger.error(res)
					return
			else:
				var current_config_name: String = AM.cm.get_data("config_name")
				_toggle_page(current_config_name)

				pages[changed_config_name].delete()
				pages.erase(changed_config_name)

				pages[current_config_name].tree_item.select(TREE_COLUMN)

# TODO when adding a new preset, this does not appear to take into account the new preset
func _on_new_preset_text_changed(text: String, button: Button) -> void:
	var model_configs: Dictionary = AM.cm.get_data("model_configs")

	var is_disabled := text.empty() or text in model_configs.keys()

	button.disabled = is_disabled

func _on_new_preset_button_pressed(line_edit: LineEdit) -> void:
	var new_model_config := ModelConfig.new()
	new_model_config.parse_dict(AM.cm.model_config.to_dict())
	new_model_config.config_name = line_edit.text

	line_edit.text = ""

	var res := Safely.wrap(AM.cm.save_data(new_model_config.config_name, new_model_config.to_string()))
	if res.is_err():
		logger.error(res)
		return

	var model_configs: Dictionary = AM.cm.get_data("model_configs")
	model_configs[new_model_config.config_name] = res.unwrap()

	AM.ps.publish("model_configs", model_configs, new_model_config.config_name)

#-----------------------------------------------------------------------------#
# Private functions                                                           #
#-----------------------------------------------------------------------------#

func _add_page(root: TreeItem, page_name: String, config_string: String, should_select: bool = false) -> Result:
	var page := PresetsPage.new(page_name, config_string, logger)
	page.hide()

	add_child(page)

	var ti := tree.create_item(root)
	ti.set_text(TREE_COLUMN, page_name)

	pages[page_name] = Page.new(page, ti)

	if should_select:
		ti.select(TREE_COLUMN)

	return Safely.ok()

#-----------------------------------------------------------------------------#
# Public functions                                                            #
#-----------------------------------------------------------------------------#
