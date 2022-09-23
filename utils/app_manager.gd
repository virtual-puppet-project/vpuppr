class_name AppManager
extends Node

signal debounced()

var logger: Logger

var env := Env.new()

var ps: PubSub
var lm: LogManager
var cm: ConfigManager
var em: ExtensionManager
var tm: TranslationManager
var nm: NotificationManager
var tcm: TempCacheManager
# Not girl, you weirdo
var grl = preload("res://addons/gdnative-runtime-loader/gdnative_runtime_loader.gd").new()

#region Debounce

const DEBOUNCE_TIME: float = 3.0
var debounce_counter: float = 0.0
var should_save := false

#endregion

var app_args := {}

#-----------------------------------------------------------------------------#
# Builtin functions                                                           #
#-----------------------------------------------------------------------------#

func _init() -> void:
	Safely.register_error_codes(Error.Code)

func _ready() -> void:
	var startup_data = preload("res://utils/startup_args.gd").new().data
	for key in startup_data.keys():
		if app_args.has(key):
			continue
		app_args[key] = startup_data[key]

	ps = PubSub.new()
	# Must be initialized AFTER the PubSub since it needs to connect to other signals
	lm = LogManager.new()
	cm = ConfigManager.new()
	# Must be initialized AFTER ConfigManager because it needs to pull config data
	em = ExtensionManager.new()
	# Must be initialized AFTER ExtensionManager because it can load translation files for extensions
	tm = TranslationManager.new()
	# Idk, this could really be anywhere
	nm = NotificationManager.new()
	tcm = TempCacheManager.new()

	connect("tree_exiting", self, "_on_tree_exiting")
	
	logger = Logger.new("AppManager")
	
	if ClassDB.class_exists("StdoutStderrIntercept"):
		Engine.get_singleton("StdoutStderrIntercept").connect("intercepted_message", self, "_on_stderr")

	logger.info("Started. おはよう。")

func _process(delta: float) -> void:
	if should_save:
		debounce_counter += delta
		if debounce_counter > DEBOUNCE_TIME:
			save_config_instant()
			emit_signal("debounced")

#-----------------------------------------------------------------------------#
# Connections                                                                 #
#-----------------------------------------------------------------------------#

func _on_tree_exiting() -> void:
	if env.current_env != Env.Envs.TEST:
		save_config_instant()
	
	logger.info("Exiting. おやすみ。")

func _on_stderr(text: String, is_error: bool) -> void:
	if is_error:
		# TODO Sometimes there's a race condition that causes the logger to not
		# be initialized somehow?
		if logger == null:
			return
		logger.error(text)

#-----------------------------------------------------------------------------#
# Private functions                                                           #
#-----------------------------------------------------------------------------#

#-----------------------------------------------------------------------------#
# Public functions                                                            #
#-----------------------------------------------------------------------------#

## Initiates saving the config on a given debounce time
func save_config() -> void:
	should_save = true

## Initiates saving the config immediately, ignoring the debounce time
func save_config_instant() -> void:
	should_save = false
	debounce_counter = 0.0
	var result := cm.save_data()
	if result.is_err():
		logger.error("Failed to save config:\n%s" % result.to_string())

## Utility function for checking if a singleton that is managed by the AppManager is ready
func is_manager_ready(manager_name: String) -> bool:
	var m = get(manager_name)
	return m != null and m.is_setup

static func inject_env_vars(text: String) -> String:
	text = text.replace("$EXE_DIR", OS.get_executable_path().get_base_dir())
	
	return text \
		.replace("$EXE_DIR", OS.get_executable_path().get_base_dir()) \
		.replace("$PROJECT", ProjectSettings.globalize_path("res://")) \
		.replace("$USER", ProjectSettings.globalize_path("user://")) \
		.replace("$HOME", OS.get_environment("HOME"))
