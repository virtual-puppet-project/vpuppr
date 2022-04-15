class_name LogManager
extends AbstractManager

const LOG_MAX: int = 100000

var logs := []

var _timer := Timer.new()

###############################################################################
# Builtin functions                                                           #
###############################################################################

func _init() -> void:
	pass

func _setup_logger() -> void:
	logger = Logger.new("LogManager")

func _setup_class() -> void:
	_timer.connect("timeout", self, "_on_timeout")
	_timer.autostart = true
	_timer.one_shot = false
	AM.add_child(_timer)

	AM.ps.connect("logger_rebroadcast", self, "_on_log_received")

###############################################################################
# Connections                                                                 #
###############################################################################

func _on_log_received(text: String) -> void:
	logs.append(text)

func _on_timeout() -> void:
	if logs.size() > LOG_MAX:
		logger.error("Max log size of %d reached, this is probably a bug" % LOG_MAX)
		# TODO add notification popup

###############################################################################
# Private functions                                                           #
###############################################################################

###############################################################################
# Public functions                                                            #
###############################################################################
