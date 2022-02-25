# class_name AppManager
extends Node

var logger := Logger.new("AppManager")

var env := Env.new()

var ps := PubSub.new()
# Must be initialized AFTER PubSub since it needs to subscribe to config data changes
var cm := ConfigManager.new()

# These must be initialized AFTER ConfigManager because they need to pull config data


###############################################################################
# Builtin functions                                                           #
###############################################################################

func _ready() -> void:
	connect("tree_exiting", self, "_on_tree_exiting")

###############################################################################
# Connections                                                                 #
###############################################################################

func _on_tree_exiting() -> void:

	if env.current_env != Env.Envs.TEST:
		# TODO save on exit
		pass
	
	logger.info("Exiting. おやすみ。")

###############################################################################
# Private functions                                                           #
###############################################################################

###############################################################################
# Public functions                                                            #
###############################################################################
