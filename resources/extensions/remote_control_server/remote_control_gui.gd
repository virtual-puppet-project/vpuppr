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

const CACHE_KEY := "RemoteControlServer"
const DEFAULT_PORT: int = 9999
const DEFAULT_POLL_INTERVAL: float = 0.1

const StartButtonText := {
	"START": "REMOTE_CONTROL_SERVER_START_LISTENING",
	"STOP": "REMOTE_CONTROL_SERVER_STOP_LISTENING"
}

var logger: Logger

var server_selector: OptionButton
var start_button: Button

#-----------------------------------------------------------------------------#
# Builtin functions                                                           #
#-----------------------------------------------------------------------------#

func _init() -> void:
	logger = Logger.new("RemoteControlServer")
	
	AM.cm.runtime_subscribe_to_signal(ConfigKeys.REMOTE_CONTROL_SERVER_TYPE)
	
	start_button = Button.new()
	if Safely.wrap(AM.tcm.pull(CACHE_KEY)).is_err():
		start_button.text = tr(StartButtonText.START)
	else:
		start_button.text = tr(StartButtonText.STOP)
	start_button.connect("pressed", self, "_on_start_button_pressed", [start_button])

	server_selector = OptionButton.new()
	add_child(server_selector)

	server_selector.add_item(tr("REMOTE_CONTROL_SERVER_NONE_OPTION"), ListenerTypes.NONE)
	# TODO add back in when rest server functionality is present
	# server_selector.add_item(tr("REMOTE_CONTROL_SERVER_REST_SERVER_OPTION"), ListenerTypes.REST)
	server_selector.add_item(tr("REMOTE_CONTROL_SERVER_WEBSOCKET_SERVER_OPTION"), ListenerTypes.WEBSOCKET)
	# TODO add back in when udp is implemented
	# server_selector.add_item(tr("REMOTE_CONTROL_SERVER_UDP_SERVER_OPTION"), ListenerTypes.UDP)

	var popup: PopupMenu = server_selector.get_popup()
	popup.connect("id_pressed", self, "_on_listener_type_pressed", [server_selector])

	var res: Result = Safely.wrap(AM.cm.get_data(ConfigKeys.REMOTE_CONTROL_SERVER_TYPE))
	if res.is_err() or typeof(res.unwrap()) != TYPE_STRING:
		logger.debug("No valid value found for %s, using defaults" % ConfigKeys.REMOTE_CONTROL_SERVER_TYPE)
		
		popup.set_item_checked(ListenerTypes.NONE, true)
		server_selector.selected = ListenerTypes.NONE
		
		_on_listener_type_pressed(ListenerTypes.NONE, server_selector)
	else:
		var listener_type: String = res.unwrap()
		for i in server_selector.get_item_count():
			var item_text: String = popup.get_item_text(i)
			if item_text == listener_type:
				logger.debug("Found initial value: %d" % i)
				popup.set_item_checked(i, true)
				server_selector.selected = i
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
	port_line_edit.connect("text_changed", self, "_on_line_edit_changed", [ConfigKeys.REMOTE_CONTROL_SERVER_PORT])

	port_hbox.add_child(port_line_edit)

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
	poll_interval_line_edit.connect("text_changed", self, "_on_line_edit_changed",
		[ConfigKeys.REMOTE_CONTROL_SERVER_POLL_INTERVAL])

	poll_interval_hbox.add_child(poll_interval_line_edit)

	add_child(start_button)

#-----------------------------------------------------------------------------#
# Connections                                                                 #
#-----------------------------------------------------------------------------#

func _on_listener_type_pressed(id: int, ob: OptionButton) -> void:
	var popup: PopupMenu = ob.get_popup()
	var current_index: int = popup.get_item_index(id)
	
	if current_index < 0:
		logger.error(tr("REMOTE_CONTROL_SERVER_NO_PREVIOUSLY_SELECTED_ITEM"))
	else:
		popup.set_item_checked(current_index, false)

	popup.set_item_checked(current_index, true)

	var item_text: String = popup.get_item_text(current_index)

	ob.text = item_text
	AM.ps.publish(ConfigKeys.REMOTE_CONTROL_SERVER_TYPE, item_text)

	# Check if there is already a server running
	if Safely.wrap(AM.tcm.pull(CACHE_KEY)).is_err():
		start_button.disabled = false
		return

	start_button.disabled = id == ListenerTypes.NONE

func _on_line_edit_changed(text: String, config_key: String) -> void:
	if text.empty():
		return
	
	match config_key:
		ConfigKeys.REMOTE_CONTROL_SERVER_PORT:
			if not text.is_valid_integer():
				return
			AM.ps.publish(config_key, text.to_int())
		ConfigKeys.REMOTE_CONTROL_SERVER_POLL_INTERVAL:
			if not text.is_valid_float():
				return
			AM.ps.publish(config_key, text.to_float())
		_:
			logger.error("Bad config key for line edit connection")

func _on_start_button_pressed(button: Button) -> void:
	# match stop_server:
	match Safely.wrap(AM.tcm.pull(CACHE_KEY)).is_err():
		true: # Server is probably stopped, start it again
			_start_server()
			button.text = tr(StartButtonText.STOP)
		false: # Server is probably running, try and stop it
			_stop_server()
			button.text = tr(StartButtonText.START)

#-----------------------------------------------------------------------------#
# Private functions                                                           #
#-----------------------------------------------------------------------------#

func _start_server() -> void:
#	if stop_server == false:
	if Safely.wrap(AM.tcm.pull(CACHE_KEY)).is_ok():
		logger.error(tr("REMOTE_CONTROL_SERVER_SERVER_ALREADY_RUNNING"))
		return

	var port: int = -1

	var res: Result = Safely.wrap(AM.cm.get_data(ConfigKeys.REMOTE_CONTROL_SERVER_PORT))
	if res.is_err():
		logger.error(tr("REMOTE_CONTROL_SERVER_NO_PORT_FOUND"))
		return
	port = res.unwrap()

	res = Safely.wrap(AM.em.load_resource("RemoteControlServer", "server_handler.gd"))
	if res.is_err():
		logger.error(res)
		return
	
	var HandlerScript: GDScript = res.unwrap()

	match server_selector.get_popup().get_item_id(server_selector.selected):
		ListenerTypes.REST:
			logger.error("Not yet implemented")
			logger.error("Will probably need to pull in this file later: https://github.com/you-win/http-util-gd/blob/master/addons/http-util/server.gd")
			return
		ListenerTypes.WEBSOCKET:
			res = Safely.wrap(AM.em.load_resource("RemoteControlServer", "websocket.gd"))
			if res.is_err():
				logger.error(tr("REMOTE_CONTROL_SERVER_UNABLE_TO_LOAD_RESOURCE"))
				return
		ListenerTypes.UDP:
			res = Safely.wrap(AM.em.load_resource("RemoteControlServer", "udp.gd"))
			if res.is_err():
				logger.error(tr("REMOTE_CONTROL_SERVER_UNABLE_TO_LOAD_RESOURCE"))
				return
		_:
			logger.error(tr("REMOTE_CONTROL_SERVER_INVALID_SERVER_TYPE"))
			return
	
	# TODO hardcoded poll interval
	var handler: Node = HandlerScript.new(res.unwrap(), port, 0.1)
	handler.name = "RemoteControlServer"

	AM.tcm.push(CACHE_KEY, handler)
	get_tree().root.add_child(handler)

	logger.info(tr("REMOTE_CONTROL_SERVER_SERVER_STARTED"))

func _stop_server() -> void:
	var res: Result = Safely.wrap(AM.tcm.pull(CACHE_KEY))
	if res.is_err():
		logger.error(tr("REMOTE_CONTROL_SERVER_SERVER_IS_NULL"))
		return
	
	var handler: Node = res.unwrap()
	yield(handler.stop(), "completed")
	handler.queue_free()
	AM.tcm.erase(CACHE_KEY)

	logger.info(tr("REMOTE_CONTROL_SERVER_SERVER_STOPPED"))

#-----------------------------------------------------------------------------#
# Public functions                                                            #
#-----------------------------------------------------------------------------#
