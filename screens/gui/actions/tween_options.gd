extends VBoxContainer

signal time_changed(value)
signal transition_changed(value)
signal easing_changed(value)

enum Type {
	NONE, TRANSITION, EASING
}

const Transitions := {
	"ACTIONS_TWEEN_OPTIONS_TRANS_LINEAR": Tween.TRANS_LINEAR,
	"ACTIONS_TWEEN_OPTIONS_TRANS_SINE": Tween.TRANS_SINE,
	"ACTIONS_TWEEN_OPTIONS_TRANS_QUINT": Tween.TRANS_QUINT,
	"ACTIONS_TWEEN_OPTIONS_TRANS_QUART": Tween.TRANS_QUART,
	"ACTIONS_TWEEN_OPTIONS_TRANS_QUAD": Tween.TRANS_QUAD,
	"ACTIONS_TWEEN_OPTIONS_TRANS_EXPO": Tween.TRANS_EXPO,
	"ACTIONS_TWEEN_OPTIONS_TRANS_ELASTIC": Tween.TRANS_ELASTIC,
	"ACTIONS_TWEEN_OPTIONS_TRANS_CUBIC": Tween.TRANS_CUBIC,
	"ACTIONS_TWEEN_OPTIONS_TRANS_CIRC": Tween.TRANS_CIRC,
	"ACTIONS_TWEEN_OPTIONS_TRANS_BOUNCE": Tween.TRANS_BOUNCE,
	"ACTIONS_TWEEN_OPTIONS_TRANS_BACK": Tween.TRANS_BACK
}

const Easing := {
	"ACTIONS_TWEEN_OPTIONS_EASE_IN": Tween.EASE_IN,
	"ACTIONS_TWEEN_OPTIONS_EASE_OUT": Tween.EASE_OUT,
	"ACTIONS_TWEEN_OPTIONS_EASE_IN_OUT": Tween.EASE_IN_OUT,
	"ACTIONS_TWEEN_OPTIONS_EASE_OUT_IN": Tween.EASE_OUT_IN
}

#-----------------------------------------------------------------------------#
# Builtin functions                                                           #
#-----------------------------------------------------------------------------#

# TODO need a way to load values if reading from config
func _ready() -> void:
	$Time/LineEdit.connect("text_changed", self, "_on_line_edit_text_changed")
	
	var transition_select := $TransitionSelect
	for i in Transitions.keys():
		transition_select.add_item(i)
	transition_select.connect("item_selected", self, "_on_option_button_item_selected",
		[Type.TRANSITION])
	transition_select.select(0)
	
	var easing_select := $EasingSelect
	for i in Easing.keys():
		easing_select.add_item(i)
	easing_select.connect("item_selected", self, "_on_option_button_item_selected", [Type.EASING])
	easing_select.select(0)

#-----------------------------------------------------------------------------#
# Connections                                                                 #
#-----------------------------------------------------------------------------#

#-----------------------------------------------------------------------------#
# Private functions                                                           #
#-----------------------------------------------------------------------------#

#-----------------------------------------------------------------------------#
# Public functions                                                            #
#-----------------------------------------------------------------------------#
