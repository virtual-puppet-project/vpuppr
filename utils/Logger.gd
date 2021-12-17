class_name Logger
extends Reference

signal on_log(message)

enum LogType { NONE, NOTIFY, INFO, DEBUG, TRACE, ERROR }
enum NotifyType { NONE, TOAST, POPUP }

###############################################################################
# Builtin functions                                                           #
###############################################################################

###############################################################################
# Connections                                                                 #
###############################################################################

###############################################################################
# Private functions                                                           #
###############################################################################

# TODO add support for log levels
func _log(message: String, log_type: int) -> void:
	var datetime: Dictionary = OS.get_datetime()
	message = "%s-%s-%s_%s:%s:%s %s" % [
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
			assert(false, message)

	print(message)
	emit_signal("on_log", message)

###############################################################################
# Public functions                                                            #
###############################################################################

func notify(message: String, notify_type: int = NotifyType.TOAST) -> void:
	_log(message, LogType.NOTIFY)
	match notify_type:
		NotifyType.TOAST:
			AppManager.nm.show_toast(message)
		NotifyType.POPUP:
			AppManager.nm.show_popup(message)
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
