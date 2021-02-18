extends MarginContainer

onready var label: Label = $HBoxContainer/Label
onready var line_edit: LineEdit = $HBoxContainer/LineEdit
onready var color_rect: ColorRect = $ColorRect

var label_text: String = "changeme"
var line_edit_text: String = "changeme"

var starting_color: Color
var mouseover_color: Color

###############################################################################
# Builtin functions                                                           #
###############################################################################

func _ready() -> void:
	label.text = label_text
	
	line_edit.text = line_edit_text
	
	starting_color = color_rect.color
	mouseover_color = starting_color
	mouseover_color *= 1.5
	
	self.connect("mouse_entered", self, "_on_mouse_entered")
	self.connect("mouse_exited", self, "_on_mouse_exited")

###############################################################################
# Connections                                                                 #
###############################################################################

func _on_mouse_entered() -> void:
	color_rect.color = mouseover_color

func _on_mouse_exited() -> void:
	color_rect.color = starting_color

###############################################################################
# Private functions                                                           #
###############################################################################

###############################################################################
# Public functions                                                            #
###############################################################################


