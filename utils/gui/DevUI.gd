extends Control

onready var fps_label: Label = $CanvasLayer/ColorRect/InfoContainer/VBoxContainer/FPSLabel
onready var translation_label: Label = $CanvasLayer/ColorRect/InfoContainer/VBoxContainer/TranslationLabel
onready var quat_label: Label = $CanvasLayer/ColorRect/InfoContainer/VBoxContainer/QuatLabel
onready var euler_label: Label = $CanvasLayer/ColorRect/InfoContainer/VBoxContainer/EulerLabel

###############################################################################
# Builtin functions                                                           #
###############################################################################

func _process(_delta: float) -> void:
	fps_label.text = "FPS: " + str(Engine.get_frames_per_second())
	
	var s = get_parent().get_node_or_null("OpenSeeShowPointsGD")
	if(s and s.open_see_data):
		translation_label.text = "Translation: " + str(s.open_see_data.translation)
		quat_label.text = "Quaternion: " + str(s.open_see_data.raw_quaternion)
		euler_label.text = "Euler: " + str(s.open_see_data.raw_euler)

###############################################################################
# Connections                                                                 #
###############################################################################

###############################################################################
# Private functions                                                           #
###############################################################################

###############################################################################
# Public functions                                                            #
###############################################################################


