class_name LandingScreen
extends CanvasLayer

onready var runners: VBoxContainer = $RootControl/TabContainer/Runners/ScrollContainer/RunnersList

###############################################################################
# Builtin functions                                                           #
###############################################################################

func _ready() -> void:
	while not AM.is_manager_ready("em"):
		yield(get_tree(), "idle_frame")
	
	$RootControl/TabContainer/Runners/ScrollContainer/RunnersList/DefaultViewer.connect(
		"pressed",
		self,
		"_on_runner_button_pressed",
		[GlobalConstants.DEFAULT_RUNNER_PATH]
	)
	
	for i in AM.em.query_extensions_for_type("runner"):
		var button := Button.new()
		button.name = i.resource_name
		button.text = i.resource_name
		button.connect("pressed", self, "_on_runner_button_pressed", [i.resource_entrypoint])
		
		runners.add_child(button)

###############################################################################
# Connections                                                                 #
###############################################################################

func _on_runner_button_pressed(entrypoint_path: String) -> void:
	_run_runner(entrypoint_path)

###############################################################################
# Private functions                                                           #
###############################################################################

func _run_runner(path: String) -> void:
	var runner = load(path)
	if runner is PackedScene:
		runner = runner.instance()
	else:
		runner = runner.new()
	
	get_tree().root.add_child(runner)
	get_tree().current_scene = runner
	get_tree().root.remove_child(self)
	queue_free()

###############################################################################
# Public functions                                                            #
###############################################################################
