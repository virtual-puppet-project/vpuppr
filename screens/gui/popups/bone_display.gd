extends ScrollContainer

"""
Represents the configuration data for one bone for a given model
"""

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

	var options_list := VBoxContainer.new()
	
	options_list.size_flags_horizontal = Control.SIZE_EXPAND_FILL
	options_list.size_flags_vertical = Control.SIZE_EXPAND_FILL

	var bone_name_label := Label.new()
	bone_name_label.text = bone_name
	bone_name_label.align = Label.ALIGN_CENTER

	options_list.add_child(bone_name_label)

	is_tracking_button.text = "Is tracking"
	options_list.add_child(is_tracking_button)

	should_pose_button.text = "Should pose"
	options_list.add_child(should_pose_button)

	#region Interpolation rate

	should_use_custom_interpolation.text = "Use custom interpolation"
	options_list.add_child(should_use_custom_interpolation)

	var hbox := HBoxContainer.new()
	hbox.size_flags_horizontal = Control.SIZE_EXPAND_FILL

	var interpolation_label := Label.new()
	interpolation_label.text = "Interpolation rate"
	interpolation_label.size_flags_horizontal = Control.SIZE_EXPAND_FILL

	hbox.add_child(interpolation_label)

	interpolation_rate.size_flags_horizontal = Control.SIZE_EXPAND_FILL
	
	hbox.add_child(interpolation_rate)

	options_list.add_child(hbox)

	#endregion

	add_child(options_list)

###############################################################################
# Connections                                                                 #
###############################################################################

# TODO stub, this is wrong
func _on_bone_updated(value, signal_name: String, bone_name: String) -> void:
	if bone_name != name:
		return
	
	

###############################################################################
# Private functions                                                           #
###############################################################################

###############################################################################
# Public functions                                                            #
###############################################################################
