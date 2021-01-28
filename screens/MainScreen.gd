extends Spatial

const DEV_UI: Resource = preload("res://utils/gui/DevUI.tscn")

var debug: bool = true

###############################################################################
# Builtin functions                                                           #
###############################################################################

func _ready() -> void:
	get_viewport().transparent_bg = true
	
	if OS.has_feature("standalone"):
		debug = false
	if debug:
		var dev_ui: Control = DEV_UI.instance()
		self.add_child(dev_ui)

func _input(event: InputEvent) -> void:
	if(event.is_action_pressed("ui_cancel") and debug):
		get_tree().quit()

###############################################################################
# Connections                                                                 #
###############################################################################

###############################################################################
# Private functions                                                           #
###############################################################################

###############################################################################
# Public functions                                                            #
###############################################################################


