extends CanvasLayer

@onready
var _node_3d := %Node3D
@onready
var _camera := %Camera3D
@onready
var _anim_player := %AnimationPlayer
const SPIN_ANIM := "clockwise_spin"
const JITTER := "jitter"

#-----------------------------------------------------------------------------#
# Builtin functions
#-----------------------------------------------------------------------------#

#-----------------------------------------------------------------------------#
# Private functions
#-----------------------------------------------------------------------------#

#-----------------------------------------------------------------------------#
# Public functions
#-----------------------------------------------------------------------------#

func start() -> void:
	show()
	_node_3d.show()
	
	_camera.current = true
	
	if randi_range(0, 9) > 8:
		_anim_player.play(JITTER)
	else:
		_anim_player.play(SPIN_ANIM)

func stop() -> void:
	hide()
	_node_3d.hide()
	
	_camera.current = false
	_anim_player.stop()
