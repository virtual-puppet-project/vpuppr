extends Node

signal file_to_load_changed(file_path)
#warning-ignore:unused_signal
signal model_loaded() # Used by model scripts to indicate when they are ready
#warning-ignore:unused_signal
signal properties_applied()
#warning-ignore:unused_signal
signal properties_reset()
signal gui_toggle_set(toggle_name, view_name)
#warning-ignore:unused_signal
signal face_tracker_offsets_set()
#warning-ignore:unused_signal
signal console_log(message)
#warning-ignore:unused_signal
signal preset_changed(preset)
signal default_model_set()

enum ModelType { GENERIC, VRM }

const DEMO_MODEL_PATH: String = "res://entities/basic-models/Duck.tscn"

const DYNAMIC_PHYSICS_BONES: bool = false

const SAVE_FILE_NAME: String = "app-config.json"
const DEFAULT_SAVE_FILE: Dictionary = {
	"face_tracker_fps": 12,
	"models": {} # String: Dictionary
}

onready var tm: TranslationManager = TranslationManager.new()
onready var cm: Reference = load("res://utils/ConfigManager.gd").new()

# Face tracker
var is_face_tracker_running: bool
var face_tracker_pid: int

# TODO disable OpenSeeGD during debug i guess
var is_face_tracking_disabled: bool = false

# Config file values
var save_directory_path: String
var app_config: Dictionary
var current_model_name: String

# Temporary storage for model path
var current_model_path: String = "res://entities/basic-models/Duck.tscn"

# Temporary VRM model data storage
var vrm_mappings: VRMMappings

# AppSettings
var default_load_path: String = "/"
var should_track_eye: float = 1.0

###############################################################################
# Builtin functions                                                           #
###############################################################################

func _ready() -> void:
	self.connect("tree_exiting", self, "_on_tree_exiting")

	if not OS.is_debug_build():
		save_directory_path = OS.get_executable_path().get_base_dir()
	else:
		save_directory_path = "res://export"
		# Run unit tests
#		var goth = load("res://addons/goth/GOTH.gd").new()
#		goth.run_unit_tests()
		# goth.run_bdd_tests()

	cm.setup()

###############################################################################
# Connections                                                                 #
###############################################################################

func _on_tree_exiting() -> void:
	if is_face_tracker_running:
		OS.kill(face_tracker_pid)
	
	log_message("Exiting. おやすみ。")

###############################################################################
# Private functions                                                           #
###############################################################################

###############################################################################
# Public functions                                                            #
###############################################################################

func save_facetracker_offsets() -> void:
	emit_signal("face_tracker_offsets_set")

func apply_properties() -> void:
	emit_signal("properties_applied")

func reset_properties() -> void:
	emit_signal("properties_reset")

# TODO pose/feature/preset view all use this
# If a prop and a preset both share the same name, then they will both be toggled on
func gui_toggle_set(toggle_name: String, view_name: String) -> void:
	emit_signal("gui_toggle_set", toggle_name, view_name)

func set_file_to_load(file_path: String) -> void:
	current_model_name = file_path.get_file()
	# Grab the full model path to allow setting model as default
	current_model_path = file_path

	emit_signal("file_to_load_changed", file_path)

# TODO update this to use cm
func set_model_default() -> void:
	if not app_config.has("settings"):
		app_config["settings"] = {}
	#if "default_model" not in app_config:
	#	app_config["settings"]["default_model"] = {}
	app_config["settings"]["default_model"] = current_model_path
	# save_config()
	emit_signal("default_model_set")

# Load DEMO_MODEL by default, otherwise load the user's saved default_model
# setting
func get_default_model_path() -> String:
	var result: String = DEMO_MODEL_PATH
	if app_config.has("settings"):
		if app_config["settings"].has("default_model"):
			result = app_config["settings"]["default_model"]
	return result

func get_current_model_path() -> String:
	var result: String = ""
	if current_model_path:
		result = current_model_path
	return result

func is_current_model_default() -> bool:
	var result: bool = false
	if get_current_model_path() == get_default_model_path():
		result = true
	return result

func model_is_loaded() -> void:
	emit_signal("model_loaded")

func change_preset(preset: String) -> void:
	emit_signal(preset)

func load_config() -> Dictionary:
	log_message("Begin loading data")

	var result: Dictionary

	var file_path: String = "%s/%s" % [save_directory_path, SAVE_FILE_NAME]

	var dir: Directory = Directory.new()
	if dir.file_exists(file_path):
		var save_file: File = File.new()
		save_file.open(file_path, File.READ)
		
		var data: JSONParseResult = JSON.parse(save_file.get_as_text())
		if (data.error == OK and typeof(data.result) == TYPE_DICTIONARY):
			log_message("Config file found")
			result = data.result
		else:
			log_message("Corrupted config file found. Please delete %s located next to your executable." % SAVE_FILE_NAME, true)
			return {}
		
		save_file.close()
	else:
		log_message("No config file found, creating new config")
		result = DEFAULT_SAVE_FILE
	
	log_message("Finished loading data")
	
	return result

# func update_config(key_name: String, data: Dictionary) -> void:
# 	"""
# 	data is a dictionary of values from a sidebar
# 	"""
# 	app_config["models"][current_model_name][key_name] = data
	# TODO currently saves the file twice since this is called by both sidebars
	# save_config()

	# cm.save_config()

# func save_config() -> void:
	# var file_path: String = "%s/%s" % [save_directory_path, SAVE_FILE_NAME]

	# var save_file: File = File.new()
	# save_file.open(file_path, File.WRITE)

	# save_file.store_string(to_json(app_config))

	# save_file.close()

	# cm.save_config()

# func get_sidebar_config_safe(sidebar_name: String) -> Dictionary:
# 	var result: Dictionary = {}

# 	if app_config["models"][current_model_name].has(sidebar_name):
# 		result = app_config["models"][current_model_name][sidebar_name]

# 	return result

func log_message(message: String, is_error: bool = false) -> void:
	if is_error:
		message = "[ERROR] %s" % message
		assert(false, message)
	print(message)
	emit_signal("console_log", message)
