extends Node

var server := UDPServer.new()
var is_listening = false
var stop_reception: bool = false
var listen_port = 49983
var peers = []  # insert tracker IP here
var receive_thread: Thread = null
var tracking_data: Array = [] # OpenSeeData

const RUN_FACE_TRACKER_TEXT: String = "Start External Tracker"
const STOP_FACE_TRACKER_TEXT: String = "Stop External Tracker"

func _ready():
	if not ifm:
		ifm = iFacial.new()
	if not if_data_map:
		self.if_data_map = {}
	AppManager.sb.connect("start_external_tracker", self, "_on_start_tracker")

func _on_start_tracker():
	if not is_listening:
		print("Not Listening")
		AppManager.log_message("Starting face tracker.")
		

		is_listening = true
		stop_reception = false
		start_receiver()
	else:
		AppManager.sb.broadcast_update_label_text("Start External Tracker", RUN_FACE_TRACKER_TEXT)
		stop_receiver()
		

var ifm = iFacial.new()
var if_data_map: Dictionary = {}

class iFacial:
		# The time this tracking data was captured at
	var time: float
	# ID of the tracked face
	var id: int
	var camera_resolution: Vector2
	# How likely the given eye is open
	var right_eye_open: float
	var left_eye_open: float
	# Rotation of the given eyeball
	var right_gaze: Vector3
	var left_gaze: Vector3
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
	#var confidence = 60
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
	var features: iFacialFeatures = iFacialFeatures.new()
	class iFacialFeatures:
		var mouthSmile_R: float
		var eyeLookOut_L: float
		var mouthUpperUp_L: float
		var eyeWide_R: float
		var mouthClose: float
		var mouthPucker: float
		var mouthRollLower: float
		var eyeBlink_R: float
		var eyeLookDown_L: float
		var cheekSquint_R: float
		var eyeBlink_L: float
		var tongueOut: float
		var jawRight: float
		var eyeLookIn_R: float
		var cheekSquint_L: float
		var mouthDimple_L: float
		var mouthPress_L: float
		var eyeSquint_L: float
		var mouthRight: float
		var mouthShrugLower: float
		var eyeLookUp_R: float
		var eyeLookOut_R: float
		var mouthPress_R: float
		var cheekPuff: float
		var jawForward: float
		var mouthLowerDown_L: float
		var mouthFrown_L: float
		var mouthShrugUpper: float
		var browOuterUp_L: float
		var browInnerUp: float
		var mouthDimple_R: float
		var browDown_R: float
		var mouthUpperUp_R: float
		var mouthRollUpper: float
		var mouthFunnel: float
		var mouthStretch_R: float
		var mouthFrown_R: float
		var eyeLookDown_R: float
		var jawOpen: float
		var jawLeft: float
		var browDown_L: float
		var mouthSmile_L: float
		var noseSneer_R: float
		var mouthLowerDown_R: float
		var noseSneer_L: float
		var eyeWide_L: float
		var mouthStretch_L: float
		var browOuterUp_R: float
		var eyeLookIn_L: float
		var eyeSquint_R: float
		var eyeLookUp_L: float
		var mouth_open: float
		var mouthLeft: int
		var head: Array
		var rightEye: Array
		var leftEye: Array

	class iFInt:
		var i: float

		func _init(my_i: float) -> void:
			self.i = my_i
	
	func _init():
		#self.confidence = PoolRealArray()
		#confidence.resize(NUMBER_OF_POINTS)
		self.points = PoolVector2Array()
		#points.resize(NUMBER_OF_POINTS)
		self.points_3d = PoolVector3Array()
		#points_3d.resize(NUMBER_OF_POINTS + 2)
	
	func swap_x(v: Vector3) -> Vector3:
		v.x = -v.x
		return v
	
	func read_float(o) -> float:
		return o
	
	func read_quaternion(o: float) -> Quat:
		var x: float = read_float(o)
		var y: float = read_float(o)
		var z: float = read_float(o)
		var w: float = read_float(o)
		var q: Quat = Quat(x, y, z, -w)
		return q
	
	func read_vector3(o) -> Vector3:
		var v: Vector3 = Vector3(read_float(o), -read_float(o), read_float(o))
		return v
	
	func read_vector2(b: StreamPeerBuffer, o: iFInt) -> Vector2:
		var v: Vector2 = Vector2(read_float(o), read_float(o))
		return v		
		
	func read_from_packet(o: float) -> void:
		#var spb = StreamPeerBuffer.new()
		
		var opi: iFInt = iFInt.new(o)

		#self.camera_resolution = read_vector2(o)
		self.right_eye_open = read_float(o)
		self.left_eye_open = read_float(o)

		#var got_3d := b[opi.i]
		#opi.i += 1
		#self.got_3d_points = false

		#self.fit_3d_error = read_float(o)
		self.rotation
		# var converted_quaternion: Quat = Quat(-self.raw_quaternion.x, self.raw_quaternion.y, -self.raw_quaternion.z, self.raw_quaternion.w)
		self.raw_euler = self.rotation
		self.raw_quaternion = Quat(self.raw_euler)
		self.right_gaze = Vector3(features.rightEye[0],features.rightEye[1],features.rightEye[2])
		self.left_gaze = Vector3(features.leftEye[0],features.leftEye[1],features.leftEye[2])


##functions

func start_receiver():
	
	if not AppManager.is_face_tracking_disabled:
		AppManager.sb.broadcast_update_label_text("Start External Tracker", STOP_FACE_TRACKER_TEXT)
		AppManager.log_message("Listening for data at port %s" % listen_port)

		
		server.listen(listen_port)
		receive_thread = Thread.new()
		receive_thread.start(self, "_perform_reception")
	else:
		AppManager.log_message("Face tracking is disabled. This should only happen in debug builds.")
		AppManager.log_message("Check AppManager.gd for more information.")


func stop_receiver():
	is_listening = false
	stop_reception = true
	print("Stopping...")
	AppManager.sb.broadcast_update_label_text("Start External Tracker", RUN_FACE_TRACKER_TEXT)
	if (receive_thread and receive_thread.is_active()):
		receive_thread.wait_to_finish()
		
	if server.is_listening():
		server.stop()
var offset: int = 1
func _recieve_data():
	server.poll()
	if (server.is_connection_available()):
		var peer : PacketPeerUDP = server.take_connection()
		var pkt = peer.get_packet()
		#print("Accepted peer: %s:%s" % [peer.get_packet_ip(), peer.get_packet_port()])
		#print("Received data: %s" % [pkt.get_string_from_utf8()])

		var rawData = pkt.get_string_from_utf8()


		var raw_split = rawData.split("|")
		for data in raw_split:
			var split_data = data.split("-")
			if split_data.size() == 2:
				var key = split_data[0] # can use direct access instead of creating temp vars
				var value = split_data[1]
				#print([key, value])
				#print(ifm[key])
				#print(key, ": ", value)
				if_data_map[key] = value
				ifm.features.set(key, value)
				
				# Some keys don't use '-' for splitting?
			split_data = data.split("#")
			if split_data.size() == 2:
				var multipart_data = split_data[1].split(",")
				if multipart_data.size() == 3:
					var key = split_data[0] 
					var value: Array = multipart_data
					#print(value)
					ifm.features.set(key, value)
					if_data_map[key] = value
				if (split_data[0] == "=head"): #special case for head axis because =head
					var key = "head"
					var value: Array = multipart_data
					if_data_map[key] = value
					ifm.features.set(key, value)
					
					ifm.read_from_packet(offset)
					#if_data_map = ifm
					
		#tracking_data = if_data_map.values()
		#ifm s

func _perform_reception() -> void:
	while not stop_reception:
		_recieve_data()

func get_if_data():
	if not if_data_map:
		return null
	return ifm
