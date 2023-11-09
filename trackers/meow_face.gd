extends AbstractTracker

var _logger := Logger.create("MeowFace")

var _data_request: PackedByteArray = []

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

static func create(data: Dictionary) -> AbstractTracker:
	var r := preload("res://trackers/meow_face.gd").new()
	
	if not data.has("address"):
		r._logger.error("Missing address")
		return null
	if not data.has("port"):
		r._logger.error("Missing port")
		return null
	
	var address: String = data["address"]
	var port: int = data["port"]
	
	var socket := PacketPeerUDP.new()
	socket.bind(port)
	socket.set_dest_address(address, port)
	socket.set_broadcast_enabled(true)
	
	r._socket = socket
	
	r._data_request = JSON.stringify({
		"messageType": "iOSTrackingDataRequest", # HMMMM
		"time": 1.0,
		"sentBy": "vpuppr",
		"ports": [
			port
		]
	}).to_utf8_buffer()
	
	return r

static func get_name() -> StringName:
	return &"MeowFace"

func start() -> Error:
	_logger.info("Starting MeowFace!")
	
	_should_stop = false
	
	_thread = Thread.new()
	_thread.start(func() -> void:
		while not _should_stop:
			OS.delay_msec(10)
			
			# TODO only need to send this once
			_socket.put_packet(_data_request)
			
			if _socket.get_available_packet_count() < 1:
				continue
			
			var packet := _socket.get_packet()
			if packet.size() < 1:
				continue
			
			data_received.emit(packet)
	)
	
	return OK

func stop() -> Error:
	_should_stop = true
	
	_thread.wait_to_finish()
	_thread = null
	
	_socket.close()
	_socket = null
	
	return OK
