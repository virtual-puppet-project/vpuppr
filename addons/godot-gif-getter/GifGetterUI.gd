extends CanvasLayer

"""
GifGetterUI

Single scene + script that can be dropped in and out of any scene.

Most gif-related variables are set from the LineEdit values.
"""

const MAX_CONSOLE_MESSAGE_COUNT: int = 20

onready var control: Control = $Control

onready var capture_now_button: Button = $Control/Options/VBoxContainer/ButtonContainer/CaptureNowButton
onready var capture_in_five_seconds_button: Button = $Control/Options/VBoxContainer/ButtonContainer/CaptureInFiveSecondsButton
onready var save_location_line_edit: LineEdit = $Control/Options/VBoxContainer/SaveLocationContainer/LineEdit
onready var render_quality_line_edit: LineEdit = $Control/Options/VBoxContainer/RenderQualityContainer/LineEdit
onready var frames_line_edit: LineEdit = $Control/Options/VBoxContainer/FramesContainer/LineEdit
onready var frame_skip_line_edit: LineEdit = $Control/Options/VBoxContainer/FrameSkipContainer/LineEdit
onready var frame_delay_line_edit: LineEdit = $Control/Options/VBoxContainer/FrameDelayContainer/LineEdit
onready var threads_line_edit: LineEdit = $Control/Options/VBoxContainer/ThreadsContainer/LineEdit
onready var hotkey_line_edit: LineEdit = $Control/Options/VBoxContainer/HotkeyContainer/LineEdit

onready var console: VBoxContainer = $Control/Console/ScrollContainer/VBoxContainer

onready var _viewport_rid: RID = get_viewport().get_viewport_rid()

# Determines if viewport texture data should be stored for processing
var _should_capture: bool = false
# Holds viewport texture data
var _images: Array = []

# Delay between storing viewport texture data
var _frame_skip: int
# Count ticks between each frame skip
var _frame_skip_counter: int = 0
# Delay between each frame in the gif
var _gif_frame_delay: int
# Total number of frames in the gif
var _max_frames: int
# Count frames stored
var _current_frame: int = 1

# Rendering quality for gifs from 1 - 30. 1 is highest quality but slow
var _render_quality: int

# Background thread for capturing screenshots
var _capture_thread: Thread = Thread.new()
# Number of render threads
var _max_threads: int

# Path to intended save location. Uses Rust's fs library instead of Godot's
var _save_location: String

# Rust gif creation library
var _gif_handler: Reference = load("res://addons/godot-gif-getter/GifHandler.gdns").new()

var _hide_ui_action: String

###############################################################################
# Builtin functions                                                           #
###############################################################################

func _ready() -> void:
	capture_now_button.connect("pressed", self, "_on_capture_now")
	capture_in_five_seconds_button.connect("pressed", self, "_on_capture_in_five_seconds")
	$Control/Options/VBoxContainer/SaveLocationContainer/Button.connect("pressed", self, "_on_select_path_button_pressed")
	$Control/Options/VBoxContainer/HotkeyContainer/Button.connect("pressed", self, "_on_set_hotkey_button_pressed")

func _physics_process(_delta: float) -> void:
	if _should_capture:
		if not _capture_thread.is_active():
			_capture_thread.start(self, "_capture_frames")

func _input(event: InputEvent) -> void:
	if _hide_ui_action:
		if (not _should_capture and event.is_action_pressed(_hide_ui_action)):
			control.visible = not control.visible

func _exit_tree() -> void:
	if _capture_thread.is_active():
		_capture_thread.wait_to_finish()

###############################################################################
# Connections                                                                 #
###############################################################################

func _on_capture_now() -> void:
	# Validate input
	var dir: Directory = Directory.new()
	if not dir.dir_exists(save_location_line_edit.text.get_base_dir()):
		_log_message("Directory does not exist.", true)
		return
	if not render_quality_line_edit.text.is_valid_integer():
		_log_message("Render quality input is not a valid integer.", true)
		return
	if not frames_line_edit.text.is_valid_integer():
		_log_message("Frames input is not a valid integer.", true)
		return
	if not frame_skip_line_edit.text.is_valid_integer():
		_log_message("Frame skip input is not a valid integer.", true)
		return
	if not frame_delay_line_edit.text.is_valid_integer():
		_log_message("Frame delay input is not a valid integer.", true)
		return
	if not threads_line_edit.text.is_valid_integer():
		_log_message("Threads input is not a valid integer.", true)
		return
	
	_save_location = save_location_line_edit.text
	_render_quality = render_quality_line_edit.text.to_int()
	_max_frames = frames_line_edit.text.to_int()
	_frame_skip = frame_skip_line_edit.text.to_int()
	_gif_frame_delay = frame_delay_line_edit.text.to_float()
	_max_threads = threads_line_edit.text.to_int()
	
	_should_capture = true
	control.visible = false

	yield(get_tree(), "physics_frame")

func _on_capture_in_five_seconds() -> void:
	yield(get_tree().create_timer(5.0), "timeout")
	_on_capture_now()

func _on_select_path_button_pressed() -> void:
	var fd: FileDialog = FileDialog.new()
	fd.name = "fd"
	fd.mode = FileDialog.MODE_SAVE_FILE
	fd.access = FileDialog.ACCESS_FILESYSTEM
	fd.current_dir = OS.get_executable_path().get_base_dir()
	fd.current_path = fd.current_dir
	fd.current_file = "result.gif"
	fd.add_filter("*.gif ; gif files")
	fd.connect("file_selected", self, "_on_system_path_selected")
	fd.connect("popup_hide", self, "_on_popup_hide")
	
	var screen_middle: Vector2 = Vector2(get_viewport().size.x / 2, get_viewport().size.y / 2)
	fd.set_global_position(screen_middle)
	fd.rect_size = screen_middle
	
	control.add_child(fd)
	fd.popup_centered_clamped(screen_middle)
	
	yield(fd, "file_selected")
	fd.queue_free()

func _on_system_path_selected(path: String) -> void:
	var path_tokens = path.split("/")
	path_tokens.invert()
	# If you don't select anything, path will auto-populate .gif as the filename
	if (path_tokens[0] == ".gif"):
		path_tokens[0] = "result.gif"
	path_tokens.invert()
	
	save_location_line_edit.text = path_tokens.join("/")

func _on_popup_hide() -> void:
	var fd: FileDialog = get_node_or_null("fd")
	if fd:
		fd.queue_free()

func _on_set_hotkey_button_pressed() -> void:
	if hotkey_line_edit.text:
		if InputMap.has_action(hotkey_line_edit.text):
			_hide_ui_action = hotkey_line_edit.text
			_log_message("Hide UI action set to %s ." % _hide_ui_action)
		else:
			_log_message("Action not configured in your project.", true)
	else:
		_hide_ui_action = ""
		_log_message("Hide UI action unset.")

###############################################################################
# Private functions                                                           #
###############################################################################

func _rust_multi_thread() -> void:
	"""
	Wrapper function for calling a Rust library to process and render a gif.
	"""
	var images_bytes: Array = []
	for image in _images:
		images_bytes.append(image.get_data())
	_gif_handler.set_file_name(_save_location)
	_gif_handler.set_frame_delay(_gif_frame_delay)
	_gif_handler.set_parent(self)
	_gif_handler.set_render_quality(_render_quality)
	_gif_handler.write_frames(
			images_bytes,
			int(get_viewport().size.x),
			int(get_viewport().size.y),
			_max_threads,
			_max_frames)

func _capture_frames(_x) -> void:
	"""
	Needs to be run on a background thread otherwise it blocks the main thread
	when saving a viewport image.
	
	_max_frames has 1 added to it since the last frame will usually have the UI
	visible in it. Instead of solving that problem, just remove the last frame.
	"""
	while _should_capture:
		_frame_skip_counter += 1
		if (_frame_skip_counter > _frame_skip and _current_frame <= _max_frames + 1):
			var image: Image = VisualServer.texture_get_data(VisualServer.viewport_get_texture(_viewport_rid))
			image.convert(Image.FORMAT_RGBA8)
			image.flip_y() # Images from the viewport are upside down
			
			_images.append(image)
			
			_frame_skip_counter = 0
			_current_frame += 1
		elif (_current_frame > _max_frames + 1):
			_should_capture = false
			_current_frame = 1
			control.visible = true
			_images.pop_back()
			
			_rust_multi_thread()

			_log_message("gif saved")

			_images.clear()
			
			_capture_thread.call_deferred("wait_to_finish")

func _log_message(message: String, is_error: bool = false) -> void:
	var label: Label = Label.new()
	if is_error:
		label.text += "[ERROR] "
	label.text += message
	console.call_deferred("add_child", label)
	yield(label, "ready")
	console.move_child(label, 0)
	print(message)
	
	while console.get_child_count() > MAX_CONSOLE_MESSAGE_COUNT:
		console.get_child(console.get_child_count() - 1).free()

###############################################################################
# Public functions                                                            #
###############################################################################


