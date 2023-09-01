class_name RunnerCamera3D
extends Camera3D

## A regular [Camera3D] with a mesh attached to it.

@onready
var _mesh: MeshInstance3D = $Mesh

#-----------------------------------------------------------------------------#
# Builtin functions
#-----------------------------------------------------------------------------#

#-----------------------------------------------------------------------------#
# Private functions
#-----------------------------------------------------------------------------#

#-----------------------------------------------------------------------------#
# Public functions
#-----------------------------------------------------------------------------#

## Show or hide the camera mesh.
func display(enabled: bool) -> void:
	_mesh.visible = enabled
