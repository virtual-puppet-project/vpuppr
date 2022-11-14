extends AbstractActionsSelection

export var should_goto := false

#-----------------------------------------------------------------------------#
# Builtin functions                                                           #
#-----------------------------------------------------------------------------#

func _ready() -> void:
	if should_goto:
		$Label.text = "DEFAULT_GUI_ACTIONS_POPUP_GOTO_LOCK_ACTION_LABEL"
		
		connect_from_to($List/FromToOptions)
		connect_tween($List/TweenOptions)
	else:
		$Label.text = "DEFAULT_GUI_ACTIONS_POPUP_LOCK_ACTION_LABEL"
		$List.hide()

#-----------------------------------------------------------------------------#
# Connections                                                                 #
#-----------------------------------------------------------------------------#

#-----------------------------------------------------------------------------#
# Private functions                                                           #
#-----------------------------------------------------------------------------#

#-----------------------------------------------------------------------------#
# Public functions                                                            #
#-----------------------------------------------------------------------------#
