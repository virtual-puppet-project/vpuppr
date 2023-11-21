class_name CommonOptions
extends Resource

## Options that can be defaulted across runners and then overridden.

## Options for MediaPipe tracking.
@export
var mediapipe_options := MediaPipeOptions.new()
## Options for iFacialMocap tracking.
@export
var ifacial_mocap_options := IFacialMocapOptions.new()
## Options for VTubeStudio tracking.
@export
var vtube_studio_options := VTubeStudioOptions.new()
## Options for MeowFace tracking.
@export
var meow_face_options := MeowFaceOptions.new()

## Options for configuring the [WorldEnvironment] [Environment].
@export
var environment_options := Environment.new()

#-----------------------------------------------------------------------------#
# Builtin functions
#-----------------------------------------------------------------------------#

#-----------------------------------------------------------------------------#
# Private functions
#-----------------------------------------------------------------------------#

#-----------------------------------------------------------------------------#
# Public functions
#-----------------------------------------------------------------------------#
