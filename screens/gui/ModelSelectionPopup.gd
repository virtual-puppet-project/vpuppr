extends FileDialog

export(AppManager.ModelType) var model_type

###############################################################################
# Builtin functions                                                           #
###############################################################################

func _ready() -> void:
	if model_type == null:
		push_error("Model type not specified when trying to load new model")
	
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
	AppManager.set_file_to_load(file_path, model_type)

func _on_popup_hide() -> void:
	queue_free()

###############################################################################
# Private functions                                                           #
###############################################################################

###############################################################################
# Public functions                                                            #
###############################################################################


