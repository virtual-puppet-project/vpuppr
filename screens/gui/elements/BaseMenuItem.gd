class_name BaseMenuItem
extends MarginContainer

onready var label: Label = $HBoxContainer/Label
onready var color_rect: ColorRect = $ColorRect

var label_text: String = "changeme"

var starting_color: Color
var mouseover_color: Color
var mouse_color_scale: float = 1.5
var selected_color: Color
var selected_color_scale: float = 1.2

var is_selectable: bool = false
var is_selected: bool = false

###############################################################################
# Builtin functions                                                           #
###############################################################################

func _ready() -> void:
	label.text = label_text
	
	starting_color = color_rect.color
	mouseover_color = starting_color * mouse_color_scale
	selected_color = mouseover_color * selected_color_scale
	
	self.connect("mouse_entered", self, "_on_mouse_entered")
	self.connect("mouse_exited", self, "_on_mouse_exited")

func _input(event: InputEvent) -> void:
	if(event.is_action_pressed("left_click") and not Input.is_action_pressed("allow_move_model")):
		if is_selectable:
			_set_is_selected(not is_selected)
		else:
			_set_is_selected(false)

###############################################################################
# Connections                                                                 #
###############################################################################

func _on_mouse_entered() -> void:
	if not is_selected:
		color_rect.color = mouseover_color
	is_selectable = true

func _on_mouse_exited() -> void:
	if not is_selected:
		color_rect.color = starting_color
	is_selectable = false

###############################################################################
# Private functions                                                           #
###############################################################################

func _set_is_selected(v: bool) -> void:
	is_selected = v
	if is_selected:
		color_rect.color = selected_color
	else:
		if is_selectable:
			color_rect.color = mouseover_color
		else:
			color_rect.color = starting_color

###############################################################################
# Public functions                                                            #
###############################################################################


