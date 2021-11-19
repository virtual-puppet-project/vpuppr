class_name Logger
extends Reference

signal on_log(message)

###############################################################################
# Builtin functions                                                           #
###############################################################################

###############################################################################
# Connections                                                                 #
###############################################################################

###############################################################################
# Private functions                                                           #
###############################################################################
func _log(message: String, is_error: bool) -> void:
	if is_error:
		message = "[ERROR] %s" % message
		assert(false, message)
	print(message)
	emit_signal("on_log", message)

###############################################################################
# Public functions                                                            #
###############################################################################

func info(message: String) -> void:
	_log(message, false)

func error(message: String) -> void:
	_log(message, true)
