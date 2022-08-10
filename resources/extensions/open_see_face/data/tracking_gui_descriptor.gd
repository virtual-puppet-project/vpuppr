extends PanelContainer

const ConfigKeys := {
	"CAMERA_NAME": "open_see_face_camera_name",
	"CAMERA_INDEX": "open_see_face_camera_index",
	"TRACKER_FPS": "open_see_face_tracker_fps",
	"SHOULD_LAUNCH_TRACKER": "open_see_face_should_launch_tracker",
	"ADDRESS": "open_see_face_address",
	"PORT": "open_see_face_port",
	"PYTHON_PATH": "open_see_face_python_path",
	"MODEL": "open_see_face_model"
}

func _init() -> void:
	for val in ConfigKeys.values():
		var res: Result = Safely.wrap(AM.cm.runtime_subscribe_to_signal(val))
		if res.is_err() and res.unwrap_err().code != Error.Code.PUB_SUB_ALREADY_CONNECTED:
			AM.logger.error(res)
			return

	_hv_fill_expand(self)
	
	var scroll_container := ScrollContainer.new()
	_hv_fill_expand(scroll_container)

	var vbox := VBoxContainer.new()
	_hv_fill_expand(vbox)

	#region Actual list of ui elements

	vbox.add_child(_camera_select())
	vbox.add_child(_tracker_fps())
	vbox.add_child(_should_launch_tracker())
	vbox.add_child(_tracker_address())
	vbox.add_child(_tracker_port())
	vbox.add_child(_model())

	# if OS.get_name().to_lower() in ["x11", "osx"]:
	# 	vbox.add_child(_python_path())

	vbox.add_child(_toggle_tracking())

	#endregion

	scroll_container.add_child(vbox)
	add_child(scroll_container)

static func _hv_fill_expand(control: Control) -> void:
	control.size_flags_horizontal = Control.SIZE_EXPAND_FILL
	control.size_flags_vertical = Control.SIZE_EXPAND_FILL

static func _h_fill_expand(control: Control) -> void:
	control.size_flags_horizontal = Control.SIZE_EXPAND_FILL

#region Connections

const IS_INT: bool = true
const IS_STRING: bool = false

static func _on_line_edit_changed(text: String, key: String, is_int: bool = false) -> void:
	if text.empty():
		return
	if is_int and not text.is_valid_integer():
		return
	
	AM.ps.publish(key, text if not is_int else text.to_int())

static func _on_button_toggled(state: bool, key: String) -> void:
	AM.ps.publish(key, state)

#endregion

func _camera_select() -> OptionButton:
	var ob := OptionButton.new()
	_h_fill_expand(ob)
	ob.hint_tooltip = tr("CAMERA_SELECT_HINT")

	var popup: PopupMenu = ob.get_popup()
	popup.connect("index_pressed", self, "_on_camera_selected", [ob])

	var os_name := OS.get_name().to_lower()

	var results := []

	var output := []
	match os_name:
		"windows":
			var exe_path: String = "%s/OpenSeeFaceFolder/OpenSeeFace/facetracker.exe" % \
					AM.em.get_extension("OpenSeeFace").expect("Unable to get context").context
			OS.execute(exe_path, ["-l", "1"], true, output)
		"osx", "x11":
			OS.execute("ls", ["/dev/v4l/by-id/"], true, output)

	if not output.empty():
		results.append_array((output[0] as String).split("\n"))
		match os_name:
			"windows":
				results.pop_back()
				results.pop_front()
			"osx", "x11":
				results.pop_back()
	else:
		results.append(tr("CAMERA_SELECT_NO_OUTPUT_1"))
		results.append(tr("CAMERA_SELECT_NO_OUTPUT_2"))

	if results.size() < 1:
		popup.add_check_item(tr("CAMERA_SELECT_NO_OUTPUT_1"))
		popup.add_check_item(tr("CAMERA_SELECT_NO_OUTPUT_2"))
		popup.set_item_checked(0, true)
		ob.text = popup.get_item_text(0)
		return ob

	for option in results:
		popup.add_check_item(option)

	var camera_name = AM.cm.get_data(ConfigKeys.CAMERA_NAME)
	if typeof(camera_name) == TYPE_NIL:
		camera_name = ""
		AM.ps.publish(ConfigKeys.CAMERA_NAME, camera_name)

	var camera_index = AM.cm.get_data(ConfigKeys.CAMERA_INDEX)
	if typeof(camera_index) == TYPE_NIL:
		camera_index = 0
		AM.ps.publish(ConfigKeys.CAMERA_INDEX, camera_index)

	# TODO compare the camera index to the actual camera name

	var found := false
	if not camera_name.empty():
		for i in popup.get_item_count():
			var item_text: String = popup.get_item_text(i)
			
			if item_text == camera_name:
				camera_index = i
				popup.set_item_checked(i, true)
				ob.text = item_text
				found = true
				break

	if not found:
		var item_text: String = popup.get_item_text(0)

		camera_index = 0
		popup.set_item_checked(0, true)
		ob.text = item_text
		AM.ps.publish(ConfigKeys.CAMERA_NAME, item_text)
	
	# Update the camera index every time since camera order can change between computer reboots
	AM.ps.publish(ConfigKeys.CAMERA_INDEX, camera_index)

	return ob

func _on_camera_selected(idx: int, ob: OptionButton) -> void:
	var popup: PopupMenu = ob.get_popup()

	var current_index: int = popup.get_current_index()
	if current_index < 0:
		AM.logger.error(tr("CAMERA_SELECTED_NO_PREVIOUSLY_SELECTED_ITEM"))
	else:
		popup.set_item_checked(current_index, false)
	
	popup.set_item_checked(idx, true)

	AM.ps.publish(ConfigKeys.CAMERA_INDEX, idx)
	AM.ps.publish(ConfigKeys.CAMERA_NAME, popup.get_item_text(idx))

func _tracker_fps() -> HBoxContainer:
	var r := HBoxContainer.new()
	_h_fill_expand(r)
	r.hint_tooltip = tr("TRACKER_FPS_HINT")

	var label := Label.new()
	_h_fill_expand(label)
	label.text = tr("TRACKER_FPS_LABEL")

	var line_edit := LineEdit.new()
	_h_fill_expand(line_edit)

	var initial_value = AM.cm.get_data(ConfigKeys.TRACKER_FPS)
	if typeof(initial_value) == TYPE_NIL:
		initial_value = int(12)
		AM.ps.publish(ConfigKeys.TRACKER_FPS, initial_value)

	line_edit.text = str(initial_value)

	r.add_child(label)
	r.add_child(line_edit)

	line_edit.connect("text_changed", self, "_on_line_edit_changed", [ConfigKeys.TRACKER_FPS, IS_INT])

	return r

func _should_launch_tracker() -> CheckButton:
	var r := CheckButton.new()
	_h_fill_expand(r)

	r.text = tr("SHOULD_LAUNCH_TRACKER_LABEL")
	r.hint_tooltip = tr("SHOULD_LAUNCH_TRACKER_HINT")

	var initial_value = AM.cm.get_data(ConfigKeys.SHOULD_LAUNCH_TRACKER)
	if typeof(initial_value) == TYPE_NIL:
		initial_value = true
		AM.ps.publish(ConfigKeys.SHOULD_LAUNCH_TRACKER, initial_value)

	r.pressed = initial_value

	r.connect("toggled", self, "_on_button_toggled", [ConfigKeys.SHOULD_LAUNCH_TRACKER])

	return r

func _tracker_address() -> HBoxContainer:
	var r := HBoxContainer.new()
	_h_fill_expand(r)
	r.hint_tooltip = tr("TRACKER_ADDRESS_HINT")

	var label := Label.new()
	_h_fill_expand(label)
	label.text = tr("TRACKER_ADDRESS_LABEL")

	var line_edit := LineEdit.new()
	_h_fill_expand(line_edit)
	
	var initial_value = AM.cm.get_data(ConfigKeys.ADDRESS)
	if typeof(initial_value) == TYPE_NIL:
		initial_value = "127.0.0.1"
		AM.ps.publish(ConfigKeys.ADDRESS, initial_value)

	line_edit.text = str(initial_value)

	r.add_child(label)
	r.add_child(line_edit)

	line_edit.connect("text_changed", self, "_on_line_edit_changed", [ConfigKeys.ADDRESS, IS_STRING])

	return r

func _tracker_port() -> HBoxContainer:
	var r := HBoxContainer.new()
	_h_fill_expand(r)
	r.hint_tooltip = tr("TRACKER_PORT_HINT")

	var label := Label.new()
	_h_fill_expand(label)
	label.text = tr("TRACKER_PORT_LABEL")

	var line_edit := LineEdit.new()
	_h_fill_expand(line_edit)
	
	var initial_value = AM.cm.get_data(ConfigKeys.PORT)
	if typeof(initial_value) == TYPE_NIL:
		initial_value = int(11573)
		AM.ps.publish(ConfigKeys.PORT, initial_value)

	line_edit.text = str(initial_value)

	r.add_child(label)
	r.add_child(line_edit)

	line_edit.connect("text_changed", self, "_on_line_edit_changed", [ConfigKeys.PORT, IS_INT])

	return r

func _toggle_tracking() -> Button:
	var r := Button.new()
	_h_fill_expand(r)
	r.text = tr("TOGGLE_TRACKING_BUTTON_TEXT_START")

	r.connect("pressed", self, "_on_toggle_tracking", [r])

	return r

func _on_toggle_tracking(button: Button) -> void:
	var trackers = get_tree().current_scene.get("trackers")
	if typeof(trackers) != TYPE_ARRAY:
		AM.logger.error(tr("TOGGLE_TRACKING_INCOMPATIBLE_RUNNER_ERROR"))
		return

	var tracker: TrackingBackendInterface
	var found := false
	for i in trackers:
		if i.get_name() == "OpenSeeFace" and i is TrackingBackendInterface:
			tracker = i
			found = true
			break

	# When this callback is triggered and tracking is already started, then the tracker
	# is being turned off. Thus if the button were to be pressed again, it would be for
	# starting the tracker
	if found:
		tracker.stop_receiver()
		trackers.erase(tracker)

		button.text = tr("TOGGLE_TRACKING_BUTTON_TEXT_START")
	else:
		var osf_res: Result = AM.em.load_resource("OpenSeeFace", "open_see_face.gd")
		if not osf_res or osf_res.is_err():
			AM.logger.error(tr("TOGGLE_TRACKING_LOAD_TRACKER_ERROR"))
			return

		var osf = osf_res.unwrap().new()

		trackers.append(osf)

		button.text = tr("TOGGLE_TRACKING_BUTTON_TEXT_STOP")

	AM.ps.publish(Globals.TRACKER_TOGGLED, not found, "OpenSeeFace")

# TODO unused now that osf is bundled using pyinstaller on all platforms
func _python_path() -> HBoxContainer:
	var r := HBoxContainer.new()
	_h_fill_expand(r)

	var label := Label.new()
	_h_fill_expand(label)
	label.text = "Python path"
	label.hint_tooltip = """
The absolute path to the python version to use. This should be defined if your system's
python version is not within Python 3.6 - Python 3.9.
	""".strip_edges()

	var line_edit := LineEdit.new()
	_h_fill_expand(line_edit)
	line_edit.placeholder_text = "/path/to/python/binary"

	var initial_value = AM.cm.get_data(ConfigKeys.PYTHON_PATH)
	if typeof(initial_value) == TYPE_NIL:
		initial_value = "*"
		AM.ps.publish(ConfigKeys.PYTHON_PATH, initial_value)

	r.add_child(label)
	r.add_child(line_edit)

	line_edit.connect("text_changed", self, "_on_line_edit_changed", [ConfigKeys.PYTHON_PATH, IS_STRING])

	return r

var POSSIBLE_ML_MODELS: Dictionary = {
	"-3": tr("ML_MODEL_NEG_3"),
	"-2": tr("ML_MODEL_NEG_2"),
	"-1": tr("ML_MODEL_NEG_1"),
	"0": tr("ML_MODEL_0"),
	"1": tr("ML_MODEL_1"),
	"2": tr("ML_MODEL_2"),
	"3": tr("ML_MODEL_3"),
	"4": tr("ML_MODEL_4")
}

func _model() -> OptionButton:
	var ob := OptionButton.new()
	_h_fill_expand(ob)
	ob.hint_tooltip = tr("ML_MODEL_SELECT_HINT")

	var popup: PopupMenu = ob.get_popup()
	popup.connect("index_pressed", self, "_on_model_selected", [ob])

	var ml_model = AM.cm.get_data(ConfigKeys.MODEL)
	if typeof(ml_model) == TYPE_NIL:
		ml_model = 3 as int
		AM.ps.publish(ConfigKeys.MODEL, ml_model)

	for model_num in POSSIBLE_ML_MODELS.keys():
		var item_text := "%s: %s" % [model_num, POSSIBLE_ML_MODELS[model_num]]
		popup.add_check_item(item_text)
		if model_num.to_int() == ml_model as int:
			popup.set_item_checked(popup.get_item_count() - 1, true)
			ob.text = item_text

	return ob

func _on_model_selected(idx: int, ob: OptionButton) -> void:
	var popup: PopupMenu = ob.get_popup()

	var current_index: int = popup.get_current_index()
	if current_index < 0:
		AM.logger.error(tr("ML_MODEL_SELECT_NO_PREVIOUS_MODEL_SELECTED_ERROR"))
	else:
		popup.set_item_checked(current_index, false)
	
	popup.set_item_checked(idx, not popup.is_item_checked(idx))

	var split: PoolStringArray = popup.get_item_text(idx).split(":")
	if split.size() < 2:
		AM.logger.error(tr("ML_MODEL_SELECT_INVALID_MODEL_SELECTED") % str(split))
		return

	if not split[0].is_valid_integer():
		AM.logger.error(tr("ML_MODEL_SELECT_NO_PRECEDING_INTEGER"))
		return

	AM.ps.publish(ConfigKeys.MODEL, split[0].to_int())
