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

func add_to_outer(value: Control) -> void:
	outer.add_child(value)

func add_to_inner(value: Control) -> void:
	inner.add_child(value)

func get_inner_children() -> Array:
	return inner.get_children()

func clear_children() -> void:
	for c in inner.get_children():
		c.free()
