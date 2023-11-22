extends Control

## A pseudo-interface that all tracking GUIs should extend.

## The tracker was started.
signal started(tracker: Trackers)
# TODO you-win (nov 19, 2023): this should be used instead of the current workaround in tracking.gd
## The tracker was stopped.
signal stopped(tracker: Trackers)
## A saveable property was changed.
signal property_changed(tracker: Trackers, key: String, value: Variant)

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
