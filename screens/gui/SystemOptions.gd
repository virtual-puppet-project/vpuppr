extends MarginContainer

const RUN_FACE_TRACKER_TEXT: String = "Run face tracker"
const STOP_FACE_TRACKER_TEXT: String = "Stop face tracker"

onready var face_tracker_button: Button = $Control/MarginContainer/VBoxContainer/MiddleColorRect/HBoxContainer/VBoxContainer/RunFaceTrackerButton
onready var set_offsets_button: Button = $Control/MarginContainer/VBoxContainer/MiddleColorRect/HBoxContainer/VBoxContainer/SetOffsetsButton
onready var console_message_container: VBoxContainer = $Control/MarginContainer/VBoxContainer/BottomColorRect/ScrollContainer/ConsoleMessageContainer

###############################################################################
# Builtin functions                                                           #
###############################################################################

func _ready() -> void:
	face_tracker_button.connect("pressed", self, "_on_run_face_tracker_button_pressed")
	AppManager.connect("console_log", self, "_on_console_log")
	
	$Control/MarginContainer/VBoxContainer/TopColorRect/HBoxContainer/ApplyPropertiesButton.connect("pressed", self, "_on_apply_properties_button_pressed")
	$Control/MarginContainer/VBoxContainer/TopColorRect/HBoxContainer/ResetPropertiesButton.connect("pressed", self, "_on_reset_properties_button_pressed")
	
	# TODO auto connect to port to see if face tracker is running
	# instead of blindly starting face tracker
	# TODO add camera number override?
	# TODO add ip/url override
	# TODO add port override
	if AppManager.is_face_tracker_running:
		face_tracker_button.text = STOP_FACE_TRACKER_TEXT
	else:
		face_tracker_button.text = RUN_FACE_TRACKER_TEXT

###############################################################################
# Connections                                                                 #
###############################################################################

func _on_run_face_tracker_button_pressed() -> void:
	# if OS.is_debug_build():
	# 	AppManager.emit_signal("console_log", "Running in debug mode, facetracker will not start.")
	# 	# Program will likely crash during testing so it won't clean up
	# 	# the facetracker correctly
	# 	return
	if not AppManager.is_face_tracker_running:
		AppManager.log_message("Starting face tracker.")
		var face_tracker_fps: String = $Control/MarginContainer/VBoxContainer/MiddleColorRect/HBoxContainer/InputLabel/HBoxContainer/FaceTrackerFPS.text
		var face_tracker_options: PoolStringArray = [
			"-c",
			"0",
			"-F",
			face_tracker_fps,
			"-D",
			"-1",
			"-v",
			"0",
			"-s",
			"1",
			"-P",
			"1",
			"--discard-after",
			"0",
			"--scan-every",
			"0",
			"--no-3d-adapt",
			"1",
			"--max-feature-updates",
			"900"
		]
		if face_tracker_fps.is_valid_float():
			if float(face_tracker_fps) > 144:
				AppManager.log_message("Face tracker fps is greater than 144. This is a bad idea.")
				AppManager.log_message("Declining to start face tracker.")
				return
			var pid = OS.execute(OS.get_executable_path().get_base_dir() + "/OpenSeeFaceFolder/OpenSeeFace/facetracker.exe",
					face_tracker_options, false, [], true)
			AppManager.is_face_tracker_running = true
			AppManager.face_tracker_pid = pid
			face_tracker_button.text = STOP_FACE_TRACKER_TEXT

			OpenSeeGd.start_receiver()

			AppManager.log_message("Face tracker started.")
	else:
		AppManager.log_message("Stopping face tracker.")
		
		OpenSeeGd.stop_receiver()
		
		OS.kill(AppManager.face_tracker_pid)
		AppManager.is_face_tracker_running = false
		face_tracker_button.text = RUN_FACE_TRACKER_TEXT

		AppManager.log_message("Face tracker stopped.")

func _on_apply_properties_button_pressed() -> void:
	AppManager.apply_properties()

func _on_reset_properties_button_pressed() -> void:
	AppManager.reset_properties()

func _on_console_log(message: String) -> void:
	_cull_console_logs()
	var label: Label = Label.new()
	label.text = message
	
	console_message_container.add_child(label)
	console_message_container.move_child(label, 0)

###############################################################################
# Private functions                                                           #
###############################################################################

func _cull_console_logs() -> void:
	if console_message_container.get_child_count() > 9:
		console_message_container.get_child(console_message_container.get_child_count() - 1).free()
	else:
		return
	_cull_console_logs()

###############################################################################
# Public functions                                                            #
###############################################################################


