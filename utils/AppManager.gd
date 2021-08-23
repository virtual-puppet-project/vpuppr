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

# TODO currently unused
# onready var tm: TranslationManager = TranslationManager.new()
onready var cm: Reference = load("res://utils/ConfigManager.gd").new()
onready var sb: Reference = load("res://utils/SignalBroadcaster.gd").new()

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

var main: MainScreen

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

	cm.load_config(file_path)

	emit_signal("file_to_load_changed", file_path)

func set_model_default() -> void:
	cm.metadata_config.default_model_to_load_path = current_model_path
	cm.save_config()
	emit_signal("default_model_set")

func is_current_model_default() -> bool:
	var result: bool = false
	if current_model_path == cm.metadata_config.default_model_to_load_path:
		result = true
	return result

func model_is_loaded() -> void:
	emit_signal("model_loaded")

func change_preset(preset: String) -> void:
	emit_signal(preset)

func log_message(message: String, is_error: bool = false) -> void:
	if is_error:
		message = "[ERROR] %s" % message
		assert(false, message)
	print(message)
	emit_signal("console_log", message)
