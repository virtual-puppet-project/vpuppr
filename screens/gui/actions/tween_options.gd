extends VBoxContainer

signal time_changed(value)
signal transition_changed(value)
signal easing_changed(value)

enum Type {
	NONE, TRANSITION, EASING
}

const DEFAULT_TRANSITION: int = 0
const Transitions := [
	[Tween.TRANS_LINEAR, "ACTIONS_TWEEN_OPTIONS_TRANS_LINEAR", "ACTIONS_TWEEN_OPTIONS_TRANS_LINEAR_HINT"],
	[Tween.TRANS_SINE, "ACTIONS_TWEEN_OPTIONS_TRANS_SINE", "ACTIONS_TWEEN_OPTIONS_TRANS_SINE_HINT"],
	[Tween.TRANS_QUINT, "ACTIONS_TWEEN_OPTIONS_TRANS_QUINT", "ACTIONS_TWEEN_OPTIONS_TRANS_QUINT_HINT"],
	[Tween.TRANS_QUART, "ACTIONS_TWEEN_OPTIONS_TRANS_QUART", "ACTIONS_TWEEN_OPTIONS_TRANS_QUART_HINT"],
	[Tween.TRANS_QUAD, "ACTIONS_TWEEN_OPTIONS_TRANS_QUAD", "ACTIONS_TWEEN_OPTIONS_TRANS_QUAD_HINT"],
	[Tween.TRANS_EXPO, "ACTIONS_TWEEN_OPTIONS_TRANS_EXPO", "ACTIONS_TWEEN_OPTIONS_TRANS_EXPO_HINT"],
	[Tween.TRANS_ELASTIC, "ACTIONS_TWEEN_OPTIONS_TRANS_ELASTIC", "ACTIONS_TWEEN_OPTIONS_TRANS_ELASTIC_HINT"],
	[Tween.TRANS_CUBIC, "ACTIONS_TWEEN_OPTIONS_TRANS_CUBIC", "ACTIONS_TWEEN_OPTIONS_TRANS_CUBIC_HINT"],
	[Tween.TRANS_CIRC, "ACTIONS_TWEEN_OPTIONS_TRANS_CIRC", "ACTIONS_TWEEN_OPTIONS_TRANS_CIRC_HINT"],
	[Tween.TRANS_BOUNCE, "ACTIONS_TWEEN_OPTIONS_TRANS_BOUNCE", "ACTIONS_TWEEN_OPTIONS_TRANS_BOUNCE_HINT"],
	[Tween.TRANS_BACK, "ACTIONS_TWEEN_OPTIONS_TRANS_BACK", "ACTIONS_TWEEN_OPTIONS_TRANS_BACK_HINT"]
]

const DEFAULT_EASING: int = 2
const Easings := [
	[Tween.EASE_IN, "ACTIONS_TWEEN_OPTIONS_EASE_IN", "ACTIONS_TWEEN_OPTIONS_EASE_IN_HINT"],
	[Tween.EASE_OUT, "ACTIONS_TWEEN_OPTIONS_EASE_OUT", "ACTIONS_TWEEN_OPTIONS_EASE_OUT_HINT"],
	[Tween.EASE_IN_OUT, "ACTIONS_TWEEN_OPTIONS_EASE_IN_OUT", "ACTIONS_TWEEN_OPTIONS_EASE_IN_OUT_HINT"],
	[Tween.EASE_OUT_IN, "ACTIONS_TWEEN_OPTIONS_EASE_OUT_IN", "ACTIONS_TWEEN_OPTIONS_EASE_OUT_IN_HINT"]
]

#-----------------------------------------------------------------------------#
# Builtin functions                                                           #
#-----------------------------------------------------------------------------#

# TODO need a way to load values if reading from config
func _ready() -> void:
	$Time/LineEdit.connect("text_changed", self, "_on_line_edit_text_changed")
	
	var transition_select := $TransitionSelect
	for i in Transitions:
		transition_select.add_item(i[1])
	transition_select.connect("item_selected", self, "_on_option_button_item_selected",
		[Type.TRANSITION, transition_select])
	_on_option_button_item_selected(DEFAULT_TRANSITION, Type.TRANSITION, transition_select)
	
	var easing_select := $EasingSelect
	for i in Easings:
		easing_select.add_item(i[1])
	easing_select.connect("item_selected", self, "_on_option_button_item_selected", [Type.EASING, easing_select])
	_on_option_button_item_selected(DEFAULT_EASING, Type.EASING, easing_select)

#-----------------------------------------------------------------------------#
# Connections                                                                 #
#-----------------------------------------------------------------------------#

func _on_line_edit_text_changed(text: String) -> void:
	if not text.is_valid_float():
		return
	
	emit_signal("time_changed", text.to_float())

func _on_option_button_item_selected(idx: int, type: int, option_button: OptionButton) -> void:
	var tuple := []
	match type:
		Type.TRANSITION:
			tuple.append_array(Transitions[idx])
			emit_signal("transition_changed", tuple[0])
		Type.EASING:
			tuple.append_array(Easings[idx])
			emit_signal("easing_changed", tuple[0])

	option_button.text = tuple[1]
	option_button.hint_tooltip = tuple[2]

#-----------------------------------------------------------------------------#
# Private functions                                                           #
#-----------------------------------------------------------------------------#

#-----------------------------------------------------------------------------#
# Public functions                                                            #
#-----------------------------------------------------------------------------#
