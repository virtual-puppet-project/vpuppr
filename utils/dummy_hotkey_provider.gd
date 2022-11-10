class_name DummyHotkeyProvider
extends HotkeyProvider

#-----------------------------------------------------------------------------#
# Builtin functions                                                           #
#-----------------------------------------------------------------------------#

func _init() -> void:
	logger = Logger.new("DummyHotkeyProvider")

#-----------------------------------------------------------------------------#
# Connections                                                                 #
#-----------------------------------------------------------------------------#

#-----------------------------------------------------------------------------#
# Private functions                                                           #
#-----------------------------------------------------------------------------#

#-----------------------------------------------------------------------------#
# Public functions                                                            #
#-----------------------------------------------------------------------------#

func register_action(action_name: String, keys: Array) -> Result:
	logger.error("Dummy cannot register %s for keys %s" % [action_name, str(keys)])
	return Safely.ok()

func unregister_action(action_name: String, keys: Array) -> Result:
	logger.error("Dummy cannot unregister %s for keys %s" % [action_name, str(keys)])
	return Safely.ok()

func get_hotkey_input_popup() -> Result:
	logger.error("Dummy cannot get hotkey input popup")
	return Safely.ok()
