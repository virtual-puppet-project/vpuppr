# server.gd
extends Node

var server := UDPServer.new()
var peers = []
var tracking_data = {}
var tracking = true
func _ready():
	server.listen(49983)
	
class iFacial:
	#var features = tracking_data
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

func _process(delta):
	server.poll() # Important!
	while server.is_connection_available():
		var peer : PacketPeerUDP = server.take_connection()
		var pkt = peer.get_packet()
		print("Accepted peer: %s:%s" % [peer.get_packet_ip(), peer.get_packet_port()])
		#print("Received data: %s" % [pkt.get_string_from_utf8()])
		
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
				tracking_data[key] = value # Add "Blue" as a key and assign 150 as its value.
				#print(tracking_data)
				
		
		print(tracking_data)
		# Reply so it knows we received the message.
		peer.put_packet(pkt)
		# Keep a reference so we can keep contacting the remote peer.
		peers.append(peer)
		

	for i in range(0, peers.size()):
		#print(tracking_data)
		pass # Do something with the connected peers.
