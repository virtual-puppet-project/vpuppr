class_name GLBPuppet
extends Node3D

var puppet_data: Puppet3DData = null

var skeleton: Skeleton3D = null
var _logger: Logger = null

#-----------------------------------------------------------------------------#
# Builtin functions
#-----------------------------------------------------------------------------#

func _init() -> void:
	pass

#-----------------------------------------------------------------------------#
# Private functions
#-----------------------------------------------------------------------------#

func _find_skeleton() -> Skeleton3D:
	return find_child("*Skeleton*", true, false)

#-----------------------------------------------------------------------------#
# Public functions
#-----------------------------------------------------------------------------#

func handle_ifacial_mocap(raw_data: PackedByteArray) -> void:
	var data := DataParser.ifacial_mocap(raw_data)

func handle_mediapipe(projection: Projection, blend_shapes: Array[MediaPipeCategory]) -> void:
	pass

func handle_vtube_studio(raw_data: PackedByteArray) -> void:
	var data := DataParser.vtube_studio(raw_data)

func handle_meow_face(raw_data: PackedByteArray) -> void:
	var data := DataParser.vtube_studio(raw_data)

func handle_open_see_face(raw_data: PackedByteArray) -> void:
	pass
