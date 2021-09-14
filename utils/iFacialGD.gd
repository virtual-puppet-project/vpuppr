extends Node

var server := UDPServer.new()
var is_listening = false
var stop_reception: bool = false
var listen_port = 49983
var peers = []  # insert tracker IP here
var receive_thread: Thread = null

const RUN_FACE_TRACKER_TEXT: String = "Start External Tracker"
const STOP_FACE_TRACKER_TEXT: String = "Stop External Tracker"

func _ready():
	AppManager.sb.connect("start_external_tracker", self, "_on_start_tracker")
	#

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
		

var ifm = {}
#var if_data: Dictionary

class iFacial:
	class features:
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

func start_receiver():
	if not AppManager.is_face_tracking_disabled:
		AppManager.sb.broadcast_update_label_text("Start External Tracker", STOP_FACE_TRACKER_TEXT)
		AppManager.log_message("Listening for data at port %s" % listen_port)

		server.listen(listen_port)
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

func _process(delta): #Parse Stream in realtime
	
	#print(server.is_connection_available())
	server.poll() # Important!
	#print(iFacial.features)
	if (server.is_connection_available() && is_listening):
		var peer : PacketPeerUDP = server.take_connection()
		var pkt = peer.get_packet()
		#print("Accepted peer: %s:%s" % [peer.get_packet_ip(), peer.get_packet_port()])
		#print("Received data: %s" % [pkt.get_string_from_utf8()])

		var rawData = pkt.get_string_from_utf8()

		#var ifm = iFacial.features.new()
		var raw_split = rawData.split("|")
		for data in raw_split:
			var split_data = data.split("-")
			if split_data.size() == 2:
				var key = split_data[0] # can use direct access instead of creating temp vars
				var value = split_data[1]
				#print([key, value])
				#print(ifm[key])
				#ifm.set(key, value)
				#print(key, ": ", value)
				ifm[key] = value
				continue
				
				# Some keys don't use '-' for splitting?
			split_data = data.split("#")
			if split_data.size() == 2:
				var multipart_data = split_data[1].split(",")
				if multipart_data.size() == 3:
					var key = split_data[0] 
					var value: Array = multipart_data
					#print(value)
					#ifm.set(key, value)
					ifm[key] = value
				if (split_data[0] == "=head"): #special case for head axis because =head
					var key = "head"
					var value: Array = multipart_data
					ifm[key] = value
					#ifm.set(key, value)
				return

	else:
		return

func get_if_data():
	return ifm

