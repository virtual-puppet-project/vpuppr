extends Control

## A pseudo-interface that all tracking GUIs should extend.

## The tracker was started.
signal started(tracker: AbstractTracker.Trackers, data: Dictionary)
## The tracker was stopped.
signal stopped(tracker: AbstractTracker.Trackers)

const Trackers := AbstractTracker.Trackers

@onready
var start := %Start

#-----------------------------------------------------------------------------#
# Builtin functions
#-----------------------------------------------------------------------------#

#-----------------------------------------------------------------------------#
# Private functions
#-----------------------------------------------------------------------------#

#-----------------------------------------------------------------------------#
# Public functions
#-----------------------------------------------------------------------------#

func get_type() -> Trackers:
	return Trackers.NONE
