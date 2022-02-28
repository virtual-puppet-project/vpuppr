# class_name AppManager
extends Node

var logger := Logger.new("AppManager")

var env := Env.new()

var ps: PubSub
var cm: ConfigManager
var nm

var plugins := {} # Plugin name: String -> Plugin: Object

#region Debounce

const DEBOUNCE_TIME: float = 3.0
var debouce_counter: float = 0.0
var should_save := false

#endregion

###############################################################################
# Builtin functions                                                           #
###############################################################################

func _ready() -> void:
	connect("tree_exiting", self, "_on_tree_exiting")

	ps = PubSub.new()
	# Must be initialized AFTER the PubSub since it needs to connect to other signals
	cm = ConfigManager.new()

	# These must be initialized AFTER ConfigManager because they need to pull config data

func _process(delta: float) -> void:
	if should_save:
		debouce_counter += delta
		if debouce_counter > DEBOUNCE_TIME:
			save_config_instant()

###############################################################################
# Connections                                                                 #
###############################################################################

func _on_tree_exiting() -> void:

	for key in plugins.keys():
		var plugin = plugins[key]
		if plugin.has_method("shutdown"):
			plugin.shutdown()

	if env.current_env != Env.Envs.TEST:
		print("hello")
#		save_config_instant()
	
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
	debouce_counter = 0.0
	cm.save()
