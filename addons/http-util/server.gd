extends Reference

class Request:
	var is_valid := false
	
	var method := ""
	var path := ""
	var protocol := ""
	
	var headers := PoolStringArray()
	var body := PoolByteArray()
	
	var peer: StreamPeerTCP

class Router:
	## Expects a configuration in the following format
	## {
	## 	"routes": {
	## 		"route/uri/optional/<wild_card>": {
	## 			# The object that will be called
	## 			"handler": Object,
	## 			# The function to call on the handler
	## 			"method": String,
	## 			# Optional, params to be passed to the handler's method
	## 			"params": [],
	## 			# Optional, route-specific option overrides
	## 			"options": {
	## 				# See root-level options
	## 			}
	## 		}
	## 	},
	## 	# Optional, Global-level options
	## 	# If omitted, the defaults shown here will be used
	## 	"options": {
	## 		# Pass the associated StreamPeerTCP to handler methods
	## 		# Handler methods are checked to see if they accept a StreamPeerTCP parameter
	## 		# If true, the router will not try to send a response
	## 		# The handler method MUST send a response and is reponsible for closing the connection
	## 		"pass_stream_peer": false,
	## 		# Handler methods are allowed to return null instead of a:
	## 		- response
	## 		- error code
	## 		"can_return_null": false
	## 	}
	##
	## @type: Dictionary<String, Route>
	var router_config := {}
	
	func _init(p_router_config: Dictionary) -> void:
		if p_router_config.empty():
			return
		if update_config(p_router_config) != OK:
			print_debug("Router not configured properly")
	
	func update_config(p_router_config: Dictionary) -> int:
		if OS.is_debug_build():
			if not p_router_config.has("routes"):
				print_debug("router_config must contain routes")
				return ERR_INVALID_DECLARATION
		
		var routes: Dictionary = p_router_config.get("routes", {})
		var global_options: Dictionary = p_router_config.get("options", {})
		
		for path in routes.keys():
			var val = routes[path]
			
			# Just send it in release mode
			if OS.is_debug_build():
				if typeof(val) != TYPE_DICTIONARY:
					print_debug("Route configuration must be a Dictionary")
					return ERR_INVALID_DATA
				
				if not val.has("handler") or not val.has("method"):
					print_debug("Route configuration must have the handler and method keys defined")
					return ERR_INVALID_DECLARATION
			
			var handler: Object = val.handler
			var method: String = val.method
			var args: Array = val.get("args", [])
			var local_options: Dictionary = val.get("options", {})
			if local_options.empty():
				local_options = global_options
			else:
				for option in global_options.keys():
					if option in local_options:
						continue
					
					local_options[option] = global_options[option]
			
			var route := Route.new(path, handler, method, args, local_options)
			verify(route)
			
			router_config[path] = route
		
		return OK
	
	func verify(route: Route = null) -> int:
		if route != null:
			return _verify(route)
		
		var err := OK
		for route in router_config.values():
			err = _verify(route)
			if err != OK:
				return err
		
		return OK
	
	func _verify(route: Route) -> int:
		if route.handler == null:
			print_debug("Route handler must not be null")
			return ERR_INVALID_DECLARATION
		if route.method.empty():
			print_debug("Route method must not be empty")
			return ERR_INVALID_DECLARATION
		
		var method_list: Array = route.handler.get_method_list()
		var is_valid_method := false
		for dict in method_list:
			if dict.name != route.method:
				continue
			
			if dict.args.size() < 1:
				break
			
			var first_param: Dictionary = dict.args[0]
			# If no type is provided, the class_name will be an empty String
			if first_param["class_name"] in ["Dictionary", ""]:
				is_valid_method = true
				break
			
			if route.pass_stream_peer:
				is_valid_method = false
				if dict.args.size() < 2:
					break
				
				var second_param: Dictionary = dict.args[1]
				if second_param["class_name"] in ["StreamPeerTCP", ""]:
					is_valid_method = true
					break
		
		if not is_valid_method:
			print_debug("Method %s does not have enough params" %
					route.method)
			return ERR_INVALID_DECLARATION
		
		return OK
	
	func cleanup() -> void:
		for route in router_config.values():
			route.handler = null
			route.args.clear()
	
	func handle(request: Request) -> int:
		var response := {
			"protocol": request.protocol,
			"response_code": 200,
			"headers": []
		}
		
		if not router_config.has(request.path):
			printerr("Route %s not configured in keys %s" % [request.path, str(router_config.keys())])
			response.response_code = 404
			
			_send_response(request.peer, response)
			
			return ERR_UNCONFIGURED
		
		var route: Route = router_config[request.path]
		
		var args := [response]
		if route.pass_stream_peer:
			args.append(request.peer)
		args.append_array(route.args)
		
		var res = route.handler.callv(route.method, args)
		match typeof(res):
			TYPE_NIL:
				if not route.can_return_null:
					printerr("Error encountered for route %s" % route.path)
					
					if not route.pass_stream_peer:
						printerr("Peer is still connected, sending 500 error response")
						response.response_code = 500
						response["body"] = "Unhandled server error"
						_send_response(request.peer, response)
					
					return ERR_BUG
				
				_send_response(request.peer, response)
				return OK
			TYPE_INT:
				# TODO it might be better to use this as the reponse code?
				if res != OK:
					printerr("Error encountered for route %s" % route.path)
					
					if not route.pass_stream_peer:
						printerr("Peer is still connected, sending 500 error response")
						response.response_code = 500
						response["body"] = "Unhandled server error"
						_send_response(request.peer, response)
					
					return ERR_BUG
				
				_send_response(request.peer, response)
				return OK
			_:
				printerr("Unhandled handler return value %s" % str(res))
				return ERR_INVALID_DATA
	
	static func _send_response(peer: StreamPeerTCP, response: Dictionary) -> void:
		var protocol: String = response.protocol
		var response_code: int = response.response_code
		var headers: Array = response.headers
		var body = response.get("body", null)
		
		var body_bytes := PoolByteArray()
		
		match typeof(body):
			TYPE_NIL:
				pass
			TYPE_STRING:
				body_bytes.append_array(body.to_utf8())
			TYPE_ARRAY, TYPE_DICTIONARY:
				body_bytes.append_array(JSON.print(body).to_utf8())
			TYPE_RAW_ARRAY:
				body_bytes.append_array(body)
			_:
				printerr("Unhandled body: %s" % str(body))
				body_bytes.append_array("Unhandled server error".to_utf8())
				response_code = 500
		
		peer.put_data(_to_response_line("%s %d" % [protocol, response_code]))
		for header in headers:
			peer.put_data(_to_response_line(header))
		if body_bytes.empty():
			peer.put_data(_to_response_line(""))
		else:
			peer.put_data(_to_response_line("Content-Length: %d\r\n" % body_bytes.size()))
			peer.put_data(body_bytes)
		
		peer.disconnect_from_host()
	
	static func _to_response_line(data: String) -> PoolByteArray:
		return ("%s\r\n" % data).to_utf8()

class Route:
	var path := ""
	
	var handler: Object
	var method := ""
	
	var args := []
	
	var pass_stream_peer := false
	var can_return_null := false
	
	func _init(p_path: String, p_handler: Object, p_method: String, p_args: Array, options: Dictionary) -> void:
		handler = p_handler
		method = p_method
		
		# TODO might need to duplicate this?
		args = p_args
		
		# Neat little trick to automatically set all options
		for prop in get_property_list():
			if prop.name in [get_class(), "script", "Script Variables",
					"handler", "method" # Excluded since they are not options
					]:
				continue
			
			# All options have a default value
			set(prop.name, options.get(prop.name, get(prop.name)))

class RouteBuilder:
	var _router: Router

	var _path := ""

	var _handler: Object
	var _method := ""

	var _args := []

	var _options := {}

	func _init(p_router: Router, p_path: String) -> void:
		_router = p_router
		_path = p_path

	func handler(p_handler: Object) -> RouteBuilder:
		_handler = p_handler

		return self

	func method(p_method: String) -> RouteBuilder:
		_method = p_method

		return self

	func arg(p_arg) -> RouteBuilder:
		_args.append(p_arg)

		return self

	func option(key: String, value) -> RouteBuilder:
		_options[key] = value

		return self

	func build() -> int:
		if _handler == null:
			return ERR_INVALID_PARAMETER
		if _method.empty():
			return ERR_INVALID_DECLARATION

		if _router.router_config.has(_path):
			print_debug("Route %s already exists, overwriting" % _path)

		_router.router_config[_path] = Route.new(_path, _handler, _method, _args, _options)

		return OK

enum ParserState {
	FIRST_LINE_READ,
	FIRST_LINE_EXPECT_NL,
	HEADER_READ,
	HEADER_EXPECT_NL,
	BODY
}

var request_parsing_retry_max: int = 5

var _server := TCP_Server.new()
var _router: Router

var _server_thread: Thread
var _should_shutdown := false

#-----------------------------------------------------------------------------#
# Builtin functions                                                           #
#-----------------------------------------------------------------------------#

func _init(router_config: Dictionary = {}) -> void:
	_router = Router.new(router_config)

func _notification(what: int) -> void:
	match what:
		NOTIFICATION_PREDELETE:
			if _router == null:
				return
			
			_router.cleanup()
			_router.router_config.clear()

#-----------------------------------------------------------------------------#
# Connections                                                                 #
#-----------------------------------------------------------------------------#

#-----------------------------------------------------------------------------#
# Private functions                                                           #
#-----------------------------------------------------------------------------#

func _listen(_x) -> void:
	_should_shutdown = false
	
	while not _should_shutdown:
		if not _server.is_connection_available():
			OS.delay_msec(100)
			continue
		
		var peer := _server.take_connection()
		
		print_debug("Peer connected %s:%d" % [peer.get_connected_host(), peer.get_connected_port()])
		
		var request := _parse_request(peer)
		if request.is_valid:
			var err: int = _router.handle(request)
			if err != OK:
				print_debug("Error occurred while handling request: %d" % err)
		
		# Cleanup peer if the handler didn't already clean it up
		if peer.is_connected_to_host():
			peer.disconnect_from_host()

func _parse_request(peer: StreamPeerTCP) -> Request:
	var req := Request.new()
	req.peer = peer

	var state: int = ParserState.FIRST_LINE_READ
	var content_length: int = 0
	
	var retry_count: int = 0

	while true:
		if not peer.is_connected_to_host():
			print_debug("Peer is not connected")
			return req

		var available_bytes := peer.get_available_bytes()
		if available_bytes < 1:
			retry_count += 1
			if retry_count > request_parsing_retry_max:
				return req
			
			OS.delay_msec(100)
			continue

		var data_tuple: Array = peer.get_data(available_bytes)
		if data_tuple[0] != OK:
			print_debug("Failed to get data: %d" % data_tuple[0])
			return req

		var string_builder := Array()
		var data: PoolByteArray = data_tuple[1]
		for byte in data:
			match state:
				ParserState.FIRST_LINE_READ:
					state = _add_char(byte, string_builder, state, ParserState.FIRST_LINE_EXPECT_NL)
				ParserState.FIRST_LINE_EXPECT_NL:
					if byte != ord("\n"):
						print_debug("Received \\r with no \\n")
						return req
					
					var line: String = PoolStringArray(string_builder).join("")
					string_builder.clear()
					
					var parts := line.split(" ")
					if parts.size() != 3:
						print_debug("Bad request, first line malformed: %s" % line)
						return req
					
					req.method = parts[0]
					req.path = parts[1]
					req.protocol = parts[2]
					
					state = ParserState.HEADER_READ
				ParserState.HEADER_READ:
					state = _add_char(byte, string_builder, state, ParserState.HEADER_EXPECT_NL)
				ParserState.HEADER_EXPECT_NL:
					if byte != ord("\n"):
						print_debug("Received \\r with no \\n")
						return req
					
					var should_break := false
					if string_builder.empty():
						if content_length > 0:
							state = ParserState.BODY
							should_break = true
						else:
							req.is_valid = true
							return req
					
					if not should_break:
						var line: String = PoolStringArray(string_builder).join("")
						string_builder.clear()
						
						var parts: PoolStringArray = line.split(": ", true, 1)
						if parts.size() != 2:
							print_debug("Bad request, malformed header %s" % line)
							return req
						
						var header_name: String = parts[0]
						var header_value: String = parts[1]
						
						if header_name == "Content-Length":
							if content_length != 0:
								print_debug("Content-Length header was set again")
								return req
							if not header_value.is_valid_integer():
								print_debug("Content-Length is invalid")
								return req
							
							content_length = header_value.to_int()
						
						req.headers.append(line)
						
						state = ParserState.HEADER_READ
				ParserState.BODY:
					req.body.append(byte)
					content_length -= 1
					if content_length == 0:
						req.is_valid = true
						return req

	printerr("Unexpected state, bad request")
	return req

static func _add_char(byte: int, builder: Array, old_state: int, new_state: int) -> int:
	var c := char(byte)
	if c == "\r":
		return new_state
	
	builder.append(c)
	
	return old_state

#-----------------------------------------------------------------------------#
# Public functions                                                            #
#-----------------------------------------------------------------------------#

func is_running() -> bool:
	return _server.is_listening()

func start(port: int, bind_address: String = "*") -> int:
	print_debug("Starting server")
	
	stop()
	
	if _router.verify() != OK:
		print_debug("Router was not configured correctly, declining to start server")
		return ERR_INVALID_DATA
	
	var err := _server.listen(port, bind_address)
	if err != OK:
		return err
	
	_server_thread = Thread.new()
	err = _server_thread.start(self, "_listen")
	
	return err

func stop() -> void:
	if _server.is_listening():
		print_debug("Stopping server")
		
		_server.stop()
	if _server_thread != null and _server_thread.is_active():
		print_debug("Stopping thread")
		
		_should_shutdown = true
		_server_thread.wait_to_finish()

#region Router

func update_router(router_config: Dictionary) -> void:
	_router.update_config(router_config)

func add_route(uri: String) -> RouteBuilder:
	return RouteBuilder.new(_router, uri)

#endregion
