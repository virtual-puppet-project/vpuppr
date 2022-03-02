class_name LandingScreen
extends CanvasLayer

###############################################################################
# Builtin functions                                                           #
###############################################################################

func _ready() -> void:
	$RootControl/TabContainer/Runners/ScrollContainer/VBoxContainer/DefaultViewer.connect(
		"pressed",
		self,
		"_on_default_viewer_pressed"
	)

###############################################################################
# Connections                                                                 #
###############################################################################

func _on_default_viewer_pressed() -> void:
	get_tree().change_scene(GlobalConstants.DEFAULT_MODEL_VIEWER_PATH)

###############################################################################
# Private functions                                                           #
###############################################################################

###############################################################################
# Public functions                                                            #
###############################################################################
