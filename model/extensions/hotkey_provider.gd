class_name HotkeyProvider
extends Reference

## @param: action_name: String
signal action_pressed(action_name)

var logger: Logger

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

func register_action(action_name: String, keys: Array) -> Result:
	return Safely.err(Error.Code.NOT_YET_IMPLEMENTED, "HotkeyProvider::register_action(%s, %s)" %
			[action_name, str(keys)])

func unregister_action(action_name: String, keys: Array) -> Result:
	return Safely.err(Error.Code.NOT_YET_IMPLEMENTED, "HotkeyProvider::unregister_action(%s, %s)" %
			[action_name, str(keys)])

## Get an un-popped-up popup to configure one sequence of hotkeys.
## Should emit a signal called `dialog_complete` when done.
func get_hotkey_input_popup() -> Result:
	return Safely.err(Error.Code.NOT_YET_IMPLEMENTED, "HotkeyProvider::get_hotkey_input_popup")

func setup_hotkeys() -> Result:
	

	return Safely.ok()
