extends Node

enum ListenerTypes {
	NONE = 0,

	REST,
	WEBSOCKET,
	UDP
}

var logger := Logger.new("RemoteControlServerHandler")

var server
var connection
var thread: Thread
var stop_server := true
var poll_interval: int = 100

var _scene_tree: SceneTree

#-----------------------------------------------------------------------------#
# Builtin functions                                                           #
#-----------------------------------------------------------------------------#

func _init(p_server: GDScript, port: int, p_poll_interval: float) -> void:
	_scene_tree = Engine.get_main_loop()

	poll_interval = int(p_poll_interval * 1000)

	thread = Thread.new()
	stop_server = false

	server = p_server.new(logger)
	server.listen(port)

	thread.start(self, "_perform_reception")

func _exit_tree() -> void:
	if thread != null:
		stop(true)

#-----------------------------------------------------------------------------#
# Connections                                                                 #
#-----------------------------------------------------------------------------#

#-----------------------------------------------------------------------------#
# Private functions                                                           #
#-----------------------------------------------------------------------------#

func _perform_reception() -> void:
	while not stop_server:
		server.poll()
		OS.delay_msec(poll_interval)

	server.shutdown()

func _perform_reception_websocket() -> void:
	while not stop_server:
		server.poll()
		yield(_scene_tree.create_timer(poll_interval), "timeout")

func _perform_reception_udp() -> void:
	while not stop_server:
		server.poll()
		yield(_scene_tree.create_timer(poll_interval), "timeout")

func _perform_reception_tcp() -> void:
	while not stop_server:
		pass

	pass

#-----------------------------------------------------------------------------#
# Public functions                                                            #
#-----------------------------------------------------------------------------#

func stop(force: bool = false) -> void:
	stop_server = true
	if not force:
		yield(get_tree(), "idle_frame")
		while thread.is_alive():
			yield(get_tree(), "idle_frame")
	thread.wait_to_finish()
	
	thread = null
	server = null
