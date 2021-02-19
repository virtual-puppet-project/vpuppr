extends MarginContainer

const RUN_FACE_TRACKER_TEXT: String = "Run facetracker"
const STOP_FACE_TRACKER_TEXT: String = "Stop facetracker"

onready var face_tracker_button: Button = $Control/MarginContainer/ScrollContainer/VBoxContainer/HBoxContainer/RunFaceTrackerButton

###############################################################################
# Builtin functions                                                           #
###############################################################################

func _ready() -> void:
	face_tracker_button.connect("pressed", self, "_on_run_face_tracker_button_pressed")
	
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
	if OS.is_debug_build():
		return
	if not AppManager.is_face_tracker_running:
		var face_tracker_fps: String = $Control/MarginContainer/ScrollContainer/VBoxContainer/HBoxContainer/InputLabel/HBoxContainer/FaceTrackerFPS.text
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
				push_error("Face tracker fps is greater than 144. This is a bad idea.")
				return
			var pid = OS.execute(OS.get_executable_path().get_base_dir() + "/OpenSeeFaceFolder/OpenSeeFace/facetracker.exe", face_tracker_options, false)
			AppManager.is_face_tracker_running = true
			AppManager.face_tracker_pid = pid
			face_tracker_button.text = STOP_FACE_TRACKER_TEXT
	else:
		OS.kill(AppManager.face_tracker_pid)
		AppManager.is_face_tracker_running = false
		face_tracker_button.text = RUN_FACE_TRACKER_TEXT

###############################################################################
# Private functions                                                           #
###############################################################################

###############################################################################
# Public functions                                                            #
###############################################################################


