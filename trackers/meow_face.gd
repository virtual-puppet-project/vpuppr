class_name MeowFace
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
	var r := MeowFace.new()
	
	if not data.has("bind_port"):
		r._logger.error("Missing bind_port")
		return null
	if not data.has("connect_address"):
		r._logger.error("Missing connect_address")
		return null
	if not data.has("connect_port"):
		r._logger.error("Missing connect_port")
		return null
	if not data.has("puppet"):
		r._logger.error("Missing puppet")
		return null
	
	var bind_port: int = data["bind_port"]
	
	var socket := PacketPeerUDP.new()
	socket.bind(bind_port)
	socket.set_dest_address(data["connect_address"], data["connect_port"])
	socket.set_broadcast_enabled(true)
	
	r._socket = socket
	r._puppet = data["puppet"]
	
	r._data_request = JSON.stringify({
		"messageType": "iOSTrackingDataRequest", # HMMMM
		"time": 1.0,
		"sentBy": "vpuppr",
		"ports": [
			bind_port
		]
	}).to_utf8_buffer()
	
	return r

func get_name() -> StringName:
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
			
			var data := MeowFaceData.from(packet)
			data_received.emit(data)
	)
	
	return OK

func stop() -> Error:
	_should_stop = true
	
	_thread.wait_to_finish()
	_thread = null
	
	_socket.close()
	_socket = null
	
	return OK
