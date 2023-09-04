extends VBoxContainer

## New runner selector.
##
## The UI for creating a new runner. Tooltips are included on each option's container. [br]
## [br]
## Data passed back via [signal Window.close_requested] will either be null or a [RunnerData].

## The type of 3d puppet to use.
const ModelType3d := {
	NONE = "None",
	## A GLTF model. Only binary GLTF (GLB) is allowed.
	GLB = "GLB",
	## A VRM model.
	VRM = "VRM",
}
var _model_type_3d := ModelType3d.NONE

## The type of 2d puppet to use.
const ModelType2d := {
	NONE = "None",
	## A PNGTuber made up of 2d images.
	PNGTUBER = "PNGTuber"
}
var _model_type_2d := ModelType2d.NONE

## The type of model to load.
enum ModelType {
	NONE = 0, ## Model type has not been set.
	PUPPET_2D, ## Use 2d runners.
	PUPPET_3D, ## Use 3d runners.
	CUSTOM, ## Use neither 2d nor 3d runners. A custom runner is required.
}
var _model_type := ModelType.NONE:
	set(model_type):
		_model_type = model_type
		match _model_type:
			ModelType.PUPPET_2D:
				_options_2d.show()
				_options_3d.hide()
			ModelType.PUPPET_3D:
				_options_2d.hide()
				_options_3d.show()
			ModelType.CUSTOM:
				_options_2d.hide()
				_options_3d.hide()
				# Only toggle on in this option, toggling things off automatically
				# will be confusing
				_advanced_options_toggle.button_pressed = true

## Logger for the new runner selector.
var _logger := Logger.create("NewRunner")

## Name of the runner.
@onready
var _runner_name := %RunnerName
## Path to the model to use for the runner.
@onready
var _model_path := %ModelPath
## Path to a custom runner resource.
@onready
var _custom_runner_path := %CustomRunnerPath

## Grouping for 3D model options. Hidden by default.
@onready
var _options_3d := %Options3d
## Grouping for 2D model options. Hidden by default.
@onready
var _options_2d := %Options2d
## Toggle for showing advanced options.
@onready
var _advanced_options_toggle := %AdvancedOptionsToggle
## Grouping for advanced options. Hidden by default.
@onready
var _advanced_options := %AdvancedOptions

## Validation statuses. If any of these exist in [_invalid_statuses], the form cannot be submitted.
const Status := {
	Setup = {
		WINDOW_NOT_SET = "Window was not set, this is a major bug!",
		SAVE_DIR_HANDLE_FMT1 = "Unable to open user data directory at {0}, this is major bug!"
	},
	RunnerName = {
		EMPTY = "Runner name is empty!",
		ALREADY_EXISTS_FMT1 = "Runner name {0} already exists"
	},
	ModelPath = {
		EXISTS_FMT1 = "{0} does not exist",
		OPEN_FMT1 = "Cannot access {0}",
	},
	ModelType2d = {
		NONE = "Model type 3d is not defined!",
	},
	ModelType3d = {
		NONE = "Model type 2d is not defined!",
	},
}
## Status label for displaying errors.
@onready
var _status := %Status
## Each item validates itself. If it's invalid, an entry will be added to this
## array and the [_status] is updated. If a previously invalid item is
## changed to be valid, then the entry will be updated and the [_status] should
## check for other entries.
var _invalid_statuses: Array[String] = []

## The accept button. Will be disabled if there are validation errors.
@onready
var _accept := %Accept

## Directory handle for checking runner names.
var _save_dir_handle: DirAccess = null
## The containing window. Used for passing data.
var window: Window = null

#-----------------------------------------------------------------------------#
# Builtin functions
#-----------------------------------------------------------------------------#

func _ready() -> void:
	if window == null:
		var err_msg := Status.Setup.WINDOW_NOT_SET
		_logger.error(err_msg)
		_add_invalid_status(err_msg)
		return
	
	_save_dir_handle = DirAccess.open(&"user://")
	if _save_dir_handle == null:
		var err_msg := Status.Setup.SAVE_DIR_HANDLE_FMT1.format([ProjectSettings.globalize_path(&"user://")])
		_logger.error(err_msg)
		_add_invalid_status(err_msg)
		return
	
	_runner_name.text_changed.connect(_validate_runner_name)
	
	_model_path.text_changed.connect(_validate_model_path)
	%SelectModelPath.pressed.connect(func() -> void:
		var fd := FileDialog.new()
		fd.access = FileDialog.ACCESS_FILESYSTEM
		fd.file_mode = FileDialog.FILE_MODE_OPEN_FILE
		
		fd.close_requested.connect(func(_path: String = "") -> void:
			fd.queue_free()
		)
		fd.visibility_changed.connect(func() -> void:
			if not fd.visible:
				fd.close_requested.emit()
		)
		fd.file_selected.connect(func(path: String) -> void:
			fd.close_requested.emit(path)
		)
		add_child(fd)
		fd.popup_centered_ratio(0.5)
		
		var model_path: Variant = await fd.close_requested
		if model_path is String:
			_model_path.text = model_path
			_validate_model_path(model_path)
	)
	
	var model_type_3d := %ModelType3d as OptionButton
	for i in ModelType3d.keys():
		model_type_3d.add_item(i)
	model_type_3d.item_selected.connect(func(idx: int) -> void:
		_validate_model_type_3d(model_type_3d.get_item_text(idx))
	)
	
	var model_type_2d := %ModelType2d as OptionButton
	for i in ModelType2d.keys():
		model_type_2d.add_item(i)
	model_type_2d.item_selected.connect(func(idx: int) -> void:
		_validate_model_type_2d(model_type_2d.get_item_text(idx))
	)
	
	_advanced_options_toggle.toggled.connect(func(state: bool) -> void:
		_advanced_options.visible = state
	)
	
	_accept.pressed.connect(func() -> void:
		_logger.debug("accept pressed!")
		
		var data := RunnerData.new()
		
		data.set_name(_runner_name.text)
		match _model_type:
			ModelType.PUPPET_3D:
				# TODO hardcoded for testing
				data.set_runner_path("res://screens/runners/runner_3d.tscn")
				match _model_type_3d:
					ModelType3d.GLB:
						data.set_puppet_class("GlbPuppet")
					ModelType3d.VRM:
						data.set_puppet_class("VrmPuppet")
			ModelType.PUPPET_2D:
				# TODO hardcoded for testing + this is the wrong file
				data.set_runner_path("res://screens/runners/runner_3d.tscn")
				match _model_type_2d:
					ModelType2d.PNGTUBER:
						data.set_puppet_class("PngPuppet")
			ModelType.CUSTOM:
				# TODO stub
				_logger.error("Not yet implemented!")
				return
		# TODO hardcoded for testing
		data.set_gui_path("res://gui/default_gui.tscn")
		data.set_model_path(_model_path.text)
		
		window.close_requested.emit(data)
	)
	%Cancel.pressed.connect(func() -> void:
		window.close_requested.emit()
	)
	
	_options_3d.hide()
	_options_2d.hide()
	_advanced_options.hide()

#-----------------------------------------------------------------------------#
# Private functions
#-----------------------------------------------------------------------------#

func _update_status() -> void:
	if _invalid_statuses.is_empty():
		_status.text = ""
		_accept.disabled = false
		return
	
	_status.text = "[center][wave]{0}[/wave][/center]".format([_invalid_statuses.back()])
	_accept.disabled = true

func _add_invalid_status(message: String) -> void:
	if _invalid_statuses.has(message):
		return
	_invalid_statuses.push_back(message)
	
	_update_status()

func _remove_invalid_status(message: String) -> void:
	_invalid_statuses.erase(message)
	
	_update_status()

func _validate_runner_name(text: String) -> void:
	if text.is_empty():
		_add_invalid_status(Status.RunnerName.EMPTY)
		return
	# TODO this seems slow
	for file in _save_dir_handle.get_files():
		if file.get_file() == text:
			_add_invalid_status(Status.RunnerName.ALREADY_EXISTS_FMT1.format([text]))
			return
	
	for i in Status.RunnerName.values():
		_remove_invalid_status(i)

func _validate_model_path(text: String) -> void:
	if not FileAccess.file_exists(text):
		_add_invalid_status(Status.ModelPath.EXISTS_FMT1.format([text]))
		return
	if not FileAccess.open(text, FileAccess.READ):
		_add_invalid_status(Status.ModelPath.OPEN_FMT1.format([text]))
		return
	
	match text.get_extension().to_lower():
		"glb", "vrm":
			_model_type = ModelType.PUPPET_3D
		"png", "jpg", "jpeg", "bmp", "webp":
			_model_type = ModelType.PUPPET_2D
		_:
			_logger.info("Could not automatically handle extension for file {0}".format([text]))
			_model_type = ModelType.CUSTOM
	
	for i in Status.ModelPath.values():
		_remove_invalid_status(i)

func _validate_model_type_3d(text: String) -> void:
	match text:
		ModelType3d.NONE:
			_model_type_3d = ModelType3d.NONE
			_add_invalid_status(Status.ModelType3d.NONE)
		ModelType3d.GLB:
			_model_type_3d = ModelType3d.GLB
		ModelType3d.VRM:
			_model_type_3d = ModelType3d.VRM
		_:
			_logger.error("Unhandled ModelType3d {0}".format(text))
	
	_update_status()

func _validate_model_type_2d(text: String) -> void:
	match text:
		ModelType2d.NONE:
			_model_type_2d = ModelType2d.NONE
			_add_invalid_status(Status.ModelType2d.NONE)
		ModelType2d.PNGTUBER:
			_model_type_2d = ModelType2d.PNGTUBER
		_:
			_logger.error("Unhandled ModelType2d {0}".format(text))
	
	_update_status()

func _validate_custom_runner_path(text: String) -> void:
	
	_update_status()

#-----------------------------------------------------------------------------#
# Public functions
#-----------------------------------------------------------------------------#

