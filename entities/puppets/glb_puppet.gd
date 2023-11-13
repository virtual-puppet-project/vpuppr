class_name GLBPuppet
extends Node3D

var puppet_data: Puppet3DData = null

var _skeleton: Skeleton3D = null
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
	return find_child("Skeleton3D")

#-----------------------------------------------------------------------------#
# Public functions
#-----------------------------------------------------------------------------#

func handle_ifacial_mocap(data: Dictionary) -> void:

	pass

func handle_mediapipe(data: Dictionary) -> void:
	pass

func handle_vtube_studio(data: Dictionary) -> void:
	pass

func handle_meow_face(data: Dictionary) -> void:
	pass

func handle_open_see_face(data: Dictionary) -> void:
	pass
