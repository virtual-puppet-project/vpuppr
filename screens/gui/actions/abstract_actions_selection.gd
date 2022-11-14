class_name AbstractActionsSelection
extends VBoxContainer

var action := Action.new()

#-----------------------------------------------------------------------------#
# Builtin functions                                                           #
#-----------------------------------------------------------------------------#

#-----------------------------------------------------------------------------#
# Connections                                                                 #
#-----------------------------------------------------------------------------#

func _on_from_value_changed(value) -> void:
	action.from_value = value

func _on_to_value_changed(value) -> void:
	action.to_value = value

func _on_tween_time_changed(value: float) -> void:
	action.tween_time = value

func _on_tween_transition_changed(transition_type: int) -> void:
	action.tween_transition = transition_type

func _on_tween_easing_changed(easing_type: int) -> void:
	action.tween_easing = easing_type

#-----------------------------------------------------------------------------#
# Private functions                                                           #
#-----------------------------------------------------------------------------#

#-----------------------------------------------------------------------------#
# Public functions                                                            #
#-----------------------------------------------------------------------------#

func connect_from_to(control: Control) -> void:
	control.connect("from_changed", self, "_on_from_value_changed")
	control.connect("to_changed", self, "_on_to_value_changed")

func connect_tween(control: Control) -> void:
	control.connect("time_changed", self, "_on_tween_time_changed")
	control.connect("transition_changed", self, "_on_tween_transition_changed")
	control.connect("easing_changed", self, "_on_tween_easing_changed")

func get_action() -> Action:
	return action
