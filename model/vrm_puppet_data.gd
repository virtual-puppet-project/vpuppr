class_name VRMPuppetData
extends Puppet3DData

## The type of VRM model.
enum VrmType {
	BASE = 0, ## Basic VRM as exported from UniVRM.
	PERFECT_SYNC, ## Enhanced VRM with PerfectSync blend shapes.
}

## The threshold that needs to be reached in order to count as eyes closed (a blink). [br]
## [br]
## This is needed since tracking software often will not register a blink as a true blink,
## instead opting for a squint instead.
@export
var blink_threshold: float = 0.0
## Whether to blink both eyes if a single blink is detected.
@export
var link_eye_blinks := false
## VRM models usually have builtin limits on how far an eye can rotate. This can be ignored
## if not desired.
@export
var use_raw_eye_rotation := false
## The VRM model type.
@export
var vrm_type := VrmType.BASE

#-----------------------------------------------------------------------------#
# Builtin functions
#-----------------------------------------------------------------------------#

#-----------------------------------------------------------------------------#
# Private functions
#-----------------------------------------------------------------------------#

#-----------------------------------------------------------------------------#
# Public functions
#-----------------------------------------------------------------------------#
