extends Node

const NUMBER_OF_POINTS: int = 68
const PACKET_FRAME_SIZE: int = 8 + 4 + 2 * 4 + 2 * 4 + 1 + 4 + 3 * 4 + 3 * 4 + 4 * 4 + 4 * 68 + 4 * 2 * 68 + 4 * 3 * 70 + 4 * 14

const MAX_TRACKER_FPS: int = 144

# UDP server settings
var server: UDPServer = UDPServer.new()

var connection: PacketPeerUDP

# Tracking data
var tracking_data: Array = [] # OpenSeeData

# In theory we only need to receive data from tracker exactly FPS times per 
# second, because that is the number of times that data will be sent.
# However for low fps this will result in lagging behind, if the moment of 
# sending to receiving data is not very close to each other.
# As we limit the fps to 144, we can just poll every 1/144 seconds. At that
# FPS there should be no perceivable lag while still keeping the CPU usage
# at a low level when the receiver is started.
var server_poll_interval: float = 1.0/MAX_TRACKER_FPS

var max_fit_3d_error: float = 100.0

class OpenSeeData:
	# The time this tracking data was captured at
	var time: float
	# ID of the tracked face
	var id: int
	var camera_resolution: Vector2
	# How likely the given eye is open
	var right_eye_open: float
	var left_eye_open: float
	# Rotation of the given eyeball
	var right_gaze: Quat
	var left_gaze: Quat
	# Tells you if 3D points have been successfully estimated from the 2D points
	# If false, do not rely on pose or 3D Data
	var got_3d_points: bool
	# The error for fitting the original 3D points
	# Shouldn't matter much, but if it is very high, something is probably wrong
	var fit_3d_error: float
	# Rotation vector for the 3D points to turn into the estimated face pose
	var rotation: Vector3
	# Translation vector for the 3D points to turn into the estimated face pose
	var translation: Vector3
	# Raw rotation quaternion calculated from the OpenCV rotation matrix
	var raw_quaternion: Quat
	# Raw rotation euler angles calculated by OpenCV from the rotation matrix
	var raw_euler: Vector3
	# How certain the tracker is
	var confidence: PoolRealArray
	# The detected face landmarks in image coordinates
	# There are 60 points
	# The last 2 points are pupil points from the gaze tracker
	var points: PoolVector2Array
	# 3D points estimated from the 2D points
	# They should be rotation and translation compensated
	# There are 70 ponits with guesses for the eyeball center positions
	# being added at the end of the 68 2D points
	var points_3d: PoolVector3Array
	# The number of action unit-like features
	var features: OpenSeeFeatures

	class OpenSeeFeatures:
		var eye_left: float
		var eye_right: float
		
		var eyebrow_steepness_left: float
		var eyebrow_up_down_left: float
		var eyebrow_quirk_left: float
		
		var eyebrow_steepness_right: float
		var eyebrow_up_down_right: float
		var eyebrow_quirk_right: float

		var mouth_corner_up_down_left: float
		var mouth_corner_in_out_left: float

		var mouth_corner_up_down_right: float
		var mouth_corner_in_out_right: float

		var mouth_open: float
		var mouth_wide: float

	# Added so we can pass ints by reference
	class OpenSeeInt:
		var i: int

		func _init(my_i: int) -> void:
			self.i = my_i
	
	func _init():
		self.confidence = PoolRealArray()
		confidence.resize(NUMBER_OF_POINTS)
		self.points = PoolVector2Array()
		points.resize(NUMBER_OF_POINTS)
		self.points_3d = PoolVector3Array()
		points_3d.resize(NUMBER_OF_POINTS + 2)
	
	func swap_x(v: Vector3) -> Vector3:
		v.x = -v.x
		return v
	
	func read_float(b: StreamPeerBuffer, o: OpenSeeInt) -> float:
		b.seek(o.i)
		var v: float = b.get_float()
		o.i += 4
		return v
	
	func read_quaternion(b: StreamPeerBuffer, o: OpenSeeInt) -> Quat:
		var x: float = read_float(b, o)
		var y: float = read_float(b, o)
		var z: float = read_float(b, o)
		var w: float = read_float(b, o)
		var q: Quat = Quat(x, y, z, w)
		return q
	
	func read_vector3(b: StreamPeerBuffer, o: OpenSeeInt) -> Vector3:
		var v: Vector3 = Vector3(read_float(b, o), -read_float(b, o), read_float(b, o))
		return v
	
	func read_vector2(b: StreamPeerBuffer, o: OpenSeeInt) -> Vector2:
		var v: Vector2 = Vector2(read_float(b, o), read_float(b, o))
		return v

	func read_from_packet(b: PoolByteArray, o: int) -> void:
		var spb: StreamPeerBuffer = StreamPeerBuffer.new()
		spb.data_array = b
		var opi: OpenSeeInt = OpenSeeInt.new(o)
		
		spb.seek(opi.i)
		self.time = spb.get_double()
		opi.i += 8
		
		spb.seek(opi.i)
		self.id = spb.get_32()
		opi.i += 4

		self.camera_resolution = read_vector2(spb, opi)
		self.right_eye_open = read_float(spb, opi)
		self.left_eye_open = read_float(spb, opi)

		var got_3d := b[opi.i]
		opi.i += 1
		self.got_3d_points = false
		if got_3d != 0:
			self.got_3d_points = true

		self.fit_3d_error = read_float(spb, opi)
		self.raw_quaternion = read_quaternion(spb, opi)
		# var converted_quaternion: Quat = Quat(-self.raw_quaternion.x, self.raw_quaternion.y, -self.raw_quaternion.z, self.raw_quaternion.w)
		self.raw_euler = read_vector3(spb, opi)
		
		self.rotation = self.raw_euler
		self.rotation.z = fmod(self.rotation.z - 90, 360)
		self.rotation.x = -fmod(self.rotation.x + 180, 360)

		var x: float = read_float(spb, opi)
		var y: float = read_float(spb, opi)
		var z: float = read_float(spb, opi)
		# TODO this might be converting to Unity vector3?
		self.translation = Vector3(-y, x, -z)

		for i in range(NUMBER_OF_POINTS):
			self.confidence.set(i, read_float(spb, opi))

		for i in range(NUMBER_OF_POINTS):
			self.points.set(i, read_vector2(spb, opi))

		for i in range(NUMBER_OF_POINTS + 2):
			self.points_3d.set(i, read_vector3(spb, opi))

		# self.right_gaze = (Quat(points_3d[66] - points_3d[68]).normalized() * Quat(Vector3.RIGHT, 180) * Quat(Vector3.FORWARD, 180)).normalized()
		self.right_gaze = Quat(Transform().looking_at(points_3d[66] - points_3d[68], Vector3.UP).basis).normalized()
		# self.left_gaze = (Quat(points_3d[67] - points_3d[69]).normalized() * Quat(Vector3.RIGHT, 180) * Quat(Vector3.FORWARD, 180)).normalized()
		self.left_gaze = Quat(Transform().looking_at(points_3d[67] - points_3d[69], Vector3.UP).basis).normalized()

		self.features = OpenSeeFeatures.new()
		features.eye_left = read_float(spb, opi)
		features.eye_right = read_float(spb, opi)
		features.eyebrow_steepness_left = read_float(spb, opi)
		features.eyebrow_up_down_left = read_float(spb, opi)
		features.eyebrow_quirk_left = read_float(spb, opi)
		features.eyebrow_steepness_right = read_float(spb, opi)
		features.eyebrow_up_down_right = read_float(spb, opi)
		features.eyebrow_quirk_right = read_float(spb, opi)
		features.mouth_corner_up_down_left = read_float(spb, opi)
		features.mouth_corner_in_out_left = read_float(spb, opi)
		features.mouth_corner_up_down_right = read_float(spb, opi)
		features.mouth_corner_in_out_right = read_float(spb, opi)
		features.mouth_open = read_float(spb, opi)
		features.mouth_wide = read_float(spb, opi)

const RUN_FACE_TRACKER_TEXT: String = "Run tracker"
const STOP_FACE_TRACKER_TEXT: String = "Stop tracker"

var open_see_data_map: Dictionary # int: OpenSeeData
# var buffer: PoolByteArray
var receive_thread: Thread = Thread.new()
var stop_reception: bool = false

var is_tracking: bool = false

var face_tracker_pid: int

###############################################################################
# Builtin functions                                                           #
###############################################################################

func _ready() -> void:
	if not open_see_data_map:
		self.open_see_data_map = {}

	AppManager.sb.connect("toggle_tracker", self, "_on_toggle_tracker")

func _exit_tree() -> void:
	stop_receiver()

###############################################################################
# Connections                                                                 #
###############################################################################

func _on_toggle_tracker() -> void:
	var was_tracking: bool = is_tracking
	if not was_tracking:
		# only makes sense to start receiver if tracker was started
		if _start_tracker():
			start_receiver()
			is_tracking = true
	else:
		# always shutdown receiver and tracker
		stop_receiver()
		is_tracking = false

	if was_tracking != is_tracking:
		if is_tracking:
			AppManager.sb.broadcast_update_label_text("Start Tracker", STOP_FACE_TRACKER_TEXT)
			AppManager.main.model_display_screen.tracking_started()
		else:
			AppManager.sb.broadcast_update_label_text("Start Tracker", RUN_FACE_TRACKER_TEXT)
			AppManager.main.model_display_screen.tracking_stopped()
			

###############################################################################
# Private functions                                                           #
###############################################################################

func _start_tracker() -> bool:
	# if a tracker should be launched, launch it
	# otherwise assume that the user launched a tracker manually already
	if not AppManager.cm.current_model_config.tracker_should_launch:
		AppManager.logger.info("Assuming face tracker was manually launched.")
		return true

	AppManager.logger.info("Starting face tracker.")

	if AppManager.cm.current_model_config.tracker_fps > MAX_TRACKER_FPS:
		AppManager.logger.info("Face tracker fps is greater than %s. This is a bad idea." % MAX_TRACKER_FPS)
		AppManager.logger.info("Declining to start face tracker.")
		return false

	var face_tracker_options: PoolStringArray = [
		"-c",
		AppManager.cm.metadata_config.camera_index,
		"-F",
		str(AppManager.cm.current_model_config.tracker_fps),
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
		"900",
		"--ip",
		AppManager.cm.current_model_config.tracker_address,
		"--port",
		str(AppManager.cm.current_model_config.tracker_port),
	]
	var pid: int = -1
	match OS.get_name().to_lower():
		"windows":
			# TODO maybe make this configurable?
			# face_tracker_options.append_array(["-D", "-1"])
			var exe_path: String = "%s%s" % [OS.get_executable_path().get_base_dir(), "/OpenSeeFaceFolder/OpenSeeFace/facetracker.exe"]
			if OS.is_debug_build():
				exe_path = "%s%s" % [ProjectSettings.globalize_path("res://export"), "/OpenSeeFaceFolder/OpenSeeFace/facetracker.exe"]
				print(exe_path)
			pid = OS.execute(exe_path,
					face_tracker_options, false, [], true)
		"osx", "x11":
			var user_data_path: String = ProjectSettings.globalize_path("user://")

			var dir := Directory.new()
			if not dir.dir_exists("%s%s" % [user_data_path, "venv"]):
				var popup = load("res://screens/gui/EphemeralPopup.tscn").instance()
				popup.popup_text = "First time setup: creating venv"
				get_tree().root.add_child(popup)

				var create_venv_script: String = "%s%s" % [OS.get_executable_path().get_base_dir(), "/resources/scripts/create_venv.sh"]
				if OS.is_debug_build():
					create_venv_script = ProjectSettings.globalize_path("res://resources/scripts/create_venv.sh")
				
				yield(get_tree(), "idle_frame")
				yield(get_tree(), "idle_frame")

				OS.execute(create_venv_script, [user_data_path])

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
					AppManager.cm.metadata_config.camera_index,
					str(AppManager.cm.current_model_config.tracker_fps),
					AppManager.cm.current_model_config.tracker_address,
					str(AppManager.cm.current_model_config.tracker_port)
				],
				false
			)
		_:
			AppManager.logger.error("Unhandled os type %s" % OS.get_name())
			return false
	
	if pid <= 0:
		AppManager.logger.error("Failed to start tracker")
		return false

	face_tracker_pid = pid

	AppManager.logger.info("Face tracker started, PID is %s." % face_tracker_pid)
	return true

func _stop_tracker() -> void:
	AppManager.logger.info("Stopping face tracker.")
	if face_tracker_pid:
		match OS.get_name().to_lower():
			"windows":
				OS.kill(face_tracker_pid)
			"osx", "x11":
				# The bash script spawns a child process that does not get cleaned up by OS.kill()
				# Thus, we call pkill to kill the process group
				OS.execute("pkill", ["-15", "-P", face_tracker_pid])
			_:
				AppManager.logger.error("Unhandled os type %s" % OS.get_name())
				return
		AppManager.logger.info("Face tracker stopped, PID was %s." % face_tracker_pid)
		face_tracker_pid = 0
	else:
		AppManager.logger.info("No tracker started.")

func _receive() -> void:
	#warning-ignore:return_value_discarded
	server.poll()
	if connection != null:
		var packet := connection.get_packet()
		if(packet.size() < 1 or packet.size() % PACKET_FRAME_SIZE != 0):
			return
		var offset: int = 0
		while offset < packet.size():
			var new_data: OpenSeeData = OpenSeeData.new()
			new_data.read_from_packet(packet, offset)
			open_see_data_map[new_data.id] = new_data
			offset += PACKET_FRAME_SIZE
		
		tracking_data = open_see_data_map.values().duplicate(true)
	elif server.is_connection_available():
		connection = server.take_connection()

func _perform_reception() -> void:
	while not stop_reception:
		_receive()
		yield(get_tree().create_timer(server_poll_interval), "timeout")

###############################################################################
# Public functions                                                            #
###############################################################################

func start_receiver() -> void:
	var listen_address: String = AppManager.cm.current_model_config.tracker_address
	var listen_port: int = AppManager.cm.current_model_config.tracker_port
	
	AppManager.logger.info("Listening for data at %s:%s" % [listen_address, str(listen_port)])

	server.listen(listen_port, listen_address)
	
	stop_reception = false

	receive_thread.start(self, "_perform_reception")

func stop_receiver() -> void:
	if stop_reception:
		return
	
	_stop_tracker()
	stop_reception = true

	if receive_thread.is_active():
		receive_thread.wait_to_finish()
	if server.is_listening():
		if (connection != null and connection.is_connected_to_host()):
			connection.close()
			connection = null
		server.stop()

func get_open_see_data(face_id: int) -> OpenSeeData:
	if not open_see_data_map:
		return null
	if not open_see_data_map.has(face_id):
		return null
	return open_see_data_map[face_id]
