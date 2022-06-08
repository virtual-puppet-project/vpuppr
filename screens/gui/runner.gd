extends BaseTreeLayout

#-----------------------------------------------------------------------------#
# Builtin functions                                                           #
#-----------------------------------------------------------------------------#

func _init() -> void:
	pass

func _setup_logger() -> void:
	logger = Logger.new(self)

func _pre_setup() -> void:
	_initial_page = "Default Runner"
	var default_runner := _create_view({
		"name": _initial_page,
		"run_args": [
			GlobalConstants.DEFAULT_RUNNER_PATH
		]
	})

	add_child(default_runner)

	for ext in AM.em.query_extensions_for_type(GlobalConstants.ExtensionTypes.RUNNER):
		ext = ext as ExtensionResource
		var view := _create_view({
			"name": ext.resource_name,
			"run_args": [
				ext.resource_entrypoint
			]
		})

		add_child(view)

#-----------------------------------------------------------------------------#
# Connections                                                                 #
#-----------------------------------------------------------------------------#

func _on_run(path: String, toggle: CheckButton) -> void:
	if toggle.pressed:
		var popup := _create_gui_select(path)

		add_child(popup)
		popup.popup_centered_ratio()
	else:
		_run_runner(path, GlobalConstants.DEFAULT_GUI_PATH)

func _on_gui_selected(runner_path: String, gui_path: String) -> void:
	var file := File.new()
	if not file.file_exists(gui_path):
		logger.error("Gui doesn't exist at path %s" % gui_path)
		return
	
	_run_runner(runner_path, gui_path)

func _terminate(node: Node) -> void:
	node.queue_free()

#-----------------------------------------------------------------------------#
# Private functions                                                           #
#-----------------------------------------------------------------------------#

static func _h_fill_expand(control: Control) -> void:
	control.size_flags_horizontal = Control.SIZE_EXPAND_FILL

static func _v_fill_expand(control: Control) -> void:
	control.size_flags_vertical = Control.SIZE_EXPAND_FILL

func _create_view(data: Dictionary) -> ScrollContainer:
	var sc := ScrollContainer.new()
	_h_fill_expand(sc)
	sc.name = data.name.replace(" ", "")
	sc.scroll_horizontal_enabled = false

	var list := VBoxContainer.new()
	_h_fill_expand(list)
	_v_fill_expand(list)

	sc.add_child(list)

	var title := Label.new()
	_h_fill_expand(title)
	title.align = Label.ALIGN_CENTER
	title.text = data.name

	list.add_child(title)

	var preview := TextureRect.new()
	_h_fill_expand(preview)
	_v_fill_expand(preview)
	preview.expand = true
	preview.stretch_mode = TextureRect.STRETCH_KEEP_ASPECT
	preview.texture = load("res://assets/NoPreview.png")

	list.add_child(preview)

	var select_gui_toggle := CheckButton.new()
	select_gui_toggle.text = "Show GUI selector"
	select_gui_toggle.set_pressed_no_signal(true)

	list.add_child(select_gui_toggle)

	data.run_args.append(select_gui_toggle)

	var run_button := Button.new()
	run_button.text = "Run"
	
	run_button.connect("pressed", self, "_on_run", data.run_args)

	list.add_child(run_button)

	return sc

func _create_gui_select(runner_path: String) -> WindowDialog:
	var wd := WindowDialog.new()

	var pc := PanelContainer.new()
	_h_fill_expand(pc)
	_v_fill_expand(pc)
	pc.anchor_bottom = 1.0
	pc.anchor_right = 1.0

	wd.add_child(pc)

	var sc := ScrollContainer.new()
	
	pc.add_child(sc)

	var list := VBoxContainer.new()
	_h_fill_expand(list)
	_v_fill_expand(list)

	sc.add_child(list)

	for i in ["popup_hide", "hide"]:
		wd.connect(i, self, "_terminate", [wd])

	var default_gui := Button.new()
	default_gui.text = "Default Gui"
	default_gui.connect("pressed", self, "_on_gui_selected", [runner_path, GlobalConstants.DEFAULT_GUI_PATH])

	list.add_child(default_gui)

	for ext in AM.em.query_extensions_for_type(GlobalConstants.ExtensionTypes.GUI):
		# TODO this might not be a great solution
		if not ext.other.get(GlobalConstants.ExtensionOtherKeys.SELECTABLE_GUI, false):
			continue

		var button := Button.new()
		button.text = ext.resource_name.capitalize()
		button.connect("pressed", self, "_on_gui_selected", [ext.resource_entrypoint])

		list.add_child(button)

	return wd

func _run_runner(runner_path: String, gui_path: String) -> void:
	var file := File.new()
	if not file.file_exists(runner_path):
		logger.error("Runner does not exist at %s" % runner_path)
		return
	if not file.file_exists(gui_path):
		logger.error("Gui does not exist at %s" % gui_path)
		return

	var runner = load(runner_path)
	runner = runner.instance() if runner is PackedScene else runner.new()
	runner.name = runner_path.get_basename().get_file()

	var gui = load(gui_path)
	gui = gui.instance() if gui is PackedScene else gui.new()

	runner.add_child(gui)

	var root := get_tree().root
	var current_scene: Node = get_tree().current_scene

	root.add_child(runner)
	get_tree().current_scene = runner
	root.remove_child(current_scene)
	current_scene.queue_free()

#-----------------------------------------------------------------------------#
# Public functions                                                            #
#-----------------------------------------------------------------------------#
