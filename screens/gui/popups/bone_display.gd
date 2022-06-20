extends ScrollContainer

## Represents the configuration data for one bone for a given model
##
## @author: Tim Yuen

var logger: Logger

## Whether or not to apply tracking data to the bone
var is_tracking_button := CheckButton.new()
## Whether or not to consider user input as bone-pose input
var should_pose_button := CheckButton.new()
## When tracking the bone, whether or not to use the global interpolation rate
var should_use_custom_interpolation := CheckButton.new()
## Interpolation rate to use when applying tracking data
var interpolation_rate := LineEdit.new()
## Reset the pose of the bone
var reset_bone := Button.new()

#-----------------------------------------------------------------------------#
# Builtin functions                                                           #
#-----------------------------------------------------------------------------#

func _init(bone_name: String, p_logger: Logger) -> void:
	name = bone_name
	visible = false
	logger = p_logger

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

	reset_bone.text = "Reset bone pose"

	options_list.add_child(reset_bone)

	#endregion

	add_child(options_list)

#-----------------------------------------------------------------------------#
# Connections                                                                 #
#-----------------------------------------------------------------------------#

func _on_bone_updated(payload: SignalPayload, signal_name: String) -> void:
	if name != payload.id:
		return
	if not payload is SignalPayload:
		logger.error("Unexpected callback value %s" % str(payload))
		return

	match signal_name:
		"additional_bones":
			is_tracking_button.set_pressed_no_signal(payload.id in payload.data)
		"bones_to_interpolate":
			should_use_custom_interpolation.set_pressed_no_signal(payload.id in payload.data)
		"bone_interpolation_rates":
			var current_text := interpolation_rate.text
			if current_text.is_valid_float() and current_text.to_float() == payload.get_changed():
				return
			interpolation_rate.text = str(payload.get_changed())
			interpolation_rate.caret_position = interpolation_rate.text.length()

func _on_event_published(payload: SignalPayload) -> void:
	if payload.signal_name != GlobalConstants.POSE_BONE or payload.id != self.name:
		return

	should_pose_button.set_pressed_no_signal(payload.data)

#-----------------------------------------------------------------------------#
# Private functions                                                           #
#-----------------------------------------------------------------------------#

#-----------------------------------------------------------------------------#
# Public functions                                                            #
#-----------------------------------------------------------------------------#
