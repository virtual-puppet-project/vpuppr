class_name FlyCamera
extends Camera3D

## Simple fly camera for viewing a 3d scene.

const SPEED: float = 5.0
const SHIFT_MULTI: float = 3.0

var _mouse_motion := Vector2.ZERO

#-----------------------------------------------------------------------------#
# Builtin functions
#-----------------------------------------------------------------------------#

func _ready() -> void:
	Input.mouse_mode = Input.MOUSE_MODE_CAPTURED

func _exit_tree() -> void:
	Input.mouse_mode = Input.MOUSE_MODE_VISIBLE

func _input(event: InputEvent) -> void:
	if event is InputEventKey:
		if event.keycode == KEY_ESCAPE and event.pressed:
			if Input.mouse_mode == Input.MOUSE_MODE_VISIBLE:
				Input.mouse_mode = Input.MOUSE_MODE_CAPTURED
			else:
				Input.mouse_mode = Input.MOUSE_MODE_VISIBLE
	elif event is InputEventMouseMotion:
		_mouse_motion = event.relative

func _physics_process(delta: float) -> void:
	rotate_y(-_mouse_motion.x * delta)
	rotate_object_local(Vector3.RIGHT, -_mouse_motion.y * delta)
	
	_mouse_motion = Vector2.ZERO
	
	var input := Vector3()
	
	if Input.is_key_pressed(KEY_W):
		input.z -= 1
	if Input.is_key_pressed(KEY_A):
		input.x -= 1
	if Input.is_key_pressed(KEY_S):
		input.z += 1
	if Input.is_key_pressed(KEY_D):
		input.x += 1
	if Input.is_key_pressed(KEY_Q):
		input.y -= 1
	if Input.is_key_pressed(KEY_E):
		input.y += 1
	
	input = (input.normalized() * delta * SPEED)
	if Input.is_key_pressed(KEY_SHIFT):
		input *= SHIFT_MULTI
	
	translate(input)

#-----------------------------------------------------------------------------#
# Private functions
#-----------------------------------------------------------------------------#

#-----------------------------------------------------------------------------#
# Public functions
#-----------------------------------------------------------------------------#
