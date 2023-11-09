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

static func create(data: Dictionary) -> AbstractTracker:
	var r := preload("res://trackers/i_facial_mocap.gd").new()
	
	if not data.has("port"):
		r._logger.error("Missing port")
		return null
	
	var port: int = data["port"]
	
	var socket := PacketPeerUDP.new()
	socket.bind(port)
	
	r._socket = socket
	
	return r

static func get_name() -> StringName:
	return &"iFacialMocap"

func start() -> Error:
	_logger.info("Starting iFacialMocap")
	
	_should_stop = false
	
	_thread = Thread.new()
	_thread.start(func() -> void:
		while not _should_stop:
			OS.delay_msec(10)
			
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
