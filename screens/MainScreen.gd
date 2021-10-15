class_name MainScreen
extends Spatial

const DEV_UI: Resource = preload("res://utils/gui/DevUI.tscn")

const MODEL_SCREEN: Resource = preload("res://screens/ModelDisplayScreen.tscn")

# var current_model_path: String = ""

onready var main_light: Spatial = $MainLight
onready var world_environment: WorldEnvironment = $WorldEnvironment

var model_display_screen: Spatial
onready var gui: CanvasLayer = $GuiHandler

###############################################################################
# Builtin functions                                                           #
###############################################################################

func _ready() -> void:
	get_viewport().transparent_bg = true
	OS.window_per_pixel_transparency_enabled = true

	AppManager.main = self
	
	yield($GuiHandler, "setup_completed")
	
	AppManager.sb.connect("file_to_load_changed", self, "_on_file_to_load_changed")

	AppManager.sb.connect("main_light", self, "_on_main_light")
	AppManager.sb.connect("world_environment", self, "_on_environment")

	# TODO accommodate config manager changes, this is gross
	while not AppManager.cm.has_loaded_metadata:
		yield(get_tree(), "idle_frame")

	# Request model to load information
	AppManager.sb.set_file_to_load(AppManager.cm.metadata_config.default_model_to_load_path)

	AppManager.cm.metadata_config.apply_rendering_changes(get_viewport())

func _input(event: InputEvent) -> void:
	if(event.is_action_pressed("ui_cancel") and OS.is_debug_build()):
		get_tree().quit()

###############################################################################
# Connections                                                                 #
###############################################################################

func _on_file_to_load_changed(file_path: String) -> void:
	AppManager.cm.load_config_and_set_as_current(file_path)
	
	_clean_load_model_display_screen(file_path)

func _on_main_light(prop_name: String, value) -> void:
	main_light.get_child(0).set(prop_name, value)

func _on_environment(prop_name: String, value) -> void:
	world_environment.environment.set(prop_name, value)

###############################################################################
# Private functions                                                           #
###############################################################################

func _clean_load_model_display_screen(path: String) -> void:
	if model_display_screen:
		# Prevent null pointers by pausing execution AND THEN freeing resources
		model_display_screen.pause_mode = PAUSE_MODE_STOP # TODO i dont think this does anything
		yield(get_tree(), "idle_frame")
		model_display_screen.free()
	model_display_screen = MODEL_SCREEN.instance()
	model_display_screen.model_resource_path = path
	add_child(model_display_screen)

###############################################################################
# Public functions                                                            #
###############################################################################

func load_file(file_path: String) -> void:
	_clean_load_model_display_screen(file_path)
