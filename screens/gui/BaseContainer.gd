class_name BaseContainer
extends MarginContainer

onready var outer: VBoxContainer = $MarginContainer/Outer
onready var inner: VBoxContainer = $MarginContainer/Outer/ScrollContainer/Inner

###############################################################################
# Builtin functions                                                           #
###############################################################################

###############################################################################
# Connections                                                                 #
###############################################################################

###############################################################################
# Private functions                                                           #
###############################################################################

###############################################################################
# Public functions                                                            #
###############################################################################

func add_to_outer(value: Control, outer_position: int = 0) -> void:
	outer.add_child(value)
	outer.move_child(value, outer_position)

func add_to_inner(value: Control) -> void:
	inner.add_child(value)

func get_inner_children() -> Array:
	return inner.get_children()

func clear_children() -> void:
	for c in inner.get_children():
		c.free()
