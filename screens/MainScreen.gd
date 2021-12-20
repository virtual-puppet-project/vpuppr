class_name MainScreen
extends Spatial

const DEV_UI: Resource = preload("res://utils/gui/DevUI.tscn")

const MODEL_SCREEN: Resource = preload("res://screens/ModelDisplayScreen.tscn")

const LIP_SYNC = "res://addons/real-time-lip-sync-gd/lip_sync.gdns"

# var current_model_path: String = ""

onready var main_light: Spatial = $MainLight
onready var world_environment: WorldEnvironment = $WorldEnvironment

var model_display_screen: Spatial
onready var gui: CanvasLayer = $GuiHandler

var lip_sync: Reference

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
	
	AppManager.sb.connect("use_lip_sync", self, "_on_use_lip_sync")

	# TODO accommodate config manager changes, this is gross
	while not AppManager.cm.has_loaded_metadata:
		yield(get_tree(), "idle_frame")

	# Request model to load information
	AppManager.sb.set_file_to_load(AppManager.cm.metadata_config.default_model_to_load_path)

	AppManager.cm.metadata_config.apply_rendering_changes(get_viewport())
	
	lip_sync = load(LIP_SYNC).new()
	lip_sync.connect("lip_sync_panicked", self, "_on_lip_sync_panicked")
	
	AppManager.logger.notify("Welcome to openseeface-gd!")

func _process(delta):
	if AppManager.cm.metadata_config.use_lip_sync:
		lip_sync.update()
		print(lip_sync.result())

func _exit_tree():
	lip_sync.stop_thread()
	lip_sync.shutdown()

func _unhandled_input(event: InputEvent) -> void:
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

func _on_use_lip_sync(value: bool) -> void:
	if value:
		lip_sync.start_thread()
	else:
		lip_sync.stop_thread()
		lip_sync.shutdown()

func _on_lip_sync_panicked(message: String) -> void:
	AppManager.logger.error(message)
	lip_sync.stop_thread()
	lip_sync.shutdown()

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
	
	# Set initial values from config
	for key in AppManager.cm.current_model_config.main_light.keys():
		main_light.get_child(0).set(key, AppManager.cm.current_model_config.main_light[key])
	
	for key in AppManager.cm.current_model_config.world_environment.keys():
		world_environment.set(key, AppManager.cm.current_model_config.world_environment[key])

###############################################################################
# Public functions                                                            #
###############################################################################

func load_file(file_path: String) -> void:
	_clean_load_model_display_screen(file_path)
