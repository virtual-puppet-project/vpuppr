class_name IFacialMocap
extends AbstractTracker

var _logger := Logger.create("iFacialMocap")

var _socket: PacketPeerUDP = null
var _thread: Thread = null
var _should_stop := true

#-----------------------------------------------------------------------------#
# Builtin functions
#-----------------------------------------------------------------------------#

#-----------------------------------------------------------------------------#
# Private functions
#-----------------------------------------------------------------------------#

#-----------------------------------------------------------------------------#
# Public functions
#-----------------------------------------------------------------------------#

static func get_name() -> StringName:
	return &"iFacialMocap"

static func start(data: Dictionary) -> AbstractTracker:
	var r := IFacialMocap.new()
	
	if not data.has("port"):
		r._logger.error("Missing port")
		return null
	
	var port: int = data["port"]
	
	var socket := PacketPeerUDP.new()
	socket.bind(port)
	
	r._socket = socket
	
	r._logger.info("Starting iFacialMocap")
	
	r._should_stop = false
	
	r._thread = Thread.new()
	r._thread.start(func() -> void:
		while not r._should_stop:
			OS.delay_msec(10)
			
			if r._socket.get_available_packet_count() < 1:
				continue
			
			var packet := r._socket.get_packet()
			if packet.size() < 1:
				continue
			
			var result := {}
			var split_data := packet.get_string_from_utf8().split("|")
			for pair in split_data:
				if pair.begins_with("=head#"):
					var split_pair := pair.trim_prefix("=head#").split(",")
					if split_pair.size() != 6:
						continue
					
					result["rotation"] = Vector3(
						split_pair[0].to_float(),
						split_pair[1].to_float(),
						split_pair[2].to_float()
					)
					result["position"] = Vector3(
						split_pair[3].to_float(),
						split_pair[4].to_float(),
						split_pair[5].to_float()
					)
				elif pair.begins_with("rightEye#"):
					var split_pair := pair.trim_prefix("rightEye#").split(",")
					if split_pair.size() != 3:
						continue
					
					result["right_eye"] = Vector3(
						split_pair[0].to_float(),
						split_pair[1].to_float(),
						split_pair[2].to_float()
					)
				elif pair.begins_with("leftEye#"):
					var split_pair := pair.trim_prefix("leftEye#").split(",")
					if split_pair.size() != 3:
						continue
					
					result["left_eye"] = Vector3(
						split_pair[0].to_float(),
						split_pair[1].to_float(),
						split_pair[2].to_float()
					)
				else:
					var split_pair := pair.split("-")
					if split_pair.size() != 2:
						continue
					
					result[split_pair[0]] = split_pair[1]
			
			r.data_received.emit(result)
	)
	
	return r

func stop() -> Error:
	_should_stop = true
	
	_thread.wait_to_finish()
	_thread = null
	
	_socket.close()
	_socket = null
	
	return OK
