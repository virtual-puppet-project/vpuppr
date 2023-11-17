class_name MeowFace
extends VTubeStudio

#-----------------------------------------------------------------------------#
# Builtin functions
#-----------------------------------------------------------------------------#

#-----------------------------------------------------------------------------#
# Private functions
#-----------------------------------------------------------------------------#

#-----------------------------------------------------------------------------#
# Public functions
#-----------------------------------------------------------------------------#

static func get_name() -> StringName:
	return &"MeowFace"

static func start(data: Dictionary) -> AbstractTracker:
	var r := super.start(data)
	if r == null:
		return r
	
	r._logger.set_name("MeowFace")
	
	return r
