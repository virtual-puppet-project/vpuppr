extends TrackingBackendInterface

## Reference: https://www.ifacialmocap.com/for-developer/
##
## Example
## Notes
## - keys are not ordered
## - newlines are inserted for readability
##
## eyeLookIn_R-54|noseSneer_L-5|mouthPress_L-8|mouthSmile_R-4|mouthLowerDown_L-1|mouthSmile_L-1|eyeWide_L-26|
## mouthRollUpper-1|mouthPucker-3|browOuterUp_L-3|mouthDimple_R-3|mouthShrugLower-21|mouthLeft-0|eyeLookUp_R-0|
## mouthFunnel-1|mouthDimple_L-3|mouthUpperUp_R-2|noseSneer_R-6|eyeSquint_R-3|jawForward-2|mouthClose-2|
## mouthFrown_L-0|mouthShrugUpper-15|eyeSquint_L-3|cheekSquint_L-3|eyeLookDown_L-16|mouthLowerDown_R-1|
## eyeLookOut_R-0|jawLeft-0|mouthStretch_L-5|cheekPuff-3|eyeLookUp_L-0|eyeBlink_R-0|jawOpen-2|mouthRollLower-5|
## browInnerUp-4|browOuterUp_R-3|mouthFrown_R-0|mouthStretch_R-5|eyeLookIn_L-0|tongueOut-0|eyeBlink_L-0|
## browDown_L-0|eyeWide_R-26|eyeLookDown_R-16|mouthUpperUp_L-2|cheekSquint_R-3|mouthPress_R-8|browDown_R-0|
## jawRight-0|mouthRight-2|eyeLookOut_L-44|hapihapi-0|=head#-1.6704091,-7.3032465,2.886358,0.084120944,
## 0.03458406,-0.4721467|rightEye#5.3555145,19.067966,1.8478252|leftEye#5.5607924,15.616646,1.5515244|

# TODO Check if these can be ints or not
## Data from an ifm packet. Variables are defined and named in the order they are encounted in the packet
class IFacialMocapData:
	var blend_shapes := {}
	
	var head_rotation := Vector3.ZERO
	var head_position := Vector3.ZERO
	
	var left_eye_rotation := Vector3.ZERO
	var right_eye_rotation := Vector3.ZERO
	
	## Set the blendshape to a value from 0.0-1.0
	##
	## @param: name: String - The name of the blendshape
	## @param: value: String - The value of the blendshape as a String from 0-100
	func set_blend_shape(name: String, value: String) -> void:
		blend_shapes[name] = value.to_float() / 100.0
	
	func set_head_rotation(x: String, y: String, z: String) -> void:
		head_rotation.x = -x.to_float()
		head_rotation.y = -y.to_float()
		head_rotation.z = z.to_float()
	
	func set_head_position(x: String, y: String, z: String) -> void:
		head_position.x = x.to_float()
		head_position.y = y.to_float()
		head_position.z = z.to_float()
	
	func set_left_eye_rotation(x: String, y: String, z: String) -> void:
		left_eye_rotation.x = x.to_float() / 100.0
		left_eye_rotation.y = y.to_float() / 100.0
		left_eye_rotation.z = z.to_float() / 100.0
	
	func set_right_eye_rotation(x: String, y: String, z: String) -> void:
		right_eye_rotation.x = x.to_float() / 100.0
		right_eye_rotation.y = y.to_float() / 100.0
		right_eye_rotation.z = z.to_float() / 100.0
var ifm_data := IFacialMocapData.new()

const ConfigKeys := {
	"ADDRESS": "i_facial_mocap_address",
	"PORT": "i_facial_mocap_port"
}

const INIT_STRING := "iFacialMocap_sahuasouryya9218sauhuiayeta91555dy3719|sendDataVersion=v2"

const HEAD_PACKET_ID := "=head#"
const RIGHT_EYE_ID := "rightEye#"
const LEFT_EYE_ID := "leftEye#"
# TODO change this to " & " when you figure out how to send packets to ifm
const BLENDSHAPE_DELIMITER := "-"

const PACKET_SIZE: int = 2048

var logger := Logger.new("iFacialMocap")

var server: UDPServer
var connection: PacketPeerUDP
var server_poll_interval: float = 1.0 / 144.0

var stop_reception := false

var receive_thread: Thread

#-----------------------------------------------------------------------------#
# Builtin functions                                                           #
#-----------------------------------------------------------------------------#

func _init() -> void:
	start_receiver()

#-----------------------------------------------------------------------------#
# Connections                                                                 #
#-----------------------------------------------------------------------------#

#-----------------------------------------------------------------------------#
# Private functions                                                           #
#-----------------------------------------------------------------------------#

func _perform_reception() -> void:
	while not stop_reception:
		_receive()
		yield(Engine.get_main_loop().create_timer(server_poll_interval), "timeout")

func _receive() -> void:
	server.poll()
	if connection != null:
		var packet := connection.get_packet()
		if packet.size() < 1:
			return
		
		var split := packet.get_string_from_utf8().split("|")
		for pair in split:
			if pair.begins_with(HEAD_PACKET_ID): # XYZ euler angles in degress, XYZ positions
				var data: PoolStringArray = pair.trim_prefix(HEAD_PACKET_ID).split(",", 5)
				if data.size() < 6:
					logger.error("Invalid ifm head data received")
					continue
				
				ifm_data.set_head_rotation(data[0], data[1], data[2])
				ifm_data.set_head_position(data[3], data[4], data[5])
			elif pair.begins_with(RIGHT_EYE_ID): # XYZ euler angles in degrees
				var data: PoolStringArray = pair.trim_prefix(RIGHT_EYE_ID).split(",", 2)
				if data.size() < 3:
					logger.error("Invalid ifm rightEye data received")
					continue
				
				ifm_data.set_right_eye_rotation(data[0], data[1], data[2])
			elif pair.begins_with(LEFT_EYE_ID): # XYZ euler angles in degrees
				var data: PoolStringArray = pair.trim_prefix(LEFT_EYE_ID).split(",", 2)
				if data.size() < 3:
					logger.error("Invalid ifm leftEye data received")
					continue
				
				ifm_data.set_left_eye_rotation(data[0], data[1], data[2])
			else: # BlendShape Name-Parameters (0 - 100)
				var data: PoolStringArray = pair.split(BLENDSHAPE_DELIMITER) # TODO change this once we get v2 data
				if data.size() < 2:
					continue
				
				ifm_data.set_blend_shape(data[0], data[1])
	elif server.is_connection_available():
		logger.info("Taking connection")
		connection = server.take_connection()
		
		# TODO this is not working for some reason
		# connection.put_packet(INIT_STRING.to_utf8())

#-----------------------------------------------------------------------------#
# Public functions                                                            #
#-----------------------------------------------------------------------------#

func get_name() -> String:
	return "iFacialMocap"

func start_receiver() -> void:
	var address = AM.cm.get_data(ConfigKeys.ADDRESS)
	if typeof(address) == TYPE_NIL:
		logger.error("No data found for %s" % ConfigKeys.ADDRESS)
		return

	var port = AM.cm.get_data(ConfigKeys.PORT)
	if typeof(port) == TYPE_NIL:
		logger.error("No data found for %s" % ConfigKeys.PORT)
		return

	logger.info("Listening for data at %s:%d" % [address, port])
	logger.info(IP.resolve_hostname(OS.get_environment("COMPUTER_NAME"), 1))

	server = UDPServer.new()
	server.listen(port, address)

	stop_reception = false

	receive_thread = Thread.new()
	receive_thread.start(self, "_perform_reception")

func stop_receiver() -> void:
	if stop_reception:
		return

	logger.info("Stopping face tracker")

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

func set_offsets(offsets: StoredOffsets) -> void:
	offsets.translation_offset = ifm_data.head_position
	offsets.rotation_offset = ifm_data.head_rotation
	offsets.left_eye_gaze_offset = ifm_data.left_eye_rotation
	offsets.right_eye_gaze_offset = ifm_data.right_eye_rotation

func apply(_model: PuppetTrait, interpolation_data: InterpolationData, _extra: Dictionary) -> void:
	interpolation_data.bone_translation.target_value = ifm_data.head_position
	interpolation_data.bone_rotation.target_value = ifm_data.head_rotation
	
	interpolation_data.left_gaze.target_value = ifm_data.left_eye_rotation
	interpolation_data.right_gaze.target_value = ifm_data.right_eye_rotation

	interpolation_data.left_blink.target_value = 1.0 - ifm_data.blend_shapes.get("eyeBlink_R", 0.0)
	interpolation_data.right_blink.target_value = 1.0 - ifm_data.blend_shapes.get("eyeBlink_L", 0.0)

	# TODO figure out which to use: mouthClose/jawOpen
	# jawOpen seems to correspond to the correct values, but then
	# what does mouthClose refer to?
	interpolation_data.mouth_open.target_value = ifm_data.blend_shapes.get("jawOpen", 1.0)
	interpolation_data.mouth_wide.target_value = \
		ifm_data.blend_shapes.get("mouthLeft", 0.0) + ifm_data.blend_shapes.get("mouthRight", 0.0)
