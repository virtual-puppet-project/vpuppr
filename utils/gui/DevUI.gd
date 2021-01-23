extends Control

onready var fps_label: Label = $CanvasLayer/ColorRect/InfoContainer/VBoxContainer/FPSLabel
onready var translation_label: Label = $CanvasLayer/ColorRect/InfoContainer/VBoxContainer/TranslationLabel
onready var quat_label: Label = $CanvasLayer/ColorRect/InfoContainer/VBoxContainer/QuatLabel

###############################################################################
# Builtin functions                                                           #
###############################################################################

func _process(_delta: float) -> void:
	fps_label.text = "FPS: " + str(Engine.get_frames_per_second())
	
	var s = get_parent().get_node("OpenSeeShowPointsGD")
	if s:
		translation_label.text = "Translation: " + str(s.current_translation)
		quat_label.text = "Quaternion: " + str(s.current_quat)

###############################################################################
# Connections                                                                 #
###############################################################################

###############################################################################
# Private functions                                                           #
###############################################################################

###############################################################################
# Public functions                                                            #
###############################################################################


