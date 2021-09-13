extends Node
# iFacialMocap implementation for OSF-GD, incomplete
const NUMBER_OF_POINTS: int = 68
const PACKET_FRAME_SIZE: int = 69 #insert maximum size here, iFM sends full strings instead of raw data

# UDP server settings
var server: UDPServer = UDPServer.new()
export var listen_address: String = "127.0.0.1"
export var listen_port: int = 49983


#test data
var rawData: String = "mouthSmile_R-0|eyeLookOut_L-0|mouthUpperUp_L-11|eyeWide_R-0|mouthClose-8|mouthPucker-4|mouthRollLower-9|eyeBlink_R-7|eyeLookDown_L-17|cheekSquint_R-11|eyeBlink_L-7|tongueOut-0|jawRight-0|eyeLookIn_R-6|cheekSquint_L-11|mouthDimple_L-10|mouthPress_L-4|eyeSquint_L-11|mouthRight-0|mouthShrugLower-9|eyeLookUp_R-0|eyeLookOut_R-0|mouthPress_R-5|cheekPuff-2|jawForward-11|mouthLowerDown_L-9|mouthFrown_L-6|mouthShrugUpper-26|browOuterUp_L-4|browInnerUp-20|mouthDimple_R-10|browDown_R-0|mouthUpperUp_R-10|mouthRollUpper-8|mouthFunnel-12|mouthStretch_R-21|mouthFrown_R-13|eyeLookDown_R-17|jawOpen-12|jawLeft-0|browDown_L-0|mouthSmile_L-0|noseSneer_R-18|mouthLowerDown_R-8|noseSneer_L-21|eyeWide_L-0|mouthStretch_L-21|browOuterUp_R-4|eyeLookIn_L-4|eyeSquint_R-11|eyeLookUp_L-0|mouthLeft-1|=head#-21.488958,-6.038993,-6.6019735,-0.030653415,-0.10287084,-0.6584072|rightEye#6.0297494,2.4403017,0.25649446|leftEye#6.034903,-1.6660284,-0.17520553|"
var ifcData: PoolStringArray = rawData.split("|")

#TODO: Properly split the raw data into dictionaries, see more at https://www.ifacialmocap.com/for-developer/
func aaa(): #placeholder function 
	for data in ifcData:
		var chars = data.split("")
		# or take out the header and then split by properties
		var props = data.split("-")
		return props

class iFacial:
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
		var mouthLeft: int
		var head: Array
		var rightEye: Array
		var leftEye: Array
	class meta:
		var points: PoolVector2Array
		var points_3d: PoolVector3Array
		var sendDataVersion: String
	# Added so we can pass ints by reference
	class facialInt:
		var i: int
	
	func _init():
		self.points = PoolVector2Array()
		meta.points.resize(NUMBER_OF_POINTS)
		self.points_3d = PoolVector3Array()
		meta.points_3d.resize(NUMBER_OF_POINTS + 2)
	
	func swap_x(v: Vector3) -> Vector3:
		v.x = -v.x
		return v
	
	func read_float(b: StreamPeerBuffer, o: facialInt) -> float:
		b.seek(o.i)
		var v: float = b.get_float()
		o.i += 4
		return v
	func lookForward():
		#remove offsets when recieves iFacialMocap_lookForward packet
		return
	func read_quaternion(b: StreamPeerBuffer, o: facialInt) -> Quat:
		var x: float = read_float(b, o)
		var y: float = read_float(b, o)
		var z: float = read_float(b, o)
		var w: float = read_float(b, o)
		var q: Quat = Quat(x, y, z, w)
		return q
	
	func read_vector3(b: StreamPeerBuffer, o: facialInt) -> Vector3:
		var v: Vector3 = Vector3(read_float(b, o), -read_float(b, o), read_float(b, o))
		return v
	
	func read_vector2(b: StreamPeerBuffer, o: facialInt) -> Vector2:
		var v: Vector2 = Vector2(read_float(b, o), read_float(b, o))
		return v	
		
		
	func read_from_packet(b: PoolByteArray, o: int) -> void:
		var spb: StreamPeerBuffer = StreamPeerBuffer.new()
		spb.data_array = b
		var opi: facialInt = facialInt.new()
		
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
		#self.right_gaze = Quat(Transform().looking_at(points_3d[66] - points_3d[68], Vector3.UP).basis).normalized()
		# self.left_gaze = (Quat(points_3d[67] - points_3d[69]).normalized() * Quat(Vector3.RIGHT, 180) * Quat(Vector3.FORWARD, 180)).normalized()
		#self.left_gaze = Quat(Transform().looking_at(points_3d[67] - points_3d[69], Vector3.UP).basis).normalized()
		
		
		#todo: add actual mappings here
		self.features = iFacialFeatures.new()
		#eyeLookIn_L = read_float(spb, opi)
		#eyeLookIn_R = read_float(spb, opi)
		#features.eyebrow_steepness_left = read_float(spb, opi)
		#features.eyebrow_up_down_left = read_float(spb, opi)
		#features.eyebrow_quirk_left = read_float(spb, opi)
		#features.eyebrow_steepness_right = read_float(spb, opi)
		#features.eyebrow_up_down_right = read_float(spb, opi)
		#features.eyebrow_quirk_right = read_float(spb, opi)
		#features.mouth_corner_up_down_left = read_float(spb, opi)
		#features.mouth_corner_in_out_left = read_float(spb, opi)
		#features.mouth_corner_up_down_right = read_float(spb, opi)
		#features.mouth_corner_in_out_right = read_float(spb, opi)
		#features.mouth_open = read_float(spb, opi)
		#features.mouth_wide = read_float(spb, opi)
	
	
const RUN_FACE_TRACKER_TEXT: String = "Run tracker"
const STOP_FACE_TRACKER_TEXT: String = "Stop tracker"

var ifcMap: Dictionary # int: OpenSeeData
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
	if not ifcMap:
		self.ifcMap = {}
	# self.buffer = PoolByteArray()
	print(aaa())
	
	start_receiver()

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
		if face_tracker_fps.is_valid_float():
			if float(face_tracker_fps) > 144:
				AppManager.log_message("Face tracker fps is greater than 144. This is a bad idea.")
				AppManager.log_message("Declining to start face tracker.")
				return
			var pid: int = -1
			if pid <= 0:
				is_listening = false
				stop_reception = true
				AppManager.log_message("Failed to start tracker", true)
				return
			face_tracker_pid = pid
			AppManager.sb.broadcast_update_label_text("Start Tracker", STOP_FACE_TRACKER_TEXT)

			start_receiver()

			AppManager.main.model_display_screen.tracking_started()

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
			print("Accepted peer: %s:%s" % [peer.get_packet_ip(), peer.get_packet_port()])
			print("Received data: %s" % [packet.get_string_from_utf8()])
			print(packet.get_string_from_ascii())
			if(packet.size() < 1 or packet.size() % PACKET_FRAME_SIZE != 0):
				print_debug("packet size too small, continuing")
				continue
			# self.received_packets += 1
			var offset: int = 0
			while offset < packet.size():
				var new_data: iFacial = iFacial.new()
				new_data.read_from_packet(packet, offset)
				ifcMap[new_data.id] = new_data
				offset += PACKET_FRAME_SIZE
			
			ifcData = ifcMap.values().duplicate(true)

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

func get_open_see_data(face_id: int) -> iFacial:
	if not ifcMap:
		return null
	if not ifcMap.has(face_id):
		return null
	return ifcMap[face_id]
