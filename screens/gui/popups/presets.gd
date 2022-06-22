extends BaseTreeLayout

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
	
	return Result.ok()

#-----------------------------------------------------------------------------#
# Connections                                                                 #
#-----------------------------------------------------------------------------#

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
	var page := _create_page(page_name, config_string)

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
