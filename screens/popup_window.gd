extends Window
class_name PopupWindow

const BG_COLOR := Color("1d2229")

#-----------------------------------------------------------------------------#
# Builtin functions
#-----------------------------------------------------------------------------#

func _init(window_name: StringName, gui: Node) -> void:
	gui.set("window", self)
	
	title = window_name
	
	var background := ColorRect.new()
	background.set_anchors_preset(Control.PRESET_FULL_RECT)
	background.color = BG_COLOR
	
	var panel_container := PanelContainer.new()
	panel_container.set_anchors_preset(Control.PRESET_FULL_RECT)
	panel_container.theme = preload("res://assets/main.theme")
	
	panel_container.add_child(gui)
	add_child(panel_container)
	
	# TODO this is probably not great
	close_requested.connect(func(_data: Variant = null) -> void:
		queue_free()
	)
	visibility_changed.connect(func() -> void:
		if not visible:
			close_requested.emit()
	)

#-----------------------------------------------------------------------------#
# Private functions
#-----------------------------------------------------------------------------#

#-----------------------------------------------------------------------------#
# Public functions
#-----------------------------------------------------------------------------#

