class_name Runner3D
extends Node3D

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
# TODO testing
#var mf: MeowFace

#-----------------------------------------------------------------------------#
# Builtin functions
#-----------------------------------------------------------------------------#

func _ready() -> void:
	if context == null:
		_logger.error("No context was found, bailing out of _ready")
		return
#	for child in get_children():
#		if child is VrmPuppet:
#			_model = child
#			break
#
#	_model.a_pose()
#
#	mf = MeowFace.create({
#		bind_port = 21412,
#		connect_address = "192.168.88.51",
#		connect_port = 21412,
#		puppet = _model
#	})
#	mf.data_received.connect(func(data: MeowFaceData) -> void:
#		_model.handle_meow_face(data)
#	)
#	if mf.start() != OK:
#		printerr("asdf")
	
	pass

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
