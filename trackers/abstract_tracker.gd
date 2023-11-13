class_name AbstractTracker
extends RefCounted

## Indicate that data has been received. Parameters can vary per tracker.
signal data_received()

## List of all builtin trackers.
enum Trackers {
	MEDIA_PIPE = 0,
	I_FACIAL_MOCAP,
	VTUBE_STUDIO,
	MEOW_FACE,
	OPEN_SEE_FACE,
	CUSTOM ## A tracker that provides its own GUI and data applier.
}

#-----------------------------------------------------------------------------#
# Builtin functions
#-----------------------------------------------------------------------------#

#-----------------------------------------------------------------------------#
# Private functions
#-----------------------------------------------------------------------------#

#-----------------------------------------------------------------------------#
# Public functions
#-----------------------------------------------------------------------------#

## Get the name of the tracker.
static func get_name() -> StringName:
	return &"AbstractTracker"

## Start the tracker.
static func start(_data: Dictionary) -> AbstractTracker:
	return null

## Stop the tracker.
func stop() -> Error:
	return ERR_UNCONFIGURED
