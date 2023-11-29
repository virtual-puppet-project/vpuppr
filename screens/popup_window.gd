class_name PopupWindow
extends Window

signal message_received(message: GUIMessage)

const BG_COLOR := Color("1d2229")
const UPDATE := &"update"

var gui: Node = null

var _logger: Logger = null

#-----------------------------------------------------------------------------#
# Builtin functions
#-----------------------------------------------------------------------------#

func _init(window_name: StringName, p_gui: Node) -> void:
	_logger = Logger.create("Popup::{window_name}".format({window_name = window_name}))
	
	gui = p_gui
	
	gui.set("window", self)
	if gui.has_signal(message_received.get_name()):
		gui.message_received.connect(func(message: GUIMessage) -> void:
			message_received.emit(message)
		)
	
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
	
	# Pretend like the inner gui is requesting an update
	focus_entered.connect(func() -> void:
		if gui.has_method(&"update"):
			message_received.emit(GUIMessage.new(gui, GUIMessage.REQUEST_UPDATE))
	)

#-----------------------------------------------------------------------------#
# Private functions
#-----------------------------------------------------------------------------#

#-----------------------------------------------------------------------------#
# Public functions
#-----------------------------------------------------------------------------#
