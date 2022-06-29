extends BaseTreeLayout

const LISTEN_SIGNALS := [
	"config_name",
	"description",
	"hotkey",
	"notes",
	"is_default_for_model"
]

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

	var logger: Logger

	var path := ""

	var name_element: PageElement
	var description_element: PageElement
	var hotkey_element: PageElement
	var notes_element: PageElement
	var default_for_model_element: PageElement
	
	var load_button: Button
	var delete_button: Button

	func _init(page_name: String, config_string: String, p_logger: Logger) -> void:
		logger = p_logger

		var config := ModelConfig.new()
		var res: Result = config.parse_string(config_string)
		if Result.failed(res):
			logger.error(Result.to_log_string(res))
			return

		path = config.model_path

		ControlUtil.h_expand_fill(self)
		name = page_name

		var list := VBoxContainer.new()
		ControlUtil.all_expand_fill(list)

		add_child(list)

		#region Config values

		name_element = PageElement.new("Config name", config.config_name)
		list.add_child(name_element)

		description_element = PageElement.new("Description", config.description)
		list.add_child(description_element)

		hotkey_element = PageElement.new("Hotkey", config.hotkey)
		list.add_child(hotkey_element)

		notes_element = PageElement.new("Notes", config.notes, {
			"element_type": "TextEdit",
			"set_property": "text",
			"expand_vertically": true
		})
		list.add_child(notes_element)

		default_for_model_element = PageElement.new("Is default for model", config.is_default_for_model, {
			"element_type": "CheckButton",
			"set_property": "pressed"
		})
		list.add_child(default_for_model_element)

		#endregion
		
		var button_container := HBoxContainer.new()
		
		load_button = Button.new()
		ControlUtil.h_expand_fill(load_button)
		load_button.text = "Load"
		button_container.add_child(load_button)
		load_button.connect("pressed", self, "_on_button_pressed", [Actions.LOAD])
		
		delete_button = Button.new()
		ControlUtil.h_expand_fill(delete_button)
		delete_button.text = "Delete"
		button_container.add_child(delete_button)
		delete_button.connect("pressed", self, "_on_button_pressed", [Actions.DELETE])
		
		list.add_child(button_container)

	func _on_config_updated(payload: SignalPayload) -> void:
		if not payload is SignalPayload:
			logger.error("Unexpected callback value %s" % str(payload))
			return
		if payload.id != name:
			return

		match payload.signal_name:
			"config_name":
				pass
			"description":
				pass
			"hotkey":
				pass
			"notes":
				pass
			"is_default_for_model":
				pass

	func _on_button_pressed(action_type: int) -> void:
		match action_type:
			Actions.LOAD:
				AM.ps.publish(GlobalConstants.RELOAD_RUNNER, path)
			Actions.DELETE:
				var config_name = AM.cm.get_data("config_name")
				if config_name == name:
					logger.error("Config is currently in use")
					return
				
				var model_configs: Dictionary = AM.cm.get_data("model_configs")
				model_configs.erase(name)
				AM.ps.publish("model_configs", model_configs, name)
			_:
				logger.error("Unhandled action %s" % action_type)
				return

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
	var res: Result = _add_page(root, _initial_page, AM.cm.model_config.get_as_json_string(), true)
	if res.is_err():
		return Result.err(Error.Code.GUI_SETUP_ERROR, "Unable to create preset page for %s" % _initial_page)

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
	
	return Result.ok()

#-----------------------------------------------------------------------------#
# Connections                                                                 #
#-----------------------------------------------------------------------------#

func _on_new_preset_text_changed(text: String, button: Button) -> void:
	var model_configs: Dictionary = AM.cm.get_data("model_configs")

	var is_disabled := text.empty() or text in model_configs.keys()

	button.disabled = is_disabled

func _on_new_preset_button_pressed(line_edit: LineEdit) -> void:
	var new_model_config := AM.cm.model_config.duplicate(true)
	new_model_config.config_name = line_edit.text

	var res := AM.cm.save_data(new_model_config.config_name, new_model_config.get_as_json_string())
	if Result.failed(res):
		logger.error(Result.to_log_string(res))
		return

	var model_configs: Dictionary = AM.cm.get_data("model_configs")
	model_configs[line_edit.text] = res.unwrap()

	AM.ps.publish("model_configs", model_configs, new_model_config.config_name)

#-----------------------------------------------------------------------------#
# Private functions                                                           #
#-----------------------------------------------------------------------------#

static func _create_page(page_name: String, config_string: String) -> ScrollContainer:
	var config := ModelConfig.new()
	config.parse_string(config_string)

	var page := ScrollContainer.new()
	page.size_flags_horizontal = Control.SIZE_EXPAND_FILL
	page.name = page_name

	var list := VBoxContainer.new()
	list.size_flags_horizontal = Control.SIZE_EXPAND_FILL

	page.add_child(list)

	#region Config values

	var model_name_label := Label.new()
	model_name_label.text = page_name
	model_name_label.align = Label.ALIGN_CENTER

	list.add_child(model_name_label)

	list.add_child(_create_input_box("Config name", config.config_name))
	list.add_child(_create_input_box("Description", config.description))
	list.add_child(_create_input_box("Hotkey", config.hotkey))
	list.add_child(_create_input_box("Notes", config.notes))

	var default_for_model := HBoxContainer.new()
	
	var default_for_model_label := Label.new()
	default_for_model_label.size_flags_horizontal = Control.SIZE_EXPAND_FILL
	default_for_model_label.text = "Is default for model"

	default_for_model.add_child(default_for_model_label)

	var default_for_model_toggle := CheckButton.new()
	default_for_model_toggle.size_flags_horizontal = Control.SIZE_EXPAND_FILL
	default_for_model_toggle.set_pressed_no_signal(config.is_default_for_model)

	default_for_model.add_child(default_for_model_toggle)

	list.add_child(default_for_model)

	#endregion

	return page

static func _create_input_box(text: String, initial_value: String) -> HBoxContainer:
	var r := HBoxContainer.new()

	var label := Label.new()
	label.size_flags_horizontal = Control.SIZE_EXPAND_FILL
	label.text = text

	r.add_child(label)

	var line_edit := LineEdit.new()
	line_edit.size_flags_horizontal = Control.SIZE_EXPAND_FILL
	line_edit.text = str(initial_value)

	r.add_child(line_edit)

	return r

func _add_page(root: TreeItem, page_name: String, config_string: String, should_select: bool = false) -> Result:
	var page := PresetsPage.new(page_name, config_string, logger)

	add_child(page)

	pages[page_name] = page

	var ti := tree.create_item(root)
	ti.set_text(TREE_COLUMN, page_name)

	if should_select:
		ti.select(TREE_COLUMN)

	return Result.ok()

#-----------------------------------------------------------------------------#
# Public functions                                                            #
#-----------------------------------------------------------------------------#
