class_name Runner3D
extends Node3D

## A runner for 3D models.

## The main camera in use.
@onready
var _camera: RunnerCamera3D = $RunnerCamera3D
## The main light for the runner.
@onready
var _main_light: DirectionalLight3D = $DirectionalLight3D

## The logger for the runner.
var _logger := Logger.create("Runner3D")

## The context. Should always be set during initialization.
var context: Context = null

## The model to apply tracking data to.
var _model: Node3D = null

#-----------------------------------------------------------------------------#
# Builtin functions
#-----------------------------------------------------------------------------#

func _ready() -> void:
	if context == null:
		_logger.error("No context was found, bailing out of _ready")
		return

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

## Sets the model for the runner. [br]
## [br]
## Returns [constant OK] if the model was successfully set. [br]
## Returns [constant ERR_ALREADY_EXISTS] if the runner already has a model set. [br]
## Returns [constant ERR_ALREADY_IN_USE] if the runner has already been added.
## to the [SceneTree].
func set_model(model: Node3D) -> Error:
	if _model != null:
		return ERR_ALREADY_EXISTS
	if is_inside_tree():
		return ERR_ALREADY_IN_USE
	
	_model = model
	
	return OK
