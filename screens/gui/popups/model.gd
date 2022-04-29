extends BasePopupTreeLayout

###############################################################################
# Builtin functions                                                           #
###############################################################################

func _ready() -> void:
	pass

func _setup() -> void:
	_initial_page = "General"
	._setup()
	
	yield(self, "ready")

	#region General
	
	_connect_element($General/VBoxContainer/LoadModel, "load_model")
	_connect_element($General/VBoxContainer/SetModelDefault, "set_model_default")

	_connect_element($General/VBoxContainer/MoveModel, GlobalConstants.SceneSignals.MOVE_MODEL)
	_connect_element($General/VBoxContainer/RotateModel, GlobalConstants.SceneSignals.ROTATE_MODEL)
	_connect_element($General/VBoxContainer/ZoomModel, GlobalConstants.SceneSignals.ZOOM_MODEL)

	_connect_element($General/VBoxContainer/ResetModelTransform, "reset_model_transform")
	_connect_element($General/VBoxContainer/ResetModelPose, "reset_model_pose")

	_connect_element($General/VBoxContainer/HeadBone/LineEdit, "head_bone")

	_connect_element($General/VBoxContainer/ApplyTranslation, "apply_translation")
	_connect_element($General/VBoxContainer/ApplyRotation, "apply_rotation")

	#endregion

	#region Looseness

	_connect_element($Looseness/VBoxContainer/Translation/LineEdit, "translation_damp")
	_connect_element($Looseness/VBoxContainer/Rotation/LineEdit, "rotation_damp")
	_connect_element($Looseness/VBoxContainer/AdditionalBones/LineEdit , "additional_bone_damp")

	#endregion

	#region Interpolation

	_connect_element($InterpolationOptions/VBoxContainer/Global/CheckButton, "interpolate_global")
	_connect_element($InterpolationOptions/VBoxContainer/Global/HBoxContainer/LineEdit, "base_interpolation_rate")

	_connect_element($InterpolationOptions/VBoxContainer/Bones/CheckButton, "interpolate_bones")
	_connect_element($InterpolationOptions/VBoxContainer/Bones/HBoxContainer/LineEdit, "bone_interpolation_rate")

	_connect_element($InterpolationOptions/VBoxContainer/Gaze/CheckButton, "interpolate_gaze")
	_connect_element($InterpolationOptions/VBoxContainer/Gaze/HBoxContainer/LineEdit, "gaze_interpolation_rate")

	_connect_element($InterpolationOptions/VBoxContainer/Blink/CheckButton, "interpolate_blinks")
	_connect_element($InterpolationOptions/VBoxContainer/Blink/HBoxContainer/LineEdit, "blinks_interpolation_rate")

	_connect_element($InterpolationOptions/VBoxContainer/Mouth/CheckButton, "interpolate_mouth")
	_connect_element($InterpolationOptions/VBoxContainer/Mouth/HBoxContainer/LineEdit, "mouth_interpolation_rate")

	_connect_element($InterpolationOptions/VBoxContainer/Eyebrows/CheckButton, "interpolate_eyebrows")
	_connect_element($InterpolationOptions/VBoxContainer/Eyebrows/HBoxContainer/LineEdit, "eyebrow_interpolation_rate")

	#endregion

	#region Eye Options

	_connect_element($EyeOptions/VBoxContainer/ShouldTrackEye, "should_track_eye")
	_connect_element($EyeOptions/VBoxContainer/GazeStrength/LineEdit, "gaze_strength")
	_connect_element($EyeOptions/VBoxContainer/LinkEyeBlinks, "link_eye_blinks")
	_connect_element($EyeOptions/VBoxContainer/RawEyeRotation, "use_raw_eye_rotation")

	#endregion

###############################################################################
# Connections                                                                 #
###############################################################################

#region Button callbacks

func _on_button_pressed(signal_name: String, _button: Button) -> void:
	match signal_name:
		"load_model":
			var fd := FileDialog.new()
			fd.access = FileDialog.ACCESS_FILESYSTEM
			fd.mode = FileDialog.MODE_OPEN_FILE

			fd.current_path = AM.cm.get_data("default_search_path")
			fd.current_dir = AM.cm.get_data("default_search_path")
			fd.add_filter("*")
			
			fd.connect("file_selected", self, "_on_model_selected")
			
			add_child(fd)
			fd.popup_centered_ratio()
		"set_model_default":
			AM.ps.emit_signal("default_model_path", get_tree().current_scene.current_model_path)
		"reset_model_transform":
			var scene = get_tree().current_scene
			scene.model.transform = scene.model_intitial_transform
			scene.model_parent.transform = scene.model_parent_initial_transform
		"reset_model_pose":
			get_tree().current_scene.model.reset_all_bone_poses()

func _on_model_selected(path: String) -> void:
	get_tree().current_scene.load_model(path)

#endregion

func _on_check_button_toggled(state: bool, signal_name: String, _check_button: CheckButton) -> void:
	AM.ps.emit_signal(signal_name, state)

# TODO 04/26/2022 these values do not match up 1-1 with the config
func _on_line_edit_text_changed(text: String, signal_name: String, _line_edit: LineEdit) -> void:
	if text.empty():
		return
	
	match signal_name:
		"head_bone":
			AM.ps.emit_signal(signal_name, text)
		_:
			_set_config_float_amount(signal_name, text)

###############################################################################
# Private functions                                                           #
###############################################################################

###############################################################################
# Public functions                                                            #
###############################################################################
