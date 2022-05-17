class_name Logger
extends Reference

signal message_logged(message)

enum LogType { NONE, NOTIFY, INFO, DEBUG, TRACE, ERROR }
enum NotifyType { NONE, TOAST, POPUP }

var parent_name := "DefaultLogger"

#-----------------------------------------------------------------------------#
# Builtin functions                                                           #
#-----------------------------------------------------------------------------#

func _init(v = null):
	if v != null:
		setup(v)

#-----------------------------------------------------------------------------#
# Connections                                                                 #
#-----------------------------------------------------------------------------#

#-----------------------------------------------------------------------------#
# Private functions                                                           #
#-----------------------------------------------------------------------------#

func _log(message: String, log_type: int) -> void:
	var datetime: Dictionary = OS.get_datetime()
	message = "%s %s-%s-%s_%s:%s:%s %s" % [
		parent_name,
		datetime["year"],
		datetime["month"],
		datetime["day"],
		datetime["hour"],
		datetime["minute"],
		datetime["second"],
		message
	]
	
	match log_type:
		LogType.INFO, LogType.NOTIFY:
			message = "[INFO] %s" % message
		LogType.DEBUG:
			message = "[DEBUG] %s" % message
		LogType.TRACE:
			message = "[TRACE] %s" % message
			var stack_trace: Array = get_stack()
			for i in stack_trace.size() - 2:
				var data: Dictionary = stack_trace[i + 2]
				message = "%s\n\t%d - %s:%d - %s" % [
					message, i, data["source"], data["line"], data["function"]]
		LogType.ERROR:
			message = "[ERROR] %s" % message

	print(message)
	emit_signal("message_logged", message)

#-----------------------------------------------------------------------------#
# Public functions                                                            #
#-----------------------------------------------------------------------------#

func setup(n) -> void:
	# Sometimes we initialize too quickly
	while AM.ps == null:
		yield(AM.get_tree(), "idle_frame")
	connect("message_logged", AM.ps, "broadcast_logger_rebroadcast")

	if typeof(n) == TYPE_STRING:
		parent_name = n
	elif n.get_script():
		parent_name = n.get_script().resource_path.get_file()
	elif n.get("name"):
		parent_name = n.name
	else:
		trace("Unable to setup logger using var: %s" % str(n))

func notify(message: String, notify_type: int = NotifyType.TOAST) -> void:
	_log(message, LogType.NOTIFY)
	match notify_type:
		NotifyType.TOAST:
			AM.nm.show_toast(message)
		NotifyType.POPUP:
			AM.nm.show_popup(message)
		_:
			assert(false, message)

func info(message: String) -> void:
	_log(message, LogType.INFO)

func debug(message: String) -> void:
	if OS.is_debug_build():
		_log(message, LogType.DEBUG)

func trace(message: String) -> void:
	if OS.is_debug_build():
		_log(message, LogType.TRACE)

func error(message: String) -> void:
	_log(message, LogType.ERROR)
