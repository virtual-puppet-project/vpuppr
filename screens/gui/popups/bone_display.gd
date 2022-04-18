extends ScrollContainer

var options_list := VBoxContainer.new()

var is_tracking_button := CheckButton.new()
var should_pose_button := CheckButton.new()

var interpolation_rate := LineEdit.new()

###############################################################################
# Builtin functions                                                           #
###############################################################################

func _init(bone_name: String) -> void:
	name = bone_name
	
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

###############################################################################
# Private functions                                                           #
###############################################################################

###############################################################################
# Public functions                                                            #
###############################################################################
