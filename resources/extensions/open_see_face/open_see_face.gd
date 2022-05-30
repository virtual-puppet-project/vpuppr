extends TrackingBackendInterface

const PACKET_FRAME_SIZE: int = 8 + 4 + 2 * 4 + 2 * 4 + 1 + 4 + 3 * 4 + 3 * 4 + 4 * 4 + 4 * 68 + 4 * 2 * 68 + 4 * 3 * 70 + 4 * 14

const MAX_TRACKER_FPS: int = 144

const RUN_FACE_TRACKER_TEXT := "Run tracker"
const STOP_FACE_TRACKER_TEXT := "Stop tracker"

var logger := Logger.new("OpenSeeFace")

# In theory we only need to receive data from tracker exactly FPS times per 
# second, because that is the number of times that data will be sent.
# However for low fps this will result in lagging behind, if the moment of 
# sending to receiving data is not very close to each other.
# As we limit the fps to 144, we can just poll every 1/144 seconds. At that
# FPS there should be no perceivable lag while still keeping the CPU usage
# at a low level when the receiver is started.
var server_poll_interval: float = 1.0 / MAX_TRACKER_FPS

var max_fit_3d_error: float = 100.0

var server := UDPServer.new()
var connection: PacketPeerUDP # Must be taken when running the server

var receive_thread: Thread # Must be created when starting tracking

var reception_counter: float = 0.0

var stop_reception := false
var is_tracking := false

var face_tracker_pid: int = -1

var data_map := {} # Face id: int -> OpenSeeFaceData

var _tree: SceneTree

var open_see_face_data: GDScript

#-----------------------------------------------------------------------------#
# Builtin functions                                                           #
#-----------------------------------------------------------------------------#

func _init() -> void:
	if AM.env.current_env != Env.Envs.TEST:
		AM.ps.subscribe(self, "event_published")

	_tree = Engine.get_main_loop()
	
	var res: Result = AM.em.get_extension("OpenSeeFace")
	if res.is_err():
		logger.error(res.to_string())
		return
	res = res.unwrap().context.load_resource("open_see_face_data.gd")
	if res.is_err():
		logger.error(res.to_string())
		return
	open_see_face_data = res.unwrap()

func _exit_tree() -> void:
	stop_receiver()

#-----------------------------------------------------------------------------#
# Connections                                                                 #
#-----------------------------------------------------------------------------#

func _on_event_published(payload: SignalPayload) -> void:
	if payload.signal_name != GlobalConstants.TRACKER_TOGGLED or payload.id != "OpenSeeFace":
		return
	
	var was_tracking: bool = is_tracking
	if not was_tracking:
		# Only makes sense to start receiver if tracker was started
		if _start_tracker():
			start_receiver()
			is_tracking = true
	else:
		# Always shutdown receiver and tracker
		stop_receiver()
		is_tracking = false

#-----------------------------------------------------------------------------#
# Private functions                                                           #
#-----------------------------------------------------------------------------#

func _start_tracker() -> bool:
	# If the tracker should be launched, launch it
	# Otherwise assume that the user launched a tracker manually already
	var should_launch = AM.cm.get_data("open_see_face_should_launch_tracker")
	if typeof(should_launch) == TYPE_NIL:
		logger.error("No data found for open_see_face_should_launch_tracker")
		return false

	var fps = AM.cm.get_data("open_see_face_tracker_fps")
	if typeof(fps) == TYPE_NIL:
		logger.error("No data found for open_see_face_tracker_fps")
		return false

	var address = AM.cm.get_data("open_see_face_address")
	if typeof(address) == TYPE_NIL:
		logger.error("No data found for open_see_face_address")
		return false

	var port = AM.cm.get_data("open_see_face_port")
	if typeof(port) == TYPE_NIL:
		logger.error("No data found for open_see_face_port")
		return false

	var camera_index = AM.cm.get_data("open_see_face_camera_index")
	if typeof(camera_index) == TYPE_NIL:
		logger.error("No data found for open_see_face_camera_index")
		return false
	
	if not should_launch:
		logger.info("Assuming face tracker was manually launched.")
		return true

	logger.info("Starting face tracker")
	
	if fps > MAX_TRACKER_FPS:
		logger.info("Face tracker fps is greater than %s. This is a bad idea." % MAX_TRACKER_FPS)
		logger.info("Declining to start face tracker.")
		return false

	var pid: int = -1

	match OS.get_name().to_lower():
		"windows":
			var exe_path: String = "%s/OpenSeeFaceFolder/OpenSeeFace/facetracker.exe" % \
				AM.em.get_context("OpenSeeFace").expect("Unable to get context").context_path
			pid = OS.execute(
				exe_path,
				[
					"-c", camera_index,
					"-F", str(fps),
					"-v", "0",
					"-s", "1",
					"-P", "1",
					"--discard-after", "0",
					"--scan-every", "0",
					"--no-3d-adapt", "1",
					"--max-feature-updates", "900",
					"--ip", address,
					"--port", str(port),
				],
				false
			)
		"osx", "x11":
			var user_data_path: String = ProjectSettings.globalize_path("user://")
			var python_path: String = AM.cm.get_data("python_path")
			if python_path == "*":
				python_path = ""

			var dir := Directory.new()
			if not dir.dir_exists("%s%s" % [user_data_path, "venv"]):
				# TODO add in logger popup notification
				# logger.notify("First time setup: creating venv", logger.NotifyType.POPUP)

				var create_venv_script: String = "%s%s" % [OS.get_executable_path().get_base_dir(), "/resources/scripts/create_venv.sh"]
				if OS.is_debug_build():
					create_venv_script = ProjectSettings.globalize_path("res://resources/scripts/create_venv.sh")
				
				# Give the popup time to actually popup/display
				yield(_tree, "idle_frame")
				yield(_tree, "idle_frame")

				OS.execute(create_venv_script, [python_path, user_data_path])

			var face_tracker_path: String = "/OpenSeeFaceFolder/OpenSeeFace/facetracker.py"

			# These paths must be absolute paths
			var exe_path: String = "%s%s" % [OS.get_executable_path().get_base_dir(), face_tracker_path]
			var script_path: String = "%s%s" % [OS.get_executable_path().get_base_dir(), "/resources/scripts/run_osf_linux.sh"]
			if OS.is_debug_build():
				exe_path = "%s%s" % [ProjectSettings.globalize_path("res://export"), face_tracker_path]
				script_path = ProjectSettings.globalize_path("res://resources/scripts/run_osf_linux.sh")

			pid = OS.execute(
				script_path,
				[
					user_data_path,
					exe_path,
					str(camera_index),
					str(fps),
					address,
					str(port)
				],
				false
			)
		_:
			logger.error("Unhandled os type: %s" % OS.get_name())
			return false

	if pid <= 0:
		logger.error("Failed to start tracker")
		return false

	face_tracker_pid = pid

	logger.info("Face tracker started, PID is %s." % face_tracker_pid)
	# TODO add in logger toast notification
	# logger.notify("Press spacebar to recenter the model if it's not looking correct!")

	return true

func _stop_tracker() -> void:
	logger.info("Stopping face tracker")

	if face_tracker_pid >= 0:
		match OS.get_name().to_lower():
			"windows":
				OS.kill(face_tracker_pid)
			"osx", "x11":
				# The bash script spawns a child process that does not get cleaned up by OS.kill()
				# Thus, we call pkill to kill the process group
				OS.execute("pkill", ["-15", "-P", face_tracker_pid])
			_:
				logger.info("Unhandled os type %s" % OS.get_name())
				return
		
		logger.info("Face tracker stopped, PID was %s." % face_tracker_pid)
		face_tracker_pid = -1
	else:
		logger.info("Tracker is not started")

func _receive() -> void:
	server.poll()
	if connection != null:
		var packet := connection.get_packet()
		if(packet.size() < 1 or packet.size() % PACKET_FRAME_SIZE != 0):
			return
		var offset: int = 0
		while offset < packet.size():
			var new_data = open_see_face_data.new()
			new_data.read_from_packet(packet, offset)
			data_map[new_data.id] = new_data
			offset += PACKET_FRAME_SIZE
		
		# tracking_data = open_see_data_map.values().duplicate(true)
	elif server.is_connection_available():
		connection = server.take_connection()

func _perform_reception() -> void:
	while not stop_reception:
		_receive()
		yield(_tree.create_timer(server_poll_interval), "timeout")

#-----------------------------------------------------------------------------#
# Public functions                                                            #
#-----------------------------------------------------------------------------#

func is_listening() -> bool:
	return is_tracking

func start_receiver() -> void:
	var address = AM.cm.get_data("open_see_face_address")
	if typeof(address) == TYPE_NIL:
		logger.error("No data found for open_see_face_address")
		return

	var port = AM.cm.get_data("open_see_face_port")
	if typeof(port) == TYPE_NIL:
		logger.error("No data found for open_see_face_port")
		return

	logger.info("Listening for data at %s:%d" % [address, port])

	server.listen(port, address)

	stop_reception = false

	receive_thread = Thread.new()
	receive_thread.start(self, "_perform_reception")

func stop_receiver() -> void:
	if stop_reception:
		return

	_stop_tracker()
	stop_reception = true

	if receive_thread != null and receive_thread.is_active():
		receive_thread.wait_to_finish()
	
	if server.is_listening():
		if connection != null and connection.is_connected_to_host():
			connection.close()
			connection = null
		server.stop()

func get_data(param = 0) -> TrackingDataInterface:
	return data_map.get(param, null)
