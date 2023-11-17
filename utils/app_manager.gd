class_name AppManager
extends Node

const DEFAULT_SCREEN_SIZE := Vector2i(1600, 900)

var metadata: Metadata = null

## Whether debug checks should be enabled. Can be overridden in production builds.
var debug_mode := OS.is_debug_build()

#-----------------------------------------------------------------------------#
# Builtin functions
#-----------------------------------------------------------------------------#

func _init() -> void:
	pass

func _exit_tree() -> void:
	if metadata.try_save() != OK:
		printerr("Failed to save metadata before exiting")

#-----------------------------------------------------------------------------#
# Private functions
#-----------------------------------------------------------------------------#

#-----------------------------------------------------------------------------#
# Public functions
#-----------------------------------------------------------------------------#

