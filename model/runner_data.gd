class_name RunnerData
extends Resource

## All data required for a Runner to initialize.

## The name given to the Runner.
@export
var name := ""
## The path to the runner file.
@export
var runner_path := ""
## The path to the gui file.
@export
var gui_path := ""
## The path to the model file.
@export
var model_path := ""

## Data related to the model that will be loaded.
@export
var puppet_data := PuppetData.new()

## Default options for MediaPipe tracking.
@export
var mediapipe_options := MediaPipeOptions.new()
## Default options for iFacialMocap tracking.
@export
var ifacial_mocap_options := IFacialMocapOptions.new()
## Default options for MeowFace tracking.
@export
var meow_face_options := MeowFaceOptions.new()

#-----------------------------------------------------------------------------#
# Builtin functions
#-----------------------------------------------------------------------------#

#-----------------------------------------------------------------------------#
# Private functions
#-----------------------------------------------------------------------------#

#-----------------------------------------------------------------------------#
# Public functions
#-----------------------------------------------------------------------------#
