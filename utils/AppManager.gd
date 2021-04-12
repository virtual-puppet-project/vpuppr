extends Node

signal file_to_load_changed(file_path)
#warning-ignore:unused_signal
signal model_loaded()
#warning-ignore:unused_signal
signal properties_applied()
#warning-ignore:unused_signal
signal properties_reset()
signal gui_toggle_set(toggle_name)
#warning-ignore:unused_signal
signal face_tracker_offsets_set()
#warning-ignore:unused_signal
signal console_log(message)

enum ModelType { GENERIC, VRM }

const DYNAMIC_PHYSICS_BONES: bool = false

const SAVE_FILE_NAME: String = "app-config.json"
const DEFAULT_SAVE_FILE: Dictionary = {
	"face_tracker_fps": 12,
	"models": {} # String: Dictionary
}

# Face tracker
var is_face_tracker_running: bool
var face_tracker_pid: int

# TODO disable OpenSeeGD during debug i guess
var is_face_tracking_disabled: bool = false

# Config file values
var save_directory_path: String
var app_config: Dictionary
var current_model_name: String

# Temporary VRM model data storage
var vrm_mappings: VRMMappings

###############################################################################
# Builtin functions                                                           #
###############################################################################

func _ready() -> void:
	self.connect("tree_exiting", self, "_on_tree_exiting")

	if not OS.is_debug_build():
		save_directory_path = OS.get_executable_path().get_base_dir()
	else:
		save_directory_path = "res://export/"

	app_config = load_config()

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

func gui_toggle_set(toggle_name: String) -> void:
	emit_signal("gui_toggle_set", toggle_name)

func set_file_to_load(file_path: String) -> void:
	current_model_name = file_path.get_file()
	if not app_config["models"].has(current_model_name):
		app_config["models"][current_model_name] = {}
	emit_signal("file_to_load_changed", file_path)

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

func update_config(key_name: String, data: Dictionary) -> void:
	"""
	data is a dictionary of values from a sidebar
	"""
	app_config["models"][current_model_name][key_name] = data
	# TODO currently saves the file twice since this is called by both sidebars
	# save_config()

func save_config() -> void:
	var file_path: String = "%s/%s" % [save_directory_path, SAVE_FILE_NAME]

	var save_file: File = File.new()
	save_file.open(file_path, File.WRITE)

	save_file.store_string(to_json(app_config))

	save_file.close()

func get_sidebar_config_safe(sidebar_name: String) -> Dictionary:
	var result: Dictionary = {}

	if app_config["models"][current_model_name].has(sidebar_name):
		result = app_config["models"][current_model_name][sidebar_name]

	return result

func log_message(message: String, is_error: bool = false) -> void:
	if is_error:
		message = "[ERROR] %s" % message
		assert(false, message)
	print(message)
	emit_signal("console_log", message)
