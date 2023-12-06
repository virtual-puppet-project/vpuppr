class_name Runner3D
extends Node3D

## A runner for 3D models.

const RenIK: GDScript = preload("res://addons/renik/renik.gd")

@onready
var _world_environment: WorldEnvironment = $WorldEnvironment
## The main camera in use.
@onready
var _camera: RunnerCamera3D = $RunnerCamera3D
## The main light for the runner.
@onready
var _main_light: DirectionalLight3D = $DirectionalLight3D

## The logger for the runner.
var _logger := Logger.create("Runner3D")

#-----------------------------------------------------------------------------#
# Builtin functions
#-----------------------------------------------------------------------------#

func _input(event: InputEvent) -> void:
	if not event is InputEventKey:
		return
	
	# TODO testing
	if event.keycode == KEY_0 and event.pressed:
		fly_camera(true)
	elif event.keycode == KEY_1 and event.pressed:
		fly_camera(false)

#-----------------------------------------------------------------------------#
# Private functions
#-----------------------------------------------------------------------------#

#-----------------------------------------------------------------------------#
# Public functions
#-----------------------------------------------------------------------------#

## Enable/disable a flying camera for inspecting the runner.
func fly_camera(enabled: bool) -> Error:
	const NAME := &"FlyCamera"
	if enabled:
		_logger.info("Enabling fly camera")
		
		var camera := FlyCamera.new()
		camera.name = NAME
		
		add_child(camera)
		camera.make_current()
		
		_camera.display(true)
	else:
		_logger.info("Disabling fly camera")
		
		var camera: Node = get_node_or_null(NodePath(NAME))
		if camera == null:
			_logger.error("Unable to find fly camera")
			return ERR_DOES_NOT_EXIST
		
		_camera.make_current()
		camera.queue_free()
		
		_camera.display(false)
	
	return OK

func update_from_config(runner_data: RunnerData) -> void:
	_world_environment.environment = runner_data.common_options.environment_options
