extends CanvasLayer

#-----------------------------------------------------------------------------#
# Builtin functions                                                           #
#-----------------------------------------------------------------------------#

func _ready() -> void:
	OS.window_size = OS.get_screen_size() * 0.75
	OS.center_window()
	
	var base := $Base as Control
	base.connect("gui_input", self, "_on_base_gui_input")

#-----------------------------------------------------------------------------#
# Connections                                                                 #
#-----------------------------------------------------------------------------#

func _on_base_gui_input(event: InputEvent) -> void:
	if not event is InputEventMouseButton and not InputEventKey:
		return
	if event is InputEventMouseMotion:
		return
	
	if event.pressed:
		_switch_to_landing_screen()

#-----------------------------------------------------------------------------#
# Private functions                                                           #
#-----------------------------------------------------------------------------#

func _switch_to_landing_screen() -> void:
	get_tree().change_scene(Globals.LANDING_SCREEN_PATH)

#-----------------------------------------------------------------------------#
# Public functions                                                            #
#-----------------------------------------------------------------------------#
