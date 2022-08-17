extends VBoxContainer

enum ListenerTypes {
	NONE = 0,

	REST,
	WEBSOCKET,
	UDP
}

const ConfigKeys := {
	"REMOTE_CONTROL_SERVER_TYPE": "remote_control_server_type",
	"REMOTE_CONTROL_SERVER_PORT": "remote_control_server_port",
	"REMOTE_CONTROL_SERVER_POLL_INTERVAL": "remote_control_server_poll_interval"
}

const DEFAULT_PORT: int = 9999
const DEFAULT_POLL_INTERVAL: float = 0.1

const StartButtonText := {
	"START": "REMOTE_CONTROL_SERVER_START_LISTENING",
	"STOP": "REMOTE_CONTROL_SERVER_STOP_LISTENING"
}

var logger: Logger

var server_selector: OptionButton
var start_button: Button

var server
var connection
var listen_thread: Thread
var stop_server := true

#-----------------------------------------------------------------------------#
# Builtin functions                                                           #
#-----------------------------------------------------------------------------#

func _init() -> void:
	logger = Logger.new("RemoteControlServer")
	
	AM.cm.runtime_subscribe_to_signal(ConfigKeys.REMOTE_CONTROL_SERVER_TYPE)
	
	start_button = Button.new()
	start_button.text = tr(StartButtonText.START)
	start_button.connect("pressed", self, "_on_start_button_pressed")

	server_selector = OptionButton.new()
	add_child(server_selector)

	server_selector.add_item(tr("REMOTE_CONTROL_SERVER_NONE_OPTION"), ListenerTypes.NONE)
	server_selector.add_item(tr("REMOTE_CONTROL_SERVER_REST_SERVER_OPTION"), ListenerTypes.REST)
	server_selector.add_item(tr("REMOTE_CONTROL_SERVER_WEBSOCKET_SERVER_OPTION"), ListenerTypes.WEBSOCKET)
	server_selector.add_item(tr("REMOTE_CONTROL_SERVER_UDP_SERVER_OPTION"), ListenerTypes.UDP)

	var popup: PopupMenu = server_selector.get_popup()
	popup.connect("index_pressed", self, "_on_listener_type_pressed", [server_selector])

	var res: Result = Safely.wrap(AM.cm.get_data(ConfigKeys.REMOTE_CONTROL_SERVER_TYPE))
	if res.is_err() or typeof(res.unwrap()) != TYPE_STRING:
		logger.debug("No valid value found for %s, using defaults" % ConfigKeys.REMOTE_CONTROL_SERVER_TYPE)
		
		popup.set_item_checked(ListenerTypes.NONE, true)
		server_selector.selected = ListenerTypes.NONE
		
		_on_listener_type_pressed(ListenerTypes.NONE, server_selector)
	else:
		var listener_type: String = res.unwrap()
		for i in server_selector.get_item_count():
			if popup.get_item_text(i) == listener_type:
				popup.set_item_checked(i, true)
				server_selector.selected = i

				_on_listener_type_pressed(i, server_selector)
				break

	var port_hbox := HBoxContainer.new()
	ControlUtil.h_expand_fill(port_hbox)

	add_child(port_hbox)

	var port_label := Label.new()
	ControlUtil.h_expand_fill(port_label)
	port_label.text = tr("REMOTE_CONTROL_SERVER_PORT_LABEL")

	port_hbox.add_child(port_label)

	var port_line_edit := LineEdit.new()
	ControlUtil.h_expand_fill(port_line_edit)
	port_line_edit.text = str(AM.cm.get_data(ConfigKeys.REMOTE_CONTROL_SERVER_PORT, DEFAULT_PORT))

	port_hbox.add_child(port_line_edit)

	# TODO
	var poll_interval_hbox := HBoxContainer.new()
	ControlUtil.h_expand_fill(poll_interval_hbox)

	add_child(poll_interval_hbox)

	var poll_interval_label := Label.new()
	ControlUtil.h_expand_fill(poll_interval_label)
	poll_interval_label.text = tr("REMOTE_CONTROL_SERVER_POLL_INTERVAL_LABEL")

	poll_interval_hbox.add_child(poll_interval_label)

	var poll_interval_line_edit := LineEdit.new()
	ControlUtil.h_expand_fill(poll_interval_line_edit)
	poll_interval_line_edit.text = str(
		AM.cm.get_data(ConfigKeys.REMOTE_CONTROL_SERVER_POLL_INTERVAL, DEFAULT_POLL_INTERVAL))

	poll_interval_hbox.add_child(poll_interval_line_edit)

	add_child(start_button)

#-----------------------------------------------------------------------------#
# Connections                                                                 #
#-----------------------------------------------------------------------------#

func _on_listener_type_pressed(idx: int, ob: OptionButton) -> void:
	var popup: PopupMenu = ob.get_popup()
	var current_index: int = ob.selected
	
	if current_index < 0:
		logger.error(tr("REMOTE_CONTROL_SERVER_NO_PREVIOUSLY_SELECTED_ITEM"))
	else:
		popup.set_item_checked(current_index, false)

	popup.set_item_checked(idx, true)

	var item_text: String = popup.get_item_text(idx)

	ob.text = item_text
	AM.ps.publish(ConfigKeys.REMOTE_CONTROL_SERVER_TYPE, item_text)

	# Always keep the start_button enabled while the server is running
	if not stop_server:
		start_button.disabled = false
		return

	start_button.disabled = idx == ListenerTypes.NONE

func _on_start_button_pressed() -> void:
	match stop_server:
		true: # Server is probably stopped, start it again
			_start_server()
		false: # Server is probably running, try and stop it
			_stop_server()

#-----------------------------------------------------------------------------#
# Private functions                                                           #
#-----------------------------------------------------------------------------#

func _perform_reception_websocket(_x) -> void:
	while not stop_server:
		server.poll()

	pass

func _perform_reception_udp(_x) -> void:
	while not stop_server:
		server.poll()

	pass

func _perform_reception_tcp(_x) -> void:
	while not stop_server:
		pass

	pass

func _start_server() -> void:
	if stop_server == false:
		logger.error(tr("REMOTE_CONTROL_SERVER_SERVER_ALREADY_RUNNING"))
		return

	var port: int = -1

	var res: Result = Safely.wrap(AM.cm.get_data(ConfigKeys.REMOTE_CONTROL_SERVER_PORT))
	if res.is_err():
		logger.error(tr("REMOTE_CONTROL_SERVER_NO_PORT_FOUND"))
		return
	port = res.unwrap()

	listen_thread = Thread.new()
	stop_server = false

	match server_selector.selected:
		ListenerTypes.REST:
			logger.error("Not yet implemented")
			logger.error("Will probably need to pull in this file later: https://github.com/you-win/http-util-gd/blob/master/addons/http-util/server.gd")
			listen_thread = null
			stop_server = true
			return
		ListenerTypes.WEBSOCKET:
			res = Safely.wrap(AM.em.load_resource("RemoteControlServer", "websocket.gd"))
			if res.is_err():
				logger.error(tr("REMOTE_CONTROL_SERVER_UNABLE_TO_LOAD_RESOURCE"))
				listen_thread = null
				return
			server = res.unwrap().new(logger)
			server.listen(port)

			listen_thread.start(self, "_perform_reception_websocket")
		ListenerTypes.UDP:
			res = Safely.wrap(AM.em.load_resource("RemoteControlServer", "udp.gd"))
			if res.is_err():
				logger.error(tr("REMOTE_CONTROL_SERVER_UNABLE_TO_LOAD_RESOURCE"))
				listen_thread = null
				return
			server = res.unwrap().new(logger)
			server.listen(port)

			listen_thread.start(self, "_perform_reception_udp")
		_:
			logger.error(tr("REMOTE_CONTROL_SERVER_INVALID_SERVER_TYPE"))
			listen_thread = null
			stop_server = true
			return

func _stop_server() -> void:
	if server == null:
		logger.error(tr("REMOTE_CONTROL_SERVER_SERVER_IS_NULL"))
	else:
		# TCP_Server, UDPServer, WebSocketServer all implement a stop() function
		server.stop()

	if listen_thread == null:
		logger.error(tr("REMOTE_CONTROL_SERVER_THREAD_IS_NULL"))
	else:
		listen_thread.wait_to_finish()
		listen_thread = null

#-----------------------------------------------------------------------------#
# Public functions                                                            #
#-----------------------------------------------------------------------------#
