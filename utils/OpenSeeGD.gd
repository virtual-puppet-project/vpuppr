extends Node

const NUMBER_OF_POINTS: int = 68
const PACKET_FRAME_SIZE: int = 8 + 4 + 2 * 4 + 2 * 4 + 1 + 4 + 3 * 4 + 3 * 4 + 4 * 4 + 4 * 68 + 4 * 2 * 68 + 4 * 3 * 70 + 4 * 14

# UDP server settings
var server: UDPServer = UDPServer.new()
export var listen_address: String = "127.0.0.1"
export var listen_port: int = 11573

# Tracking data
# var received_packets: int = 0
var tracking_data: Array = [] # OpenSeeData

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
# TODO this might be unity specific?
# var socket
# var buffer: PoolByteArray
var receive_thread: Thread = null
var stop_reception: bool = false

var is_listening := false

var face_tracker_fps: String = "12"
var face_tracker_pid: int

###############################################################################
# Builtin functions                                                           #
###############################################################################

func _ready() -> void:
	if not open_see_data_map:
		self.open_see_data_map = {}
	# self.buffer = PoolByteArray()
	
	# start_receiver()

	AppManager.sb.connect("start_tracker", self, "_on_start_tracker")

#func _process(_delta: float) -> void:
#	if(receive_thread and not receive_thread.is_active()):
#		self._ready()

func _exit_tree() -> void:
	stop_receiver()

###############################################################################
# Connections                                                                 #
###############################################################################

func _on_start_tracker() -> void:
	if not is_listening:
		AppManager.log_message("Starting face tracker.")

		is_listening = true
		stop_reception = false

		# var face_tracker_fps: String = $Control/MarginContainer/VBoxContainer/MiddleColorRect/HBoxContainer/InputLabel/HBoxContainer/FaceTrackerFPS.text
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
			var pid: int = -1
			match OS.get_name().to_lower():
				"windows":
					pid = OS.execute(OS.get_executable_path().get_base_dir() + "/OpenSeeFaceFolder/OpenSeeFace/facetracker.exe",
							face_tracker_options, false, [], true)
				"osx", "x11":
					var modified_options := PoolStringArray(["./OpenSeeFace/facetracker.py"])
					modified_options.append_array(face_tracker_options)

					var python_alias: String = ""
					
					var shell_output: Array = []

					OS.execute("command -v python3", [], true, shell_output)
					if not shell_output.empty():
						python_alias = "python3"
					else:
						OS.execute("command -v python", [], true, shell_output)
						if not shell_output.empty():
							python_alias = "python"
					
					if python_alias.empty():
						AppManager.log_message("Unable to find python executable")
						return
					
					pid = OS.execute("%s %s/facetracker.py" % [python_alias, OS.get_executable_path().get_base_dir()], face_tracker_options,
							false, [], true)
				_:
					AppManager.log_message("Unhandled os type %s" % OS.get_name(), true)
					return
			
			if pid <= 0:
				is_listening = false
				stop_reception = true
				AppManager.log_message("Failed to start tracker", true)
				return
			face_tracker_pid = pid
			AppManager.sb.broadcast_update_label_text("Start Tracker", STOP_FACE_TRACKER_TEXT)

			start_receiver()

			AppManager.log_message("Face tracker started.")
	else:
		AppManager.log_message("Stopping face tracker.")

		is_listening = false
		stop_reception = true
		
		stop_receiver()
		
		OS.kill(face_tracker_pid)
		AppManager.sb.broadcast_update_label_text("Start Tracker", RUN_FACE_TRACKER_TEXT)

		AppManager.log_message("Face tracker stopped.")
	pass

###############################################################################
# Private functions                                                           #
###############################################################################

func _perform_reception() -> void:
	while not stop_reception:
		#warning-ignore:return_value_discarded
		server.poll()
		if server.is_connection_available():
			var peer: PacketPeerUDP = server.take_connection()
			var packet := peer.get_packet()
			# print("Accepted peer: %s:%s" % [peer.get_packet_ip(), peer.get_packet_port()])
			# print("Received data: %s" % [packet.get_string_from_utf8()])
			# print(packet.get_string_from_ascii())
			if(packet.size() < 1 or packet.size() % PACKET_FRAME_SIZE != 0):
				print_debug("packet size too small, continuing")
				continue
			# self.received_packets += 1
			var offset: int = 0
			while offset < packet.size():
				var new_data: OpenSeeData = OpenSeeData.new()
				new_data.read_from_packet(packet, offset)
				open_see_data_map[new_data.id] = new_data
				offset += PACKET_FRAME_SIZE
			
			tracking_data = open_see_data_map.values().duplicate(true)

###############################################################################
# Public functions                                                            #
###############################################################################

func start_receiver() -> void:
	if not AppManager.is_face_tracking_disabled:
		AppManager.log_message("Listening for data at %s:%s" % [listen_address, str(listen_port)])

		server.listen(listen_port, listen_address)

		receive_thread = Thread.new()
		
		receive_thread.start(self, "_perform_reception")
	else:
		AppManager.log_message("Face tracking is disabled. This should only happen in debug builds.")
		AppManager.log_message("Check AppManager.gd for more information.")

func stop_receiver() -> void:
	if (receive_thread and receive_thread.is_active()):
		receive_thread.wait_to_finish()
	if server.is_listening():
		server.stop()

func get_open_see_data(face_id: int) -> OpenSeeData:
	if not open_see_data_map:
		return null
	if not open_see_data_map.has(face_id):
		return null
	return open_see_data_map[face_id]
