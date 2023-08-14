class_name AbstractTracker
extends RefCounted

#-----------------------------------------------------------------------------#
# Builtin functions
#-----------------------------------------------------------------------------#

#-----------------------------------------------------------------------------#
# Private functions
#-----------------------------------------------------------------------------#

#-----------------------------------------------------------------------------#
# Public functions
#-----------------------------------------------------------------------------#

static func create(_data: Dictionary) -> AbstractTracker:
	return null

func start() -> Error:
	return ERR_UNCONFIGURED

func stop() -> Error:
	return ERR_UNCONFIGURED

func poll() -> void:
	pass
