extends WebSocketServer

## WebSocket remote controller
##
## FORMAT:
##
## key|type|values
##
## Key: The pubsub key to broadcast on
##
## Type: The Godot type to process as. Must match the builtin Godot enum for the type
##
## Values:
## - String, int, float: sent normally
## - bool: true/false as Strings
## - Vector2, Vector3, Color, Quaternion: x,y,z,w
##   - values delimited by commas, number of values must match
## - Transform, Transform2D: 1,2,3,4,5,6,7,8,9,x,y,z

const MAX_SHUTDOWN_RETRIES: int = 10

var logger: Logger

var known_clients := []

#-----------------------------------------------------------------------------#
# Builtin functions                                                           #
#-----------------------------------------------------------------------------#

func _init(p_logger: Logger) -> void:
	logger = p_logger

	connect("client_close_request", self, "_on_client_close_request")
	connect("client_connected", self, "_on_client_connected")
	connect("client_disconnected", self, "_on_client_disconnected")
	connect("data_received", self, "_on_data_received")

#-----------------------------------------------------------------------------#
# Connections                                                                 #
#-----------------------------------------------------------------------------#

func _on_client_close_request(id: int, code: int, reason: String) -> void:
	logger.info(tr("REMOTE_CONTROL_SERVER_CLIENT_CLOSE_REQUEST") % [code, reason])
	
	get_peer(id).close()

	if not known_clients.has(id):
		logger.error("Unknown client tried to disconnect: %d" % id)
		return
	known_clients.erase(id)

func _on_client_connected(id: int, protocol: String) -> void:
	logger.info(tr("REMOTE_CONTROL_SERVER_CLIENT_CONNECTED") % [id, protocol])
	
	get_peer(id).set_write_mode(WebSocketPeer.WRITE_MODE_TEXT)
	
	known_clients.append(id)

func _on_client_disconnected(id: int, was_clean_close: bool) -> void:
	logger.info(tr("REMOTE_CONTROL_SERVER_CLIENT_DISCONNECTED") % [id, str(was_clean_close)])

func _on_data_received(id: int) -> void:
	var data: String = get_peer(id).get_packet().get_string_from_utf8().strip_edges().strip_escapes()
	
	var split: PoolStringArray = data.split("|")
	if split.size() < 3:
		logger.error("Invalid data received")
		return

	var key: String = split[0]
	var value
	match int(split[1]):
		TYPE_STRING:
			value = split[2]
		TYPE_INT:
			value = int(split[2])
		TYPE_REAL:
			value = float(split[2])
		TYPE_BOOL:
			value = true if split[2].to_lower() == "true" else false
		TYPE_VECTOR2:
			split = split[2].split(",")
			value = Vector2(split[0].to_float(), split[1].to_float())
		TYPE_VECTOR3:
			split = split[2].split(",")
			value = Vector3(split[0].to_float(), split[1].to_float(), split[2].to_float())
		TYPE_COLOR:
			split = split[2].split(",")
			value = Color(split[0].to_float(), split[1].to_float(), split[2].to_float(), split[3].to_float())
			# TODO allow for int constructor as well?
		TYPE_TRANSFORM2D:
			split = split[2].split(",")
			value = Transform2D(
				Vector2(split[0].to_float(), split[1].to_float()),
				Vector2(split[2].to_float(), split[3].to_float()),
				Vector2(split[4].to_float(), split[5].to_float())
			)
		TYPE_TRANSFORM:
			split = split[2].split(",")
			value = Transform(
				Vector3(split[0].to_float(), split[1].to_float(), split[2].to_float()),
				Vector3(split[3].to_float(), split[4].to_float(), split[5].to_float()),
				Vector3(split[6].to_float(), split[7].to_float(), split[8].to_float()),
				Vector3(split[9].to_float(), split[10].to_float(), split[11].to_float())
			)
		TYPE_QUAT:
			split = split[2].split(",")
			value = Quat(split[0].to_float(), split[1].to_float(), split[2].to_float(), split[3].to_float())

	AM.ps.publish(key, value)

#-----------------------------------------------------------------------------#
# Private functions                                                           #
#-----------------------------------------------------------------------------#

#-----------------------------------------------------------------------------#
# Public functions                                                            #
#-----------------------------------------------------------------------------#

func shutdown() -> void:
	var clients_to_disconnect: int = known_clients.size()
	for client in known_clients:
		if not has_peer(client):
			continue
		var peer: WebSocketPeer = get_peer(client)
		peer.close(1000, tr("REMOTE_CONTROL_SERVER_SERVER_SHUTTING_DOWN"))
	
	var retries: int = 0
	while true:
		if known_clients.size() == clients_to_disconnect:
			logger.info(tr("REMOTE_CONTROL_SERVER_ALL_CLIENTS_DISCONNECTED"))
			break
		elif retries == MAX_SHUTDOWN_RETRIES:
			logger.error(tr("REMOTE_CONTROL_SERVER_MAX_SHUTDOWN_RETRIES_REACHED"))
			break
		
		yield(Engine.get_main_loop(), "idle_frame")
		retries += 1
		
		logger.debug("Retrying shutdown")

	stop()
