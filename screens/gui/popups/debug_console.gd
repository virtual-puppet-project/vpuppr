extends VBoxContainer

const AE = preload("res://addons/advanced-expression/advanced_expression.gd")

onready var output = $Output as TextEdit
onready var input = $Input as LineEdit

var _env := {}

###############################################################################
# Builtin functions                                                           #
###############################################################################

func _ready() -> void:
	input.connect("text_entered", self, "_on_enter")

###############################################################################
# Connections                                                                 #
###############################################################################

func _on_enter(text: String) -> void:
	# TODO implement using AdvancedExpression
	# Store results in _env and add interface for accessing
	pass

###############################################################################
# Private functions                                                           #
###############################################################################

###############################################################################
# Public functions                                                            #
###############################################################################
