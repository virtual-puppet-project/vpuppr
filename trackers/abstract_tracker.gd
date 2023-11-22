class_name AbstractTracker
extends RefCounted

## Indicate that data has been received. Parameters can vary per tracker.
signal data_received()

## List of all builtin trackers.
enum Trackers {
	NONE = 0,
	
	MEDIA_PIPE,
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

## Get the type of the tracker.
static func get_type() -> Trackers:
	return Trackers.NONE

## Start the tracker.
static func start(_data: Resource) -> AbstractTracker:
	return null

## Stop the tracker.
func stop() -> Error:
	return ERR_UNCONFIGURED
