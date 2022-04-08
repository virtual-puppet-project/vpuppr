class_name LandingScreen
extends CanvasLayer

onready var runners: VBoxContainer = $RootControl/TabContainer/Runners/ScrollContainer/RunnersList

###############################################################################
# Builtin functions                                                           #
###############################################################################

func _ready() -> void:
	while not AM.is_manager_ready("em"):
		yield(get_tree(), "idle_frame")
	
	var default_runner_button := Button.new()
	default_runner_button.name = "DefaultRunner"
	default_runner_button.text = "Default Runner"
	default_runner_button.connect(
		"pressed",
		self,
		"_on_runner_button_pressed",
		[GlobalConstants.DEFAULT_RUNNER_PATH, true]
	)
	
	runners.add_child(default_runner_button)
	
	for i in AM.em.query_extensions_for_type(GlobalConstants.ExtensionTypes.RUNNER):
		var button := Button.new()
		button.name = i.resource_name
		button.text = i.resource_name
		button.connect("pressed", self, "_on_runner_button_pressed", [
			i.resource_entrypoint, i.other.get(GlobalConstants.SELECTABLE_GUI, false)
		])
		
		runners.add_child(button)

###############################################################################
# Connections                                                                 #
###############################################################################

func _on_runner_button_pressed(entrypoint_path: String, use_selectable_gui: bool) -> void:
	if not use_selectable_gui:
		_run_runner(entrypoint_path, load(GlobalConstants.DEFAULT_GUI_PATH).instance())
	else:
		_gui_selection_popup(entrypoint_path)

func _on_gui_selected(scene: Node, path: String) -> void:
	_run_runner(path, scene)

###############################################################################
# Private functions                                                           #
###############################################################################

func _run_runner(path: String, gui: Node) -> void:
	var runner = load(path)
	if runner is PackedScene:
		runner = runner.instance()
	else:
		runner = runner.new()

	runner.add_child(gui)
	
	get_tree().root.add_child(runner)
	get_tree().current_scene = runner
	get_tree().root.remove_child(self)
	queue_free()

func _gui_selection_popup(original_entrypoint_path: String) -> void:
	var popup = preload("res://screens/gui_selector.tscn").instance()
	popup.connect("selected", self, "_on_gui_selected", [original_entrypoint_path])
	
	add_child(popup)
	popup.popup_centered_ratio()

###############################################################################
# Public functions                                                            #
###############################################################################
