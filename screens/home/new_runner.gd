extends Window

# TODO move to a global?
const RunnerType := {
	VRM_RUNNER = "VRM",
	PNG_TUBER_RUNNER = "PNGTuber"
}
var _runner_type_selection := RunnerType.VRM_RUNNER

const GuiType := {
	STANDARD_GUI = "Standard GUI"
}
var _gui_type_selection := GuiType.STANDARD_GUI

var _logger := Logger.emplace("NewRunner")

@onready
var _name_input := %NameInput
@onready
var _model_container := %Model
@onready
var _model_path := %ModelPath
@onready
var _choose_model := %ChooseModel
@onready
var _status := %Status

@onready
var _confirm := %Confirm
@onready
var _cancel := %Cancel

#-----------------------------------------------------------------------------#
# Builtin functions
#-----------------------------------------------------------------------------#

func _ready() -> void:
	_cancel.pressed.connect(func() -> void:
		# TODO this is not great, what to do when the window is closed instead of the _cancel button
		close_requested.emit()
	)
	visibility_changed.connect(func() -> void:
		if not visible:
			close_requested.emit()
	)
	close_requested.connect(func(data: RunnerData = null) -> void:
		queue_free()
	)
	
	# TODO use default no preview image
#	runner_data.preview_path = "C:/Users/theaz/Pictures/astro.png"
	
	_confirm.pressed.connect(func() -> void:
		var data := RunnerData.new()
		
		data.name = _name_input.text
		# TODO use default no preview image
		data.preview_path = ""
		
		match _runner_type_selection:
			RunnerType.VRM_RUNNER:
				data.runner_path = "res://screens/runners/vrm_runner.tscn"
				
				var config := VrmConfig.new()
				config.model_path = _model_path.text
				
				data.config = config
				data.config_type = RunnerData.ConfigType.VRM
				
			RunnerType.PNG_TUBER_RUNNER:
				data.runner_path = "res://screens/runners/png_tuber_runner.tscn"
				
				var config := PngTuberConfig.new()
				# TODO stub
				
				data.config = config
				data.config_type = RunnerData.ConfigType.PNG
				
				# TODO seems kind of weird to set gui stuff here instead of based off of gui type
				data.gui_menus = [
					GuiMenu.new("PNG Tuber", "res://gui/2d/png-tuber-config/png_tuber_config.tscn"),
					GuiMenu.new("Tracking", "res://gui/tracking.tscn"),
					GuiMenu.new("Mic Input", "res://gui/mic_input.tscn")
				]
		
		match _gui_type_selection:
			GuiType.STANDARD_GUI:
				data.gui_path = "res://gui/standard_gui.tscn"
		
		close_requested.emit(data)
	)
	
	_name_input.text_changed.connect(func(_text: String) -> void:
		_validate()
	)
	
	_model_path.text_changed.connect(func(_text: String) -> void:
		_validate()
	)
	_choose_model.pressed.connect(func() -> void:
		var fd := FileDialog.new()
		fd.access = FileDialog.ACCESS_FILESYSTEM
		fd.file_mode = FileDialog.FILE_MODE_OPEN_FILE
		
		fd.file_selected.connect(func(path: String) -> void:
			fd.close_requested.emit(path)
		)
		fd.visibility_changed.connect(func() -> void:
			if not fd.visible:
				fd.close_requested.emit(fd.current_path)
		)
		fd.close_requested.connect(func(_path: String) -> void:
			fd.queue_free()
		)
		
		add_child(fd)
		fd.popup_centered_ratio()
		
		var path: Variant = await fd.close_requested
		
		if path == null or not path is String:
			return
		
		_model_path.text = path
		_model_path.text_changed.emit(_model_path.text)
	)
	
	var runner_type: OptionButton = %RunnerType
	var runner_type_popup: PopupMenu = runner_type.get_popup()
	for i in RunnerType.values():
		runner_type_popup.add_item(i)
	runner_type_popup.index_pressed.connect(func(idx: int) -> void:
		_runner_type_selection = runner_type_popup.get_item_text(idx)
		
		match _runner_type_selection:
			RunnerType.VRM_RUNNER:
				_model_container.show()
			RunnerType.PNG_TUBER_RUNNER:
				_model_container.hide()
			_:
				_logger.error("Unhandled runner type: %s" % _runner_type_selection)
		
		_validate()
	)
	runner_type.select(0)
	runner_type_popup.index_pressed.emit(0)
	
	var gui_type: OptionButton = %GuiType
	var gui_type_popup: PopupMenu = gui_type.get_popup()
	for i in GuiType.values():
		gui_type_popup.add_item(i)
	gui_type_popup.index_pressed.connect(func(idx: int) -> void:
		_gui_type_selection = gui_type_popup.get_item_text(idx)
		
		match _gui_type_selection:
			GuiType.STANDARD_GUI:
				pass
			_:
				_logger.error("Unhandled gui type: %s" % _gui_type_selection)
	)
	gui_type.select(0)
	gui_type_popup.index_pressed.emit(0)

#-----------------------------------------------------------------------------#
# Private functions
#-----------------------------------------------------------------------------#

func _update_status(text: String) -> void:
	_status.text = text

func _block_submission(state: bool) -> void:
	_confirm.disabled = state

func _validate() -> void:
	if _name_input.text.is_empty():
		_block_submission(true)
		_update_status("Runner with name %s already exists" % _name_input.text)
		return
	if FileAccess.file_exists("%s.tres" % _name_input.text):
		_block_submission(true)
		_update_status("Model does not exist at path %s" % _name_input.text)
		return
	
	match _runner_type_selection:
		RunnerType.VRM_RUNNER:
			if not FileAccess.file_exists(_model_path.text):
				_block_submission(true)
				_update_status("Model does not exist at path %s" % _model_path.text)
				return
		RunnerType.PNG_TUBER_RUNNER:
			pass
	
	match _gui_type_selection:
		GuiType:
			pass
	
	_block_submission(false)
	_update_status("")

#-----------------------------------------------------------------------------#
# Public functions
#-----------------------------------------------------------------------------#

