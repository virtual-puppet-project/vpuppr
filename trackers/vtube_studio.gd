class_name VTubeStudio
extends AbstractTracker

var _logger := Logger.create("VTubeStudio")

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

static func get_name() -> StringName:
	return &"VTubeStudio"

static func get_type() -> Trackers:
	return Trackers.VTUBE_STUDIO

static func start(data: Resource) -> AbstractTracker:
	var r := VTubeStudio.new()
	
	var address: String = data.address
	var port: int = data.port
	
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
	
	r._logger.info("Starting VTubeStudio!")
	
	r._should_stop = false
	
	r._thread = Thread.new()
	r._thread.start(func() -> void:
		while not r._should_stop:
			OS.delay_msec(10)
			
			# TODO only need to send this once
			r._socket.put_packet(r._data_request)
			
			if r._socket.get_available_packet_count() < 1:
				continue
			
			var packet := r._socket.get_packet()
			if packet.size() < 1:
				continue
			
			r.data_received.emit(packet)
	)
	
	return r

func stop() -> Error:
	_should_stop = true
	
	_thread.wait_to_finish()
	_thread = null
	
	_socket.close()
	_socket = null
	
	return OK
