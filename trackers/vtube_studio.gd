extends AbstractTracker

var _logger := Logger.create("VTubeStudio")

var _data_request: PackedByteArray = []

var _socket: PacketPeerUDP = null
var _thread: Thread = null
var _should_stop := true

#-----------------------------------------------------------------------------#
# Builtin functions
#-----------------------------------------------------------------------------#

func _init() -> void:
	pass

#-----------------------------------------------------------------------------#
# Private functions
#-----------------------------------------------------------------------------#

#-----------------------------------------------------------------------------#
# Public functions
#-----------------------------------------------------------------------------#

static func create(data: Dictionary) -> AbstractTracker:
	var r := preload("res://trackers/vtube_studio.gd").new()
	
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
	return &"VTubeStudio"

func start() -> Error:
	return ERR_UNCONFIGURED

func stop() -> Error:
	return ERR_UNCONFIGURED
