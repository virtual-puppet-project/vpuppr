extends BaseTreeLayout

var move_model: CheckButton
var rotate_model: CheckButton
var zoom_model: CheckButton

#-----------------------------------------------------------------------------#
# Builtin functions                                                           #
#-----------------------------------------------------------------------------#

func _setup() -> Result:
	_initial_page = tr("DEFAULT_GUI_MODEL_GENERAL_PAGE")

	#region General
	
	_connect_element($DEFAULT_GUI_MODEL_GENERAL_PAGE/VBoxContainer/LoadModel, "load_model")
	_connect_element($DEFAULT_GUI_MODEL_GENERAL_PAGE/VBoxContainer/SetModelDefault, "set_model_default")

	# TODO need a way to pull the global state of this element
	# e.g. other "Model" popups might already have "move" turned on
	move_model = $DEFAULT_GUI_MODEL_GENERAL_PAGE/VBoxContainer/MoveModel
	_connect_element(move_model, Globals.SceneSignals.MOVE_MODEL)
	rotate_model = $DEFAULT_GUI_MODEL_GENERAL_PAGE/VBoxContainer/RotateModel
	_connect_element(rotate_model, Globals.SceneSignals.ROTATE_MODEL)
	zoom_model = $DEFAULT_GUI_MODEL_GENERAL_PAGE/VBoxContainer/ZoomModel
	_connect_element(zoom_model, Globals.SceneSignals.ZOOM_MODEL)

	_connect_element($DEFAULT_GUI_MODEL_GENERAL_PAGE/VBoxContainer/ResetModelTransform, "reset_model_transform")
	_connect_element($DEFAULT_GUI_MODEL_GENERAL_PAGE/VBoxContainer/ResetModelPose, "reset_model_pose")

	_connect_element($DEFAULT_GUI_MODEL_GENERAL_PAGE/VBoxContainer/HeadBone/LineEdit, "head_bone")

	_connect_element($DEFAULT_GUI_MODEL_GENERAL_PAGE/VBoxContainer/ApplyTranslation, "apply_translation")
	_connect_element($DEFAULT_GUI_MODEL_GENERAL_PAGE/VBoxContainer/ApplyRotation, "apply_rotation")

	#endregion

	#region Looseness

	_connect_element($DEFAULT_GUI_MODEL_LOOSENESS_PAGE/VBoxContainer/AdditionalBones/LineEdit , "additional_bone_damping")

	_connect_element($DEFAULT_GUI_MODEL_LOOSENESS_PAGE/VBoxContainer/BoneTranslation/LineEdit, "bone_translation_damping")
	_connect_element($DEFAULT_GUI_MODEL_LOOSENESS_PAGE/VBoxContainer/BoneRotation/LineEdit, "bone_rotation_damping")

	_connect_element($DEFAULT_GUI_MODEL_LOOSENESS_PAGE/VBoxContainer/LeftGaze/LineEdit, "left_gaze_damping")
	_connect_element($DEFAULT_GUI_MODEL_LOOSENESS_PAGE/VBoxContainer/RightGaze/LineEdit, "right_gaze_damping")

	_connect_element($DEFAULT_GUI_MODEL_LOOSENESS_PAGE/VBoxContainer/LeftBlink/LineEdit, "left_blink_damping")
	_connect_element($DEFAULT_GUI_MODEL_LOOSENESS_PAGE/VBoxContainer/RightBlink/LineEdit, "right_blink_damping")

	_connect_element($DEFAULT_GUI_MODEL_LOOSENESS_PAGE/VBoxContainer/MouthOpen/LineEdit, "mouth_open_damping")
	_connect_element($DEFAULT_GUI_MODEL_LOOSENESS_PAGE/VBoxContainer/MouthWide/LineEdit, "mouth_wide_damping")

	_connect_element($DEFAULT_GUI_MODEL_LOOSENESS_PAGE/VBoxContainer/EyebrowSteepnessLeft/LineEdit, "eyebrow_steepness_left_damping")
	_connect_element($DEFAULT_GUI_MODEL_LOOSENESS_PAGE/VBoxContainer/EyebrowUpDownLeft/LineEdit, "eyebrow_up_down_left_damping")
	_connect_element($DEFAULT_GUI_MODEL_LOOSENESS_PAGE/VBoxContainer/EyebrowQuirkLeft/LineEdit, "eyebrow_quirk_left_damping")

	_connect_element($DEFAULT_GUI_MODEL_LOOSENESS_PAGE/VBoxContainer/EyebrowSteepnessRight/LineEdit, "eyebrow_steepness_right_damping")
	_connect_element($DEFAULT_GUI_MODEL_LOOSENESS_PAGE/VBoxContainer/EyebrowUpDownRight/LineEdit, "eyebrow_up_down_right_damping")
	_connect_element($DEFAULT_GUI_MODEL_LOOSENESS_PAGE/VBoxContainer/EyebrowQuirkRight/LineEdit, "eyebrow_quirk_right_damping")

	#endregion

	#region Interpolation

	_connect_element($DEFAULT_GUI_MODEL_INTERPOLATION_PAGE/VBoxContainer/Global/CheckButton, "interpolate_global")
	_connect_element($DEFAULT_GUI_MODEL_INTERPOLATION_PAGE/VBoxContainer/Global/HBoxContainer/LineEdit, "base_interpolation_rate")

	_connect_element($DEFAULT_GUI_MODEL_INTERPOLATION_PAGE/VBoxContainer/Bones/CheckButton, "interpolate_bones")
	_connect_element($DEFAULT_GUI_MODEL_INTERPOLATION_PAGE/VBoxContainer/Bones/HBoxContainer/LineEdit, "bone_interpolation_rate")

	_connect_element($DEFAULT_GUI_MODEL_INTERPOLATION_PAGE/VBoxContainer/Gaze/CheckButton, "interpolate_gaze")
	_connect_element($DEFAULT_GUI_MODEL_INTERPOLATION_PAGE/VBoxContainer/Gaze/HBoxContainer/LineEdit, "gaze_interpolation_rate")

	_connect_element($DEFAULT_GUI_MODEL_INTERPOLATION_PAGE/VBoxContainer/Blink/CheckButton, "interpolate_blinks")
	_connect_element($DEFAULT_GUI_MODEL_INTERPOLATION_PAGE/VBoxContainer/Blink/HBoxContainer/LineEdit, "blinks_interpolation_rate")

	_connect_element($DEFAULT_GUI_MODEL_INTERPOLATION_PAGE/VBoxContainer/Mouth/CheckButton, "interpolate_mouth")
	_connect_element($DEFAULT_GUI_MODEL_INTERPOLATION_PAGE/VBoxContainer/Mouth/HBoxContainer/LineEdit, "mouth_interpolation_rate")

	_connect_element($DEFAULT_GUI_MODEL_INTERPOLATION_PAGE/VBoxContainer/Eyebrows/CheckButton, "interpolate_eyebrows")
	_connect_element($DEFAULT_GUI_MODEL_INTERPOLATION_PAGE/VBoxContainer/Eyebrows/HBoxContainer/LineEdit, "eyebrow_interpolation_rate")

	#endregion

	#region Eye Options

	_connect_element($DEFAULT_GUI_MODEL_EYES_PAGE/VBoxContainer/ShouldTrackEye, "should_track_eye")
	_connect_element($DEFAULT_GUI_MODEL_EYES_PAGE/VBoxContainer/GazeStrength/LineEdit, "gaze_strength")
	_connect_element($DEFAULT_GUI_MODEL_EYES_PAGE/VBoxContainer/BlinkThreshold/LineEdit, "blink_threshold")
	_connect_element($DEFAULT_GUI_MODEL_EYES_PAGE/VBoxContainer/LinkEyeBlinks, "link_eye_blinks")
	_connect_element($DEFAULT_GUI_MODEL_EYES_PAGE/VBoxContainer/RawEyeRotation, "use_raw_eye_rotation")
	_connect_element($DEFAULT_GUI_MODEL_EYES_PAGE/VBoxContainer/BlendShapeBlinks, "use_blend_shapes_for_blinking")

	#endregion

	AM.ps.subscribe(self, Globals.EVENT_PUBLISHED)

	return ._setup()

#-----------------------------------------------------------------------------#
# Connections                                                                 #
#-----------------------------------------------------------------------------#

#region Button callbacks

func _on_button_pressed(signal_name: String, _button: Button) -> void:
	match signal_name:
		"load_model":
			var fd = FileUtil.get_file_picker()
			
			fd.connect("file_selected", self, "_on_model_selected")
			
			add_child(fd)
			fd.popup_centered_ratio()
		"set_model_default":
			AM.ps.publish("default_model_path", AM.cm.get_data("model_path"))
		"reset_model_transform":
			var scene = get_tree().current_scene
			
			var model_transform := Transform()
			var res := Safely.wrap(AM.tcm.pull("model_initial_transform"))
			if res.is_err():
				logger.error(res)
			else:
				model_transform = res.unwrap()
			
			var model_parent_transform := Transform()
			res = Safely.wrap(AM.tcm.pull("model_parent_initial_transform"))
			if res.is_err():
				logger.error(res)
			else:
				model_parent_transform = res.unwrap()
			
			scene.model.transform = model_transform
			scene.model_parent.transform = model_parent_transform
		"reset_model_pose":
			get_tree().current_scene.model.reset_all_bone_poses()
		_:
			_log_unhandled_signal(signal_name)

func _on_model_selected(path: String) -> void:
	AM.ps.publish(Globals.RELOAD_RUNNER, path)

#endregion

# TODO 04/26/2022 these values do not match up 1-1 with the config
func _on_line_edit_text_changed(text: String, signal_name: String, _line_edit: LineEdit) -> void:
	if text.empty():
		return
	
	match signal_name:
		"head_bone":
			AM.ps.publish(signal_name, text)
		_:
			_set_config_float_amount(signal_name, text)

func _on_event_published(payload: SignalPayload) -> void:
	match payload.signal_name:
		Globals.SceneSignals.MOVE_MODEL:
			move_model.set_pressed_no_signal(payload.data)
		Globals.SceneSignals.ROTATE_MODEL:
			rotate_model.set_pressed_no_signal(payload.data)
		Globals.SceneSignals.ZOOM_MODEL:
			zoom_model.set_pressed_no_signal(payload.data)

#-----------------------------------------------------------------------------#
# Private functions                                                           #
#-----------------------------------------------------------------------------#

func _delete(node: Node) -> void:
	node.queue_free()

#-----------------------------------------------------------------------------#
# Public functions                                                            #
#-----------------------------------------------------------------------------#
