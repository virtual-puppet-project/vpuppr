extends VBoxContainer

#-----------------------------------------------------------------------------#
# Builtin functions                                                           #
#-----------------------------------------------------------------------------#

func _init() -> void:
	pass

func _ready() -> void:
	var from_to_options: Control = $FromToOptions
	from_to_options.connect("from_changed", self, "_on_from_value_changed")
	from_to_options.connect("to_changed", self, "_on_to_value_changed")
	
	var tween_options: Control = $TweenOptions
	tween_options.connect("time_changed", self, "_on_tween_time_changed")
	tween_options.connect("transition_changed", self, "_on_tween_transition_changed")
	tween_options.connect("easing_changed", self, "_on_tween_easing_changed")

#-----------------------------------------------------------------------------#
# Connections                                                                 #
#-----------------------------------------------------------------------------#

func _on_from_value_changed(value: float) -> void:
	pass

func _on_to_value_changed(value: float) -> void:
	pass

func _on_tween_time_changed(value: float) -> void:
	pass

func _on_tween_transition_changed(transition_type: int) -> void:
	pass

func _on_tween_easing_changed(easing_type: int) -> void:
	pass

#-----------------------------------------------------------------------------#
# Private functions                                                           #
#-----------------------------------------------------------------------------#

#-----------------------------------------------------------------------------#
# Public functions                                                            #
#-----------------------------------------------------------------------------#
