extends Reference

class Request:
	## The address without any subpages
	## e.g. www.google.com
	var base_url := ""
	var port: int = -1
	var use_ssl := false
	var verify_host := true
	## The identifier with no preceding "/" character
	## e.g. mail
	var uri := ""
	var request_type: int = -1
	var headers := []
	var data := ""
	
	func _to_string() -> String:
		return ("""
---Request---
base_url:
%s
port:
%d
use_ssl:
%s
verify_host:
%s
uri:
%s
request_type:
%d
headers:
%s
data:
%s
		""" % [
			base_url,
			port,
			str(use_ssl),
			str(verify_host),
			uri,
			request_type,
			JSON.print(headers, "\t"),
			data
		]).strip_edges()
	
	func send() -> Response:
		print_debug(to_string())
		
		var response := Response.new()
		
		var http := HTTPClient.new()
		
		var err: int = http.connect_to_host(base_url, port, use_ssl, verify_host)
		if err != OK:
			printerr("Error occurred while connecting to host %s:%d: %d" % [base_url, port, err])
			return response
		
		print_debug("Connecting")
		
		while http.get_status() == HTTPClient.STATUS_CONNECTING or \
				http.get_status() == HTTPClient.STATUS_RESOLVING:
			http.poll()
			
			print_debug("...")
			
			yield(Engine.get_main_loop(), "idle_frame")
		
		if http.get_status() != HTTPClient.STATUS_CONNECTED:
			printerr("Unable to connect to host: %s:%d" % [base_url, port])
			return response
		
		print_debug("Requesting")
		
		err = http.request(request_type, uri, headers)
		if err != OK:
			printerr("Unable to send request to %s:%d%s" % [base_url, port, uri])
			return response
		
		while http.get_status() == HTTPClient.STATUS_REQUESTING:
			http.poll()
			
			print_debug("...")
			
			yield(Engine.get_main_loop(), "idle_frame")
		
		if not http.get_status() == HTTPClient.STATUS_BODY and \
				not http.get_status() == HTTPClient.STATUS_CONNECTED:
			printerr("Unexpected response from %s:%d%s" % [base_url, port, uri])
		
		response.code = http.get_response_code()
		response.headers = http.get_response_headers_as_dictionary()
		
		var body := PoolByteArray()
		
		print_debug("Parsing body")
		
		while http.get_status() == HTTPClient.STATUS_BODY:
			http.poll()
			
			print_debug("...")
			
			var chunk: PoolByteArray = http.read_response_body_chunk()
			if chunk.size() == 0:
				yield(Engine.get_main_loop(), "idle_frame")
			else:
				body.append_array(chunk)
		
		response.body = body
		
		print_debug("Finished!")
		
		return response

class RequestBuilder:
	const DEFAULT_USER_AGENT := "User-Agent: http-util-gd/1.0 (Godot)"
	const DEFAULT_ACCEPT_ALL := "Accept: */*"
	
	## The address without any subpages
	## e.g. www.google.com
	var base_url := ""
	var port: int = -1
	var use_ssl := false
	var verify_host := true
	## The identifier
	## e.g. /mail
	var uri := ""
	var request_type: int = -1
	var headers := {}
	var data
	
	func _init(url: String) -> void:
		base_url = url.trim_suffix("/")
	
	func _to_string() -> String:
		return ("""
---RequestBuilder---
base_url:
%s
port:
%d
use_ssl:
%s
verify_host:
%s
uri:
%s
request_type:
%d
headers:
%s
data:
%s
		""" % [
			base_url,
			port,
			str(use_ssl),
			str(verify_host),
			uri,
			request_type,
			JSON.print(headers, "\t"),
			str(data)
		]).strip_edges()
	
	func _verify() -> bool:
		if base_url.empty():
			return false
		if request_type < 0:
			return false
		
		return true
	
	func port(p_port: int) -> RequestBuilder:
		port = p_port
		return self
	
	func use_ssl(enable: bool = true) -> RequestBuilder:
		use_ssl = enable
		return self
	
	func verify_host(enable: bool = true) -> RequestBuilder:
		verify_host = enable
		return self
	
	func uri(p_uri: String) -> RequestBuilder:
		uri = p_uri.trim_prefix("/")
		return self
	
	#region Set request type
	
	func as_get() -> RequestBuilder:
		request_type = HTTPClient.METHOD_GET
		return self
	
	func as_post() -> RequestBuilder:
		request_type = HTTPClient.METHOD_POST
		return self
	
	func as_put() -> RequestBuilder:
		request_type = HTTPClient.METHOD_PUT
		return self
	
	func as_delete() -> RequestBuilder:
		request_type = HTTPClient.METHOD_DELETE
		return self
	
	func as_patch() -> RequestBuilder:
		request_type = HTTPClient.METHOD_PATCH
		return self
	
	func as_option() -> RequestBuilder:
		request_type = HTTPClient.METHOD_OPTION
		return self
	
	func as_connect() -> RequestBuilder:
		request_type = HTTPClient.METHOD_CONNECT
		return self
	
	func as_trace() -> RequestBuilder:
		request_type = HTTPClient.METHOD_TRACE
		return self
	
	#endregion
	
	#region Headers
	
	func header(header_key: String, header_value: String) -> RequestBuilder:
		headers[header_key] = header_value
		return self
	
	func headers(p_headers: Dictionary) -> RequestBuilder:
		for key in p_headers.keys():
			headers[key] = p_headers[key]
		return self
	
	func header_line(header: String) -> RequestBuilder:
		var split := header.split(":", false, 1)
		if split.size() < 2:
			printerr("Invalid header: %s" % header)
			return self
		
		headers[split[0].strip_edges()] = split[1].strip_edges()
		
		return self
	
	func default_user_agent() -> RequestBuilder:
		return header_line(DEFAULT_USER_AGENT)

	func default_accept_all() -> RequestBuilder:
		return header_line(DEFAULT_ACCEPT_ALL)
	
	#endregion
	
	func data(p_data) -> RequestBuilder:
		data = p_data
		return self
	
	func build() -> Request:
		var request := Request.new()
		
		if not _verify():
			printerr("Invalid data, returning empty request")
			return request
		
		request.base_url = base_url
		request.port = port
		request.use_ssl = use_ssl
		request.verify_host = verify_host
		request.uri = "/%s" % uri
		request.request_type = request_type
		for key in headers.keys():
			request.headers.append("%s: %s" % [key, headers[key]])
		match typeof(data):
			TYPE_NIL:
				pass
			TYPE_DICTIONARY, TYPE_ARRAY, TYPE_COLOR_ARRAY, TYPE_INT_ARRAY, TYPE_REAL_ARRAY, \
			TYPE_STRING_ARRAY, TYPE_VECTOR2_ARRAY, TYPE_VECTOR3_ARRAY:
				request.data = JSON.print(data)
			TYPE_STRING:
				request.data = data
			_:
				printerr("Unhandled data type for request: %s" % str(data))
		
		return request

class Response:
	var code: int = -1
	var headers := {}
	var body := PoolByteArray()
	
	func _to_string() -> String:
		return ("""
---Response---
response code:
%d
headers:
%s
body:
%s
		""" % [
			code,
			JSON.print(headers, "\t"),
			body.get_string_from_ascii()
		]).strip_edges()

#-----------------------------------------------------------------------------#
# Builtin functions                                                           #
#-----------------------------------------------------------------------------#

#-----------------------------------------------------------------------------#
# Connections                                                                 #
#-----------------------------------------------------------------------------#

#-----------------------------------------------------------------------------#
# Private functions                                                           #
#-----------------------------------------------------------------------------#

#-----------------------------------------------------------------------------#
# Public functions                                                            #
#-----------------------------------------------------------------------------#

static func create(url: String) -> RequestBuilder:
	return RequestBuilder.new(url)
