class_name HotkeyManager
extends AbstractManager

var from_time: int = Time.get_ticks_msec()
var current_time: int = from_time
var elapsed_time: int = current_time - from_time

#-----------------------------------------------------------------------------#
# Builtin functions                                                           #
#-----------------------------------------------------------------------------#

func _init() -> void:
	pass

func _setup_logger() -> void:
	logger = Logger.new("HotkeyManager")

func _setup_class() -> void:
	yield(AM, "ready")
	
	var res: Result = Safely.wrap(AM.cm.get_data("hotkey_config"))
	if res.is_err():
		logger.error(res.to_string())
		return
	
	var hotkey_config: Dictionary = res.unwrap()
	
	# TODO stub

#-----------------------------------------------------------------------------#
# Connections                                                                 #
#-----------------------------------------------------------------------------#

func _on_hotkey_pressed(key: String) -> void:
	pass

#-----------------------------------------------------------------------------#
# Private functions                                                           #
#-----------------------------------------------------------------------------#

#-----------------------------------------------------------------------------#
# Public functions                                                            #
#-----------------------------------------------------------------------------#

func setup(instance: Object, signal_name: String) -> void:
	instance.connect(signal_name, self, "hotkey_pressed")
