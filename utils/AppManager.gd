extends Node

#warning-ignore:unused_signal
signal model_loaded() # Used by model scripts to indicate when they are ready
#warning-ignore:unused_signal
signal properties_applied()
#warning-ignore:unused_signal
signal properties_reset()
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
# var should_track_eye: float = 1.0

# Debounce
const DEBOUNCE_TIME: float = 5.0
var debounce_counter: float = 0.0
var should_save := false
var config_to_save: Reference

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

func _process(delta: float) -> void:
	if should_save:
		debounce_counter += delta
		if debounce_counter > DEBOUNCE_TIME:
			debounce_counter = 0.0
			should_save = false
			cm.save_config(config_to_save)

###############################################################################
# Connections                                                                 #
###############################################################################

func _on_tree_exiting() -> void:
	if OpenSeeGd.is_listening:
		OpenSeeGd.stop_receiver()
	
	log_message("Exiting. おやすみ。")

###############################################################################
# Private functions                                                           #
###############################################################################

###############################################################################
# Public functions                                                            #
###############################################################################

func save_facetracker_offsets() -> void:
	emit_signal("face_tracker_offsets_set")

func is_current_model_default() -> bool:
	var result: bool = false
	if current_model_path == cm.metadata_config.default_model_to_load_path:
		result = true
	return result

func save_config(p_config: Reference = null) -> void:
	"""
	Start saving config based off a debounce time
	
	If p_config is null, will save the current config in use
	"""
	should_save = true
	config_to_save = p_config

func save_config_instant(p_config: Reference = null) -> void:
	"""
	Immediately save config and stop debouncing if in progress
	
	If p_config is null, will save the current config in use
	"""
	should_save = false
	debounce_counter = 0.0
	cm.save_config(p_config)

func log_message(message: String, is_error: bool = false) -> void:
	if is_error:
		message = "[ERROR] %s" % message
		assert(false, message)
	print(message)
	emit_signal("console_log", message)
