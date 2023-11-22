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

static func get_type() -> Trackers:
	return Trackers.I_FACIAL_MOCAP

static func start(data: Resource) -> AbstractTracker:
	var r := IFacialMocap.new()
	
	var port: int = data.port
	
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
