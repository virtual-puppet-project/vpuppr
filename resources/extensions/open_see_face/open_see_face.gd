extends TrackingBackendTrait

class OSFData:
	const NUMBER_OF_POINTS: int = 68

	# The time this tracking data was captured at
	var time: float = -1.0
	# ID of the tracked face
	var id: int = -1
	var camera_resolution := Vector2.ZERO
	# How likely it is that the given eye is open
	var right_eye_open: float = -1.0
	var left_eye_open: float = -1.0
	# Rotation of the given eyeball
	var right_gaze := Quat.IDENTITY
	var left_gaze := Quat.IDENTITY
	# Tells you if the 3D points have been successfully estimated from the 2d points
	# If false, do not rely on pose or 3D data
	var got_3d_points := false
	# The error for fitting the original 3D points
	# Shouldn't matter much, but if it is very high, something is probably wrong
	var fit_3d_error: float = -1.0
	# Rotation vector for the 3D points to turn into the estimated face pose
	var rotation := Vector3.ZERO
	# Translation vector for the 3D points to turn into the estimated face pose
	var translation := Vector3.ZERO
	# Raw rotation quaternion calculated from the OpenCV rotation matrix
	var raw_quaternion := Quat.IDENTITY
	# Raw rotation euler angles calculated by OpenCV from the rotation matrix
	var raw_euler := Vector3.ZERO
	# How certain the tracker is
	var confidence := PoolRealArray()
	# The detected face landmarks in image coordinates
	# There are 60 points
	# The last 2 points are pupil points from the gaze tracker
	var points := PoolVector2Array()
	# 3D points estimated from the 2D points
	# They should be rotation and translation compensated
	# There are 70 points with guess for the eyeball center positions
	# being added at the end of 68 2D points
	var points_3d := PoolVector3Array()

	class Features:
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
	
	var features := Features.new()

	# We need to pass ints by reference
	class Integer:
		var i: int

		func _init(p_i: int) -> void:
			i = p_i

	func _init() -> void:
		confidence.resize(NUMBER_OF_POINTS)
		points.resize(NUMBER_OF_POINTS)
		points_3d.resize(NUMBER_OF_POINTS + 2)

	func _swap_x(v: Vector3) -> Vector3:
		v.x = -v.x
		return v
	
	func _read_float(b: StreamPeerBuffer, i: Integer) -> float:
		b.seek(i.i)
		var v := b.get_float()
		i.i += 4
		return v
	
	func _read_quaternion(b: StreamPeerBuffer, i: Integer) -> Quat:
		var x := _read_float(b, i)
		var y := _read_float(b, i)
		var z := _read_float(b, i)
		var w := _read_float(b, i)
		return Quat(x, y, z, w)
	
	func _read_vector3(b: StreamPeerBuffer, i: Integer) -> Vector3:
		# NOTE we invert the y value here
		# TODO we adjust the y value when loading models and always seem to negate it
		# Maybe we don't need to negate it here?
		return Vector3(_read_float(b, i), -_read_float(b, i), _read_float(b, i))
	
	func _read_vector2(b: StreamPeerBuffer, i: Integer) -> Vector2:
		return Vector2(_read_float(b, i), _read_float(b, i))

	func read_from_packet(b: PoolByteArray, regular_int: int) -> void:
		var spb := StreamPeerBuffer.new()
		spb.data_array = b
		var i := Integer.new(regular_int)
	
		spb.seek(i.i)
		time = spb.get_double()
		i.i += 8
	
		spb.seek(i.i)
		id = spb.get_32()
		i.i += 4
	
		camera_resolution = _read_vector2(spb, i)
		right_eye_open = _read_float(spb, i)
		left_eye_open = _read_float(spb, i)
	
		var got_3d := b[i.i]
		i.i += 1
		got_3d_points = false
		if got_3d != 0:
			got_3d_points = true
	
		fit_3d_error = _read_float(spb, i)
		raw_quaternion = _read_quaternion(spb, i)
		raw_euler = _read_vector3(spb, i)
	
		rotation = raw_euler
		# rotation.z = fmod(rotation.z - 90, 360)
		rotation.x = rotation.x if rotation.x > 0.0 else rotation.x + 360.0
	
		var x := _read_float(spb, i)
		var y := _read_float(spb, i)
		var z := _read_float(spb, i)
		
		translation = Vector3(-y, -x, -z)
	
		for point_idx in NUMBER_OF_POINTS:
			confidence.set(point_idx, _read_float(spb, i))
	
		for point_idx in NUMBER_OF_POINTS:
			points.set(point_idx, _read_vector2(spb, i))
	
		for point_idx in NUMBER_OF_POINTS + 2:
			points_3d.set(point_idx, _read_vector3(spb, i))
	
		# TODO im pretty sure this is kind of wrong
		right_gaze = Quat(Transform().looking_at(points_3d[66] - points_3d[68], Vector3.UP).basis).normalized()
		left_gaze = Quat(Transform().looking_at(points_3d[67] - points_3d[69], Vector3.UP).basis).normalized()
	
		features.eye_left = _read_float(spb, i)
		features.eye_right = _read_float(spb, i)
		features.eyebrow_steepness_left = _read_float(spb, i)
		features.eyebrow_up_down_left = _read_float(spb, i)
		features.eyebrow_quirk_left = _read_float(spb, i)
		features.eyebrow_steepness_right = _read_float(spb, i)
		features.eyebrow_up_down_right = _read_float(spb, i)
		features.eyebrow_quirk_right = _read_float(spb, i)
		features.mouth_corner_up_down_left = _read_float(spb, i)
		features.mouth_corner_in_out_left = _read_float(spb, i)
		features.mouth_corner_up_down_right = _read_float(spb, i)
		features.mouth_corner_in_out_right = _read_float(spb, i)
		features.mouth_open = _read_float(spb, i)
		features.mouth_wide = _read_float(spb, i)

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

var server: UDPServer
var connection: PacketPeerUDP # Must be taken when running the server

var receive_thread: Thread # Must be created when starting tracking

var reception_counter: float = 0.0
var stop_reception := false

var face_tracker_pid: int = -1

var data_map := {} # Face id: int -> OpenSeeFaceData

var updated_time: float = 0.0

#-----------------------------------------------------------------------------#
# Builtin functions                                                           #
#-----------------------------------------------------------------------------#

func _init() -> void:
	if _start_tracker():
		start_receiver()

#-----------------------------------------------------------------------------#
# Connections                                                                 #
#-----------------------------------------------------------------------------#

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

	# Settings could be messed up, so do this before anything else.
	if not should_launch:
		logger.info("Assuming face tracker was manually launched.")
		return true

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

	var ml_model = AM.cm.get_data("open_see_face_model")
	if typeof(ml_model) == TYPE_NIL:
		logger.error("No data found for open_see_face_model")
		return false
	
	logger.info("Starting face tracker")
	
	if fps > MAX_TRACKER_FPS:
		logger.info("Face tracker fps is greater than %s. This is a bad idea." % MAX_TRACKER_FPS)
		logger.info("Declining to start face tracker.")
		return false

	var res = Safely.wrap(AM.em.get_context("OpenSeeFace"))
	if res.is_err():
		logger.error(res)
		return false

	var context_path: String = res.unwrap()

	var pid: int = OS.execute(
		"%s/OpenSeeFaceFolder/OpenSeeFace/facetracker%s" % [
			context_path,
			".exe" if OS.get_name().to_lower() == "windows" else ""
		],
		[
			"--capture", camera_index,
			"--fps", str(fps),
			"--visualize", "0",
			"--silent", "1",
			"--pnp-points", "0",
			"--discard-after", "0",
			"--scan-every", "0",
			"--no-3d-adapt", "1",
			"--max-feature-updates", "900",
			"--ip", address,
			"--port", str(port),
			"--model", str(ml_model)
		],
		false
	)

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
			"windows", "osx", "x11":
				OS.kill(face_tracker_pid)
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
			var new_data = OSFData.new()
			new_data.read_from_packet(packet, offset)
			data_map[new_data.id] = new_data
			offset += PACKET_FRAME_SIZE
		
	elif server.is_connection_available():
		connection = server.take_connection()

func _perform_reception() -> void:
	while not stop_reception:
		_receive()
		yield(Engine.get_main_loop().create_timer(server_poll_interval), "timeout")

#-----------------------------------------------------------------------------#
# Public functions                                                            #
#-----------------------------------------------------------------------------#

func get_name() -> String:
	return "OpenSeeFace"

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

	server = UDPServer.new()
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
		receive_thread = null
	
	if server != null and server.is_listening():
		if connection != null and connection.is_connected_to_host():
			connection.close()
			connection = null
		server.stop()
		server = null

func set_offsets() -> void:
	var data: OSFData = data_map.get(0, null)
	if data == null:
		return

	stored_offsets.translation_offset = data.translation
	stored_offsets.rotation_offset = data.rotation
	stored_offsets.left_eye_gaze_offset = data.left_gaze.get_euler()
	stored_offsets.right_eye_gaze_offset = data.right_gaze.get_euler()

func has_data() -> bool:
	return not data_map.empty()

func apply(data: InterpolationData, _model: PuppetTrait) -> void:
	var osf_data: OSFData = data_map.get(0, null)
	if osf_data == null or osf_data.fit_3d_error > 100.0:
		return

	data.bone_translation.target_value = stored_offsets.translation_offset - osf_data.translation
	data.bone_rotation.target_value = stored_offsets.rotation_offset - osf_data.rotation

	data.left_gaze.target_value = stored_offsets.left_eye_gaze_offset - osf_data.left_gaze.get_euler()
	data.right_gaze.target_value = stored_offsets.right_eye_gaze_offset - osf_data.right_gaze.get_euler()

	data.left_blink.target_value = osf_data.left_eye_open
	data.right_blink.target_value = osf_data.right_eye_open

	data.mouth_open.target_value = osf_data.features.mouth_open
	data.mouth_wide.target_value = osf_data.features.mouth_wide
