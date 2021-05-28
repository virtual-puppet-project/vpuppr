extends FileDialog

###############################################################################
# Builtin functions                                                           #
###############################################################################

func _ready() -> void:	
	self.current_dir = OS.get_executable_path().get_base_dir()
	self.current_path = self.current_dir
	
	self.connect("file_selected", self, "_on_file_selected")
	
	var screen_middle: Vector2 = Vector2(get_viewport_rect().size.x/2, get_viewport_rect().size.y/2)
	self.set_global_position(screen_middle)
	self.rect_size = screen_middle
	popup_centered(screen_middle)
	
	self.connect("popup_hide", self, "_on_popup_hide")

###############################################################################
# Connections                                                                 #
###############################################################################

func _on_file_selected(file_path: String) -> void:
	AppManager.set_file_to_load(file_path)

func _on_popup_hide() -> void:
	queue_free()

###############################################################################
# Private functions                                                           #
###############################################################################

###############################################################################
# Public functions                                                            #
###############################################################################


