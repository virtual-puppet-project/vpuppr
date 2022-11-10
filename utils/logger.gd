class_name Logger
extends Reference

enum LogType { NONE, NOTIFY, INFO, DEBUG, TRACE, ERROR }
enum NotifyType { NONE, TOAST, POPUP }

var parent_name := "DefaultLogger"
var all_logs := false

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
	var datetime: Dictionary = Time.get_datetime_dict_from_system()
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
	AM.ps.publish(Globals.MESSAGE_LOGGED, message)

#-----------------------------------------------------------------------------#
# Public functions                                                            #
#-----------------------------------------------------------------------------#

func setup(n) -> void:
	if typeof(n) == TYPE_STRING:
		parent_name = n
	elif n.get_script():
		parent_name = n.get_script().resource_path.get_file()
	elif n.get("name"):
		parent_name = n.name
	else:
		trace("Unable to setup logger using var: %s" % str(n))
	
	all_logs = AM.all_logs

func notify(message, notify_type: int = NotifyType.TOAST) -> void:
	var text := str(message)
	_log(text, LogType.NOTIFY)
	match notify_type:
		NotifyType.TOAST:
			AM.nm.show_toast(text)
		NotifyType.POPUP:
			AM.nm.show_popup(text)
		_:
			assert(false, text)

func info(message) -> void:
	_log(str(message), LogType.INFO)

func debug(message) -> void:
	if all_logs or OS.is_debug_build():
		_log(str(message), LogType.DEBUG)

func trace(message) -> void:
	if all_logs or OS.is_debug_build():
		_log(str(message), LogType.TRACE)

func error(message) -> void:
	_log(str(message), LogType.ERROR)
