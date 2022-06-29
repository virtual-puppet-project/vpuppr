class_name LogManager
extends AbstractManager

const LOG_MANAGER_NAME := "LogManager"

const LOG_MAX: int = 1_000_000

var logs := []

var _timer := Timer.new()

#-----------------------------------------------------------------------------#
# Builtin functions                                                           #
#-----------------------------------------------------------------------------#

func _init() -> void:
	pass

func _setup_logger() -> void:
	logger = Logger.new(LOG_MANAGER_NAME)

func _setup_class() -> void:
	_timer.connect("timeout", self, "_on_timeout")
	_timer.autostart = true
	_timer.one_shot = false
	AM.add_child(_timer)

	AM.ps.subscribe(self, GlobalConstants.EVENT_PUBLISHED)

#-----------------------------------------------------------------------------#
# Connections                                                                 #
#-----------------------------------------------------------------------------#

func _on_event_published(payload: SignalPayload) -> void:
	if payload.signal_name != GlobalConstants.MESSAGE_LOGGED:
		return
	
	logs.append(payload.data)

func _on_timeout() -> void:
	if logs.size() > LOG_MAX:
		logger.error("Max log size of %d reached, this is probably a bug" % LOG_MAX)
		# TODO add notification popup

#-----------------------------------------------------------------------------#
# Private functions                                                           #
#-----------------------------------------------------------------------------#

#-----------------------------------------------------------------------------#
# Public functions                                                            #
#-----------------------------------------------------------------------------#
