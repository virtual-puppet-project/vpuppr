class_name RemoteControlManager
extends Node

var thread: Thread
var should_stop_thread := true

var server: WebSocketServer
const POLL_INTERVAL: float = 0.1
var known_clients: Array = [] # Array of client ids as ints
var client_disconnects: int = 0 # Only used during shutdown

const MAX_SHUTDOWN_RETRY: int = 10
const DELAY_AMOUNT: int = 500 # Delay for half a second on each shutdown retry

###############################################################################
# Builtin functions                                                           #
###############################################################################

func _ready() -> void:
	AppManager.sb.connect("remote_control_port", self, "_on_remote_control_port")
	AppManager.sb.connect("use_remote_control", self, "_on_use_remote_control")
	
	if AppManager.cm.metadata_config.use_remote_control:
		start(AppManager.cm.metadata_config.remote_control_port)

###############################################################################
# Connections                                                                 #
###############################################################################

func _on_remote_control_port(_port: int) -> void:
	"""
	We don't actually use the value from the callback. This is just for telling the user
	that changing the port when the server is running won't do anything
	"""
	if not should_stop_thread:
		AppManager.logger.notify("Changing the remote control port while remote control is enabled will not have any effect")

func _on_use_remote_control(value: bool) -> void:
	if value:
		start(AppManager.cm.metadata_config.remote_control_port)
	else:
		shutdown()

func _on_client_close_request(id: int, code: int, reason: String) -> void:
	server.get_peer(id).close()
	AppManager.logger.info("Remote control client %d close requested with code %d and reason %s" % [
		id, code, reason
	])

func _on_client_connected(id: int, protocol: String) -> void:
	known_clients.append(id)
	AppManager.logger.info("Remote control client %d connected with protocol %s" % [
		id, protocol
	])

func _on_client_disconnected(id: int, _was_clean_close: bool) -> void:
	if should_stop_thread:
		client_disconnects += 1
	AppManager.logger.info("Remote control client %d disconnected" % id)

func _on_data_received(id: int) -> void:
	if not id in known_clients:
		AppManager.logger.error("Data received from unknown client %d\nShutting down" % id)
		shutdown()
		return
	
	var data: String = server.get_peer(id).get_packet().get_string_from_utf8().strip_edges().strip_escapes()
	if data.length() < 2: # Must be at least an empty json object
		AppManager.logger.error("Invalid data received from client %d" % id)
		return
	
	var json_result: JSONParseResult = JSON.parse(data)
	if json_result.error != OK:
		AppManager.logger.error("Unable to parse remote manager data: %s" % json_result.error_string)
		return
	
	if (typeof(json_result.result) != TYPE_DICTIONARY
			or not json_result.result.has("signal")
			or not json_result.result.has("value")):
		AppManager.logger.error("Invalid data type received from client %d" % id)
		return
	
	if (typeof(json_result.result["value"]) == TYPE_STRING and json_result.result["value"] == "remote_control_data_received"):
		var error_message: String = "Malicious client detected. Tried to trigger infinite loop.\nShutting down"
		AppManager.logger.error(error_message)
		AppManager.logger.notify("%s\n\nPlease delete the remote control app you are using as it is probably compromised."
				% error_message, Logger.NotifyType.POPUP)
		shutdown()
		return
	
	AppManager.sb.broadcast_remote_control_data_received(json_result.result)

###############################################################################
# Private functions                                                           #
###############################################################################

func _run_thread() -> void:
	while not should_stop_thread:
		server.poll()
		yield(get_tree().create_timer(POLL_INTERVAL), "timeout")

func _setup_server() -> WebSocketServer:
	var s := WebSocketServer.new()
	
	s.connect("client_close_request", self, "_on_client_close_request")
	s.connect("client_connected", self, "_on_client_connected")
	s.connect("client_disconnected", self, "_on_client_disconnected")
	s.connect("data_received", self, "_on_data_received")
	
	return s

###############################################################################
# Public functions                                                            #
###############################################################################

func start(port: int) -> void:
	AppManager.logger.debug("Try starting remote control server and thread")
	
	server = _setup_server()
	if server.listen(port) != OK:
		AppManager.logger.error("Unable to start remote manager server on port %d" % port)
		server = null
		return
	
	thread = Thread.new()
	should_stop_thread = false
	thread.start(self, "_run_thread")
	
	AppManager.logger.debug("Successfully started remote control server and thread")

func shutdown() -> void:
	var should_abort_shutdown := false
	if (thread == null or (thread != null and not thread.is_active())):
		thread = null
		should_abort_shutdown = true
	if (server == null or (server != null and not server.is_listening())):
		server = null
		should_abort_shutdown = true
	if should_abort_shutdown:
		return
	AppManager.logger.debug("Start shutting down remote control server and thread")
	
	for c in known_clients:
		if not server.has_peer(c):
			continue
		var peer: WebSocketPeer = server.get_peer(c)
		peer.close(1000, "Server shutting down")
	
	var retries: int = 0
	while true:
		if known_clients.size() == client_disconnects:
			AppManager.logger.debug("All clients disconnected as expected")
			break
		elif retries > MAX_SHUTDOWN_RETRY:
			AppManager.logger.error("Unable to disconnect all remote control clients")
			break
		OS.delay_msec(DELAY_AMOUNT)
		AppManager.logger.debug("Retrying remote manager shutdown")
		retries += 1
	
	client_disconnects = 0
	known_clients.clear()
	server.stop()
	
	should_stop_thread = true
	thread.wait_to_finish()
	server = null
	thread = null
	
	AppManager.logger.debug("Finished shutting down remote control server and thread")
