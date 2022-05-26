extends VBoxContainer

## The path of godot.log for the application
const GODOT_LOG_PATH := "user://logs/godot.log"

onready var logs = $Logs as TextEdit

#-----------------------------------------------------------------------------#
# Builtin functions                                                           #
#-----------------------------------------------------------------------------#

func _ready() -> void:
	for i in AM.lm.logs:
		_add_log(i)
	
	AM.ps.subscribe(self, GlobalConstants.EVENT_PUBLISHED)
	
	logs.add_keyword_color("INFO", Color.aquamarine)
	logs.add_keyword_color("DEBUG", Color.gold)
	logs.add_keyword_color("TRACE", Color.blue)
	logs.add_keyword_color("ERROR", Color.red)
	
	$HBoxContainer/Copy.connect("pressed", self, "_on_copy")
	$HBoxContainer/Open.connect("pressed", self, "_on_open")

#-----------------------------------------------------------------------------#
# Connections                                                                 #
#-----------------------------------------------------------------------------#

func _on_event_published(payload: SignalPayload) -> void:
	if payload.signal_name != GlobalConstants.MESSAGE_LOGGED:
		return
	
	_add_log(payload.data)

## Copies the logs to the system clipboard
func _on_copy() -> void:
	OS.clipboard = logs.text

## Opens the godot.log file in the system's native text editor
func _on_open() -> void:
	OS.shell_open(ProjectSettings.globalize_path(GODOT_LOG_PATH))

#-----------------------------------------------------------------------------#
# Private functions                                                           #
#-----------------------------------------------------------------------------#

func _add_log(text: String) -> void:
	logs.text += "%s\n" % text

#-----------------------------------------------------------------------------#
# Public functions                                                            #
#-----------------------------------------------------------------------------#
