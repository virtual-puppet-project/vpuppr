extends Node

var server := UDPServer.new()
var peers = []
var tracking_data = {
	mouthSmile_R = 0,
	eyeLookOut_L = 0,
	mouthUpperUp_L = 0,
	eyeWide_R = 0,
	mouthClose = 0,
	mouthPucker = 0,
	mouthRollLower = 0,
	eyeBlink_R = 0,
	eyeLookDown_L = 0,
	cheekSquint_R = 0,
	eyeBlink_L = 0,
	tongueOut = 0,
	jawRight = 0,
	eyeLookIn_R = 0,
	cheekSquint_L = 0,
	mouthDimple_L = 0,
	mouthPress_L = 0,
	eyeSquint_L = 0,
	mouthRight = 0,
	mouthShrugLower = 0,
	eyeLookUp_R = 0,
	eyeLookOut_R = 0,
	mouthPress_R = 0,
	cheekPuff = 0,
	jawForward = 0,
	mouthLowerDown_L = 0,
	mouthFrown_L = 0,
	mouthShrugUpper = 0,
	browOuterUp_L = 0,
	browInnerUp = 0,
	mouthDimple_R = 0,
	browDown_R = 0,
	mouthUpperUp_R = 0,
	mouthRollUpper = 0,
	mouthFunnel = 0,
	mouthStretch_R = 0,
	mouthFrown_R = 0,
	eyeLookDown_R = 0,
	jawOpen = 0,
	jawLeft = 0,
	browDown_L = 0,
	mouthSmile_L = 0,
	noseSneer_R = 0,
	mouthLowerDown_R = 0,
	noseSneer_L = 0,
	eyeWide_L = 0,
	mouthStretch_L = 0,
	browOuterUp_R = 0,
	eyeLookIn_L = 0,
	eyeSquint_R = 0,
	eyeLookUp_L = 0,
	mouthLeft = 0,
	head = [0,0,0],
	rightEye = [0,0,0],
	leftEye = [0,0,0],
}
var tracking = true
var listen_port = 49983
func _ready():
	server.listen(listen_port)
	
class iFacial:
	#var features = tracking_data
	class features:
		var data = {}
		var mouthSmile_R  
		var eyeLookOut_L
		var mouthUpperUp_L
		var eyeWide_R
		var mouthClose
		var mouthPucker
		var mouthRollLower
		var eyeBlink_R
		var eyeLookDown_L
		var cheekSquint_R
		var eyeBlink_L
		var tongueOut
		var jawRight
		var eyeLookIn_R
		var cheekSquint_L
		var mouthDimple_L
		var mouthPress_L
		var eyeSquint_L
		var mouthRight
		var mouthShrugLower
		var eyeLookUp_R
		var eyeLookOut_R
		var mouthPress_R
		var cheekPuff
		var jawForward
		var mouthLowerDown_L
		var mouthFrown_L
		var mouthShrugUpper
		var browOuterUp_L
		var browInnerUp
		var mouthDimple_R
		var browDown_R
		var mouthUpperUp_R
		var mouthRollUpper
		var mouthFunnel
		var mouthStretch_R
		var mouthFrown_R
		var eyeLookDown_R
		var jawOpen
		var jawLeft
		var browDown_L
		var mouthSmile_L
		var noseSneer_R
		var mouthLowerDown_R
		var noseSneer_L
		var eyeWide_L
		var mouthStretch_L
		var browOuterUp_R 
		var eyeLookIn_L
		var eyeSquint_R
		var eyeLookUp_L
		var mouthLeft: int
		var head: Array
		var rightEye: Array
		var leftEye: Array

func _process(_delta):
	server.poll() # Important!
	if(server.is_connection_available() && tracking == true):
		var peer : PacketPeerUDP = server.take_connection()
		var pkt = peer.get_packet()
		#print("Accepted peer: %s:%s" % [peer.get_packet_ip(), peer.get_packet_port()])
		print("Received data: %s" % [pkt.get_string_from_utf8()])
		
		var rawData = pkt.get_string_from_utf8()
		
		
		
		var raw_split = rawData.split("|")
		for data in raw_split:
			var split_data = data.split("-")
			if split_data.size() == 2:
				var key = split_data[0] # can use direct access instead of creating temp vars
				var value = split_data[1]
				
				# Some keys don't use '-' for splitting?
				split_data = data.split("#")
				if split_data.size() == 2:
					var multipart_data = split_data[1].split(",")
					if multipart_data.size() == 3:
						var val_0: Array = multipart_data[0]
						print(val_0)
						print(key + ": " + value)
						tracking_data[key] = val_0
						tracking_data[key] = val_0
				print(tracking_data)
				return
			return
		
		
		# Reply so it knows we received the message.
		peer.put_packet(pkt)
		# Keep a reference so we can keep contacting the remote peer.
		peers.append(peer)
		

