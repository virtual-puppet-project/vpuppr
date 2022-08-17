extends WebSocketServer

var logger: Logger

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

func _on_client_connected(id: int, protocol: String) -> void:
	logger.info(tr("REMOTE_CONTROL_SERVER_CLIENT_CONNECTED") % [id, protocol])

func _on_client_disconnected(id: int, was_clean_close: bool) -> void:
	logger.info(tr("REMOTE_CONTROL_SERVER_CLIENT_DISCONNECTED") % [id, str(was_clean_close)])

func _on_data_received(id: int) -> void:
	var data: String = get_peer(id).get_packet().get_string_from_utf8().strip_edges().strip_escapes()

	logger.debug(data)

#-----------------------------------------------------------------------------#
# Private functions                                                           #
#-----------------------------------------------------------------------------#

#-----------------------------------------------------------------------------#
# Public functions                                                            #
#-----------------------------------------------------------------------------#
