class_name BasePopup
extends WindowDialog

var screen: Control

###############################################################################
# Builtin functions                                                           #
###############################################################################

func _init(p_name: String, p_screen: PackedScene) -> void:
	window_title = p_name
	resizable = true
#	popup_exclusive = true
	
	var panel_container := PanelContainer.new()
	
	var stylebox := StyleBoxFlat.new()
	stylebox.content_margin_top = 5
	stylebox.content_margin_bottom = 5
	stylebox.content_margin_left = 5
	stylebox.content_margin_right = 5
	stylebox.bg_color = Color("333a4f")
	
	panel_container.set_indexed("custom_styles/panel", stylebox)
	add_child(panel_container)
	
	screen = p_screen.instance()
	panel_container.add_child(screen)
	
	connect("mouse_entered", self, "_on_mouse_entered")
	connect("mouse_exited", self, "_on_mouse_exited")

func _ready() -> void:
#	popup_centered_ratio()
	show()
	
	var rect := Rect2()
	var window_size := get_viewport_rect().size
	rect.size = (window_size * 0.75).floor()
	rect.size.x *= 0.5
	rect.position = ((window_size - rect.size) / 2.0).floor()
	
	rect_global_position = rect.position
	rect_size = rect.size

###############################################################################
# Connections                                                                 #
###############################################################################

func _on_mouse_entered() -> void:
	print("entered")
	popup_exclusive = true

func _on_mouse_exited() -> void:
	print("exited")
	popup_exclusive = false

###############################################################################
# Private functions                                                           #
###############################################################################

###############################################################################
# Public functions                                                            #
###############################################################################
