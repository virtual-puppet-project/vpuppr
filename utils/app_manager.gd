class_name AppManager
extends Node

var logger: Logger

var env := Env.new()

var ps: PubSub
var lm: LogManager
var cm: ConfigManager
var em: ExtensionManager
var nm: NotificationManager
# Not girl, you weirdo
var grl = preload("res://addons/gdnative-runtime-loader/gdnative_runtime_loader.gd").new()

#region Debounce

const DEBOUNCE_TIME: float = 3.0
var debounce_counter: float = 0.0
var should_save := false

#endregion

var tracker: TrackingBackendInterface

###############################################################################
# Builtin functions                                                           #
###############################################################################

func _ready() -> void:
	OS.window_size = OS.get_screen_size() * 0.75
	OS.center_window()
	
	connect("tree_exiting", self, "_on_tree_exiting")
	
	if ClassDB.class_exists("Redirect"):
		Engine.get_singleton("Redirect").connect("print_line", self, "_on_stderr")

	ps = PubSub.new()
	# Must be initialized AFTER the PubSub since it needs to connect to other signals
	lm = LogManager.new()
	cm = ConfigManager.new()
	# Must be initialized AFTER ConfigManager because it needs to pull config data
	em = ExtensionManager.new()
	# Idk, this could really be anywhere
	nm = NotificationManager.new()

	# Initialized here since loggers must connect to the PubSub
	logger = Logger.new("AppManager")
	
	logger.info("Started. おはよう。")

func _process(delta: float) -> void:
	if should_save:
		debounce_counter += delta
		if debounce_counter > DEBOUNCE_TIME:
			save_config_instant()
	
	if Input.is_key_pressed(KEY_A):
		printerr("a")

###############################################################################
# Connections                                                                 #
###############################################################################

func _on_tree_exiting() -> void:
	# TODO this might need to be moved somewhere else
	if tracker != null:
		tracker.stop_receiver()

	if env.current_env != Env.Envs.TEST:
		save_config_instant()
	
	logger.info("Exiting. おやすみ。")

func _on_stderr(text: String, is_error: bool) -> void:
	if is_error:
		logger.error(text)

###############################################################################
# Private functions                                                           #
###############################################################################

###############################################################################
# Public functions                                                            #
###############################################################################

func save_config() -> void:
	should_save = true

func save_config_instant() -> void:
	should_save = false
	debounce_counter = 0.0
	cm.save_data()

func is_manager_ready(manager_name: String) -> bool:
	var m = get(manager_name)
	return m != null and m.is_setup
