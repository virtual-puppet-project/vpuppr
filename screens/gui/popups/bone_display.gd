extends ScrollContainer

"""
Represents the configuration data for one bone for a given model
"""

signal is_tracking_set(bone_name, state)
signal should_pose_set(bone_name, state)
signal should_use_custom_interpolation_set(bone_name, state)
signal interpolation_rate_set(bone_name, rate)

var options_list := VBoxContainer.new()

# Whether or not to apply tracking data to the bone
var is_tracking_button := CheckButton.new()
# Whether or not to consider user input as bone-pose input
var should_pose_button := CheckButton.new()
# When tracking the bone, whether or not to use the global interpolation rate
var should_use_custom_interpolation := CheckButton.new()
# Interpolation rate to use when applying tracking data
var interpolation_rate := LineEdit.new()

###############################################################################
# Builtin functions                                                           #
###############################################################################

func _init(bone_name: String) -> void:
	name = bone_name
	visible = false
	
	options_list.size_flags_horizontal = Control.SIZE_EXPAND_FILL
	options_list.size_flags_vertical = Control.SIZE_EXPAND_FILL

	var bone_name_label := Label.new()
	bone_name_label.text = bone_name
	bone_name_label.align = Label.ALIGN_CENTER

	options_list.add_child(bone_name_label)

	is_tracking_button.text = "Is tracking"
	is_tracking_button.connect("toggled", self, "_on_is_tracking_toggled")
	options_list.add_child(is_tracking_button)

	should_pose_button.text = "Should pose"
	should_pose_button.connect("toggled", self, "_on_should_pose_toggled")
	options_list.add_child(should_pose_button)

	#region Interpolation rate

	should_use_custom_interpolation.text = "Use custom interpolation"
	should_use_custom_interpolation.connect("toggled", self, "_on_should_use_custom_interpolation_set")
	options_list.add_child(should_use_custom_interpolation)

	var hbox := HBoxContainer.new()
	hbox.size_flags_horizontal = Control.SIZE_EXPAND_FILL

	var interpolation_label := Label.new()
	interpolation_label.text = "Interpolation rate"
	interpolation_label.size_flags_horizontal = Control.SIZE_EXPAND_FILL

	hbox.add_child(interpolation_label)

	interpolation_rate.size_flags_horizontal = Control.SIZE_EXPAND_FILL
	interpolation_rate.connect("text_entered", self, "_on_interpolation_rate_set")
	interpolation_rate.connect("text_changed", self, "_on_interpolation_rate_changed")
	
	hbox.add_child(interpolation_rate)

	options_list.add_child(hbox)

	#endregion

	add_child(options_list)

###############################################################################
# Connections                                                                 #
###############################################################################

func _on_is_tracking_toggled(state: bool) -> void:
	emit_signal("is_tracking_set", name, state)

func _on_should_pose_toggled(state: bool) -> void:
	emit_signal("should_pose_set", name, state)

func _on_should_use_custom_interpolation_set(state: bool) -> void:
	emit_signal("should_use_custom_interpolation_set", name, state)

func _on_interpolation_rate_changed(text: String) -> void:
	if not text.is_valid_float():
		return

	emit_signal("interpolation_rate_set", name, text.to_float())

func _on_interpolation_rate_set(text: String) -> void:
	_on_interpolation_rate_changed(text)

###############################################################################
# Private functions                                                           #
###############################################################################

###############################################################################
# Public functions                                                            #
###############################################################################
