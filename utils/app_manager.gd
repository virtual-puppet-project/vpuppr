class_name AppManager
extends Node

var logger: Logger

var env := Env.new()

var ps: PubSub
var cm: ConfigManager
var em: ExtensionManager
var nm

var plugins := {} # Plugin name: String -> Plugin: Object

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
	connect("tree_exiting", self, "_on_tree_exiting")

	ps = PubSub.new()
	# Must be initialized AFTER the PubSub since it needs to connect to other signals
	cm = ConfigManager.new()

	# These must be initialized AFTER ConfigManager because they need to pull config data
	em = ExtensionManager.new()

	# Initialized here since loggers must connect to the PubSub
	logger = Logger.new("AppManager")

func _process(delta: float) -> void:
	if should_save:
		debounce_counter += delta
		if debounce_counter > DEBOUNCE_TIME:
			save_config_instant()

###############################################################################
# Connections                                                                 #
###############################################################################

func _on_tree_exiting() -> void:
	if tracker != null:
		tracker.stop_receiver()

	for key in plugins.keys():
		var plugin = plugins[key]
		if plugin.has_method("shutdown"):
			plugin.shutdown()

	if env.current_env != Env.Envs.TEST:
		save_config_instant()
	
	logger.info("Exiting. おやすみ。")

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
