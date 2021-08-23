class_name MainScreen
extends Spatial

const DEV_UI: Resource = preload("res://utils/gui/DevUI.tscn")

const MODEL_SCREEN: Resource = preload("res://screens/ModelDisplayScreen.tscn")

var current_model_path: String = ""

onready var light_container: Spatial = $LightContainer
onready var world_environment: WorldEnvironment = $WorldEnvironment
var model_display_screen: Spatial

###############################################################################
# Builtin functions                                                           #
###############################################################################

func _ready() -> void:
	get_viewport().transparent_bg = true
	OS.window_per_pixel_transparency_enabled = true

	AppManager.main = self
	
	yield($GuiHandler, "setup_completed")
	
	# AppManager.connect("file_to_load_changed", self, "_on_file_to_load_changed")
	AppManager.sb.connect("file_to_load_changed", self, "_on_file_to_load_changed")

	# TODO remove this
	# AppManager.set_file_to_load(AppManager.get_default_model_path())

	# TODO accommodate config manager changes, this is gross
	while not AppManager.cm.has_loaded_metadata:
		yield(get_tree(), "idle_frame")

	# Request model to load information
	AppManager.sb.set_file_to_load(AppManager.cm.metadata_config.default_model_to_load_path)

func _input(event: InputEvent) -> void:
	if(event.is_action_pressed("ui_cancel") and OS.is_debug_build()):
		get_tree().quit()

###############################################################################
# Connections                                                                 #
###############################################################################

func _on_file_to_load_changed(file_path: String) -> void:
	current_model_path = file_path
	_clean_load_model_display_screen()

###############################################################################
# Private functions                                                           #
###############################################################################

func _clean_load_model_display_screen() -> void:
	if model_display_screen:
		# Prevent null pointers by pausing execution AND THEN freeing resources
		model_display_screen.pause_mode = PAUSE_MODE_STOP # TODO i dont think this does anything
		yield(get_tree(), "idle_frame")
		model_display_screen.free()
	model_display_screen = MODEL_SCREEN.instance()
	model_display_screen.model_resource_path = current_model_path
	add_child(model_display_screen)

###############################################################################
# Public functions                                                            #
###############################################################################


