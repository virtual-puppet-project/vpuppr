class_name OpenSeeGD
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

var listening: bool = false

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

		self.right_gaze = Quat(Transform.looking_at(swap_x(points_3d[66]) - swap_x(points_3d[68]), Vector3.UP).origin) * Quat(Vector3.RIGHT, 180) * Quat(Vector3.FORWARD, 180)
		self.left_gaze = Quat(Transform.looking_at(swap_x(points_3d[67]) - swap_x(points_3d[69]), Vector3.UP).origin) * Quat(Vector3.RIGHT, 180) * Quat(Vector3.FORWARD, 180)

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

var open_see_data_map: Dictionary # int: OpenSeeData
# TODO add type, not sure what kind of socket this is
# var socket
var buffer: PoolByteArray
var receive_thread: Thread = null
var stop_reception: bool = false

###############################################################################
# Builtin functions                                                           #
###############################################################################

func _ready() -> void:
	if not open_see_data_map:
		self.open_see_data_map = {}
	self.buffer = PoolByteArray()
	
	# start_receiver()

func _process(_delta: float) -> void:
	if(receive_thread and not receive_thread.is_active()):
		self._ready()

func _exit_tree() -> void:
	stop_receiver()

###############################################################################
# Connections                                                                 #
###############################################################################

###############################################################################
# Private functions                                                           #
###############################################################################

func _perform_reception(_x) -> void:
	self.listening = true
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
			# TODO maybe doesn't need to be cleared?
			tracking_data = []
			tracking_data = open_see_data_map.values().duplicate(true)

###############################################################################
# Public functions                                                            #
###############################################################################

func start_receiver() -> void:
	if not AppManager.is_face_tracking_disabled:
		AppManager.log_message("Listening for data at %s:%s" % [listen_address, str(listen_port)])
		#warning-ignore:return_value_discarded
		server.listen(listen_port, listen_address)

		receive_thread = Thread.new()
		#warning-ignore:return_value_discarded
		receive_thread.start(self, "_perform_reception")
	else:
		AppManager.log_message("Face tracking is disabled. This should only happen in debug builds.")
		AppManager.log_message("Check AppManager.gd for more information.")

func stop_receiver() -> void:
	if receive_thread:
		self.stop_reception = true
		receive_thread.wait_to_finish()
	if server.is_listening():
		server.stop()

func is_server_listening() -> bool:
	if server.is_listening():
		return true
	return false

func get_open_see_data(face_id: int) -> OpenSeeData:
	if not open_see_data_map:
		return null
	if not open_see_data_map.has(face_id):
		return null
	return open_see_data_map[face_id]
