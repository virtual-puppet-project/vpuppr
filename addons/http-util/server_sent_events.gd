extends Reference

## Library for Server Sent Events (SSE)
## SSEs are (basically) a one-way websocket connection
##
## Mimics the EventSource interface in ECMAScript
## https://developer.mozilla.org/en-US/docs/Web/API/Server-sent_events
## https://html.spec.whatwg.org/multipage/server-sent-events.html#server-sent-events

class ServerSideEvent:
	var event := ""
	var data := ""
	var id: int = -1
	## Must be interpreted as ASCII during parsing
	var retry: int = -1

# TODO verify this
## JSON object
signal error(data)
## Data comes in the format
## {
## 	"event": String, # Optional
## 	"data": Variant,
## 	"id": int, # Optional
## 	"retry": float # Optional
## }
signal message(data)
signal open()

enum State {
	CONNECTING = 0,
	OPEN,
	CLOSED
}

var _client: WebSocketClient

var ready_state: int = State.CONNECTING
var url := ""
var with_credentials := false

enum NewlineType {
	NONE = 0,
	CRLF,
	LF, # Prefer this option
	CR
}

const Fields := {
	"EVENT": "event",
	"DATA": "data",
	"ID": "id",
	"RETRY": "retry"
}

var newline_type: int = NewlineType.LF
var newline_char := "\n"
const COMMENT_CHAR := ":"

## Array of events being listened to
## These are emitted as user signals when data is received and the event matches a user signal
##
## NOTE: Once an event is added, it is never removed. Mostly because it is not possible
## to remove user_signals
var user_events := []

#-----------------------------------------------------------------------------#
# Builtin functions                                                           #
#-----------------------------------------------------------------------------#

# TODO not sure how to pass credentials, will need to look more into the spec
func _init(p_url: String, p_options: Dictionary = {
		"with_credentials": false,
		"newline_type": NewlineType.LF
		}) -> void:
	url = p_url
	for key in p_options.keys():
		set(key, p_options[key])
	
	match newline_type:
		NewlineType.CRLF:
			newline_char = "\r\n"
		NewlineType.LF:
			newline_char = "\n"
		NewlineType.CR:
			newline_char = "\r"
		_:
			printerr("Unhandled newline_type %d, aborting" % newline_type)
			return
	
	_client = WebSocketClient.new()
	if _client.connect_to_url(url) != OK:
		printerr("Unable to connect to SSE endpoint %s, aborting" % url)
		_client = null
		return
	
	_client.connect("connection_closed", self, "_on_connection_closed")
	_client.connect("connection_error", self, "_on_connection_error")
	_client.connect("connection_established", self, "_on_connection_established")
	_client.connect("data_received", self, "_on_data_received")
	_client.connect("server_close_request", self, "_on_server_close_request")

#-----------------------------------------------------------------------------#
# Connections                                                                 #
#-----------------------------------------------------------------------------#

func _on_connection_closed(was_clean_close: bool) -> void:
	print_debug("Connection to %s closed" % url)
	if not was_clean_close:
		printerr("%s was not a clean close" % url)

func _on_connection_error() -> void:
	printerr("Unable to connect to %s" % url)
	_client = null
	ready_state = State.CLOSED

func _on_connection_established(protocol: String) -> void:
	print_debug("SSE connection to %s established with %s" % [url, protocol])
	ready_state = State.OPEN

func _on_data_received() -> void:
	var sse := _parse_message(_get_message())
	
	emit_signal("message", sse)
	
	if sse.event in user_events:
		emit_signal(sse.event, sse)

func _on_server_close_request(code: int, reason: String) -> void:
	_client.disconnect_from_host(code, reason)
	ready_state = State.CLOSED

#-----------------------------------------------------------------------------#
# Private functions                                                           #
#-----------------------------------------------------------------------------#

## Gets a message from the connected host
##
## @return: String - The incoming message
func _get_message() -> String:
	return _client.get_peer(1).get_packet().get_string_from_utf8()

## Parses an SSE
## Based off of https://html.spec.whatwg.org/multipage/server-sent-events.html#server-sent-events
##
## @param: message: String - The packet converted to a valid String
##
## @return: ServerSideEvent - The parsed message
func _parse_message(message: String) -> ServerSideEvent:
	var sse := ServerSideEvent.new()
	
	var split := message.split(newline_char)
	for line in split:
		if line.begins_with(COMMENT_CHAR):
			continue
		
		var split_line: PoolStringArray = line.split(COMMENT_CHAR, false, 1)
		line = split_line[0] as String
		
		split_line = line.split(" ", true, 1)
		if split_line.size() < 2:
			print_debug("Skipping invalid line: %s" % line)
			continue
		
		var identifier: String = split_line[0]
		var value: String = split_line[1]
		match identifier:
			Fields.EVENT:
				sse.event = value
			Fields.DATA:
				sse.data = value
			Fields.ID:
				if not value.is_valid_integer():
					print_debug("field id is not a valid integer: %s" % str(value))
				else:
					sse.id = int(value)
			Fields.RETRY:
				if not value.is_valid_integer():
					print_debug("field retry is not a valid integer: %s" % str(value))
				else:
					sse.retry = int(value)
			_:
				print_debug("Unhandled field: %s" % identifier)
	
	return sse

#-----------------------------------------------------------------------------#
# Public functions                                                            #
#-----------------------------------------------------------------------------#

func is_alive() -> bool:
	return ready_state == State.OPEN

func poll() -> void:
	_client.poll()

func add_event_listener(event_name: String, handler: Object, method: String) -> int:
	if not has_user_signal(event_name):
		add_user_signal(event_name)
	
	return connect(event_name, handler, method)

func remove_event_listener(event_name: String, handler: Object, method: String) -> int:
	if not has_user_signal(event_name):
		return ERR_DOES_NOT_EXIST
	
	disconnect(event_name, handler, method)
	
	return OK

func close(code: int = 1000, reason: String = "") -> void:
	_client.disconnect_from_host(code, reason)
	ready_state = State.CLOSED
