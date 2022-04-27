extends BasePopupTreeLayout

#region General

onready var load_model := $General/VBoxContainer/LoadModel as Button
onready var set_model_default := $General/VBoxContainer/SetModelDefault as Button

onready var move_model := $General/VBoxContainer/MoveModel as CheckButton
onready var rotate_model := $General/VBoxContainer/RotateModel as CheckButton
onready var scale_model := $General/VBoxContainer/ScaleModel as CheckButton

onready var reset_model_transform := $General/VBoxContainer/ResetModelTransform as Button
onready var reset_model_pose := $General/VBoxContainer/ResetModelPose as Button

onready var head_bone := $General/VBoxContainer/HeadBone/LineEdit as LineEdit

onready var apply_translation := $General/VBoxContainer/ApplyTranslation as CheckButton
onready var apply_rotation := $General/VBoxContainer/ApplyRotation as CheckButton

#endregion

#region Looseness

onready var translation_looseness := $Looseness/VBoxContainer/Translation/LineEdit as LineEdit
onready var rotation_looseness := $Looseness/VBoxContainer/Rotation/LineEdit as LineEdit
onready var additional_bones_looseness := $Looseness/VBoxContainer/AdditionalBones/LineEdit as LineEdit

#endregion

#region Interpolation Options

onready var global_interpolation_enabled := $InterpolationOptions/VBoxContainer/Global/CheckButton as CheckButton
onready var global_interpolation_amount := $InterpolationOptions/VBoxContainer/Global/HBoxContainer/LineEdit as LineEdit

onready var bone_interpolation_enabled := $InterpolationOptions/VBoxContainer/Bones/CheckButton as CheckButton
onready var bone_interpolation_amount := $InterpolationOptions/VBoxContainer/Bones/HBoxContainer/LineEdit as LineEdit

onready var gaze_interpolation_enabled := $InterpolationOptions/VBoxContainer/Gaze/CheckButton as CheckButton
onready var gaze_interpolation_amount := $InterpolationOptions/VBoxContainer/Gaze/HBoxContainer/LineEdit as LineEdit

onready var blink_interpolation_enabled := $InterpolationOptions/VBoxContainer/Blink/CheckButton as CheckButton
onready var blink_interpolation_amount := $InterpolationOptions/VBoxContainer/Blink/HBoxContainer/LineEdit as LineEdit

onready var mouth_interpolation_enabled := $InterpolationOptions/VBoxContainer/Mouth/CheckButton as CheckButton
onready var mouth_interpolation_amount := $InterpolationOptions/VBoxContainer/Mouth/HBoxContainer/LineEdit as LineEdit

onready var eyebrow_interpolation_enabled := $InterpolationOptions/VBoxContainer/Eyebrows/CheckButton as CheckButton
onready var eyebrow_interpolation_amount := $InterpolationOptions/VBoxContainer/Eyebrows/HBoxContainer/LineEdit as LineEdit

#endregion

#region Eye Options

onready var should_track_eye := $EyeOptions/VBoxContainer/ShouldTrackEye as CheckButton
onready var gaze_strength := $EyeOptions/VBoxContainer/GazeStrength/LineEdit as LineEdit
onready var link_eye_blinks := $EyeOptions/VBoxContainer/LinkEyeBlinks as CheckButton
onready var raw_eye_rotation := $EyeOptions/VBoxContainer/RawEyeRotation as CheckButton

#endregion

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
	
	_connect_button(load_model)
	_connect_button(set_model_default)

	_connect_check_button(move_model)
	_connect_check_button(rotate_model)
	_connect_check_button(scale_model)

	_connect_button(reset_model_transform)
	_connect_button(reset_model_pose)

	_connect_line_edit(head_bone, "head_bone")

	_connect_check_button(apply_translation)
	_connect_check_button(apply_rotation)

	#endregion

	#region Looseness

	_connect_line_edit(translation_looseness, "translation_damp")
	_connect_line_edit(rotation_looseness, "rotation_damp")
	_connect_line_edit(additional_bones_looseness, "additional_bone_damp")

	#endregion

	#region Interpolation

	_connect_check_button(global_interpolation_enabled, "interpolate_global")
	_connect_line_edit(global_interpolation_amount, "base_interpolation_rate")

	_connect_check_button(bone_interpolation_enabled, "interpolate_bones")
	_connect_line_edit(bone_interpolation_amount, "bone_interpolation_rate")

	_connect_check_button(gaze_interpolation_enabled, "interpolate_gaze")
	_connect_line_edit(gaze_interpolation_amount, "gaze_interpolation_rate")

	_connect_check_button(blink_interpolation_enabled, "interpolate_blinks")
	_connect_line_edit(blink_interpolation_amount, "blinks_interpolation_rate")

	_connect_check_button(mouth_interpolation_enabled, "interpolate_mouth")
	_connect_line_edit(mouth_interpolation_amount, "mouth_interpolation_rate")

	_connect_check_button(eyebrow_interpolation_enabled, "interpolate_eyebrows")
	_connect_line_edit(eyebrow_interpolation_amount, "eyebrow_interpolation_rate")

	#endregion

	#region Eye Options

	_connect_check_button(should_track_eye, "should_track_eye")
	_connect_line_edit(gaze_strength, "gaze_strength")
	_connect_check_button(link_eye_blinks, "link_eye_blinks")
	_connect_check_button(raw_eye_rotation, "use_raw_eye_rotation")

	#endregion

###############################################################################
# Connections                                                                 #
###############################################################################

#region Button callbacks

func _on_pressed(button: Button) -> void:
	match button:
		load_model:
			var fd := FileDialog.new()
			fd.access = FileDialog.ACCESS_FILESYSTEM
			fd.mode = FileDialog.MODE_OPEN_FILE

			fd.current_path = AM.cm.get_data("default_search_path")
			fd.current_dir = AM.cm.get_data("default_search_path")
			fd.add_filter("*")
			
			fd.connect("file_selected", self, "_on_model_selected")
			
			add_child(fd)
			fd.popup_centered_ratio()
		set_model_default:
			AM.ps.emit_signal("default_model_path", get_tree().current_scene.current_model_path)
		reset_model_transform:
			var scene = get_tree().current_scene
			scene.model.transform = scene.model_intitial_transform
			scene.model_parent.transform = scene.model_parent_initial_transform
		reset_model_pose:
			get_tree().current_scene.model.reset_all_bone_poses()

func _on_model_selected(path: String) -> void:
	get_tree().current_scene.load_model(path)

#endregion

func _on_toggled(state: bool, check_button: CheckButton) -> void:
	logger.info("%s toggled" % check_button.text)
	pass

# TODO 04/26/2022 these values do not match up 1-1 with the config
func _on_text_changed(text: String, line_edit: LineEdit) -> void:
	if text.empty():
		return
	match line_edit:
		head_bone:
			AM.ps.emit_signal("head_bone", text)
		translation_looseness:
			_set_config_float_amount("translation_damp", text)
		rotation_looseness:
			_set_config_float_amount("rotation_damp", text)
		additional_bones_looseness:
			_set_config_float_amount("additional_bone_damp", text)
		global_interpolation_amount:
			_set_config_float_amount("base_interpolation_rate", text)
		bone_interpolation_amount:
			_set_config_float_amount("bone_interpolation_rate", text)
		gaze_interpolation_amount:
			_set_config_float_amount("gaze_interpolation_rate", text)
		mouth_interpolation_amount:
			_set_config_float_amount("mouth_interpolation_rate", text)
		eyebrow_interpolation_amount:
			_set_config_float_amount("eyebrow_interpolation_rate", text)
		gaze_strength:
			_set_config_float_amount("gaze_strength", text)

func _on_text_entered(text: String, line_edit: LineEdit) -> void:
	_on_text_changed(text, line_edit)

func _on_config_updated(value, control: Control) -> void:
	if control is LineEdit:
		control.text = str(value)
	elif control is CheckButton:
		control.pressed = bool(value)

###############################################################################
# Private functions                                                           #
###############################################################################

func _connect_button(button: Button) -> void:
	button.connect("pressed", self, "_on_pressed", [button])

func _connect_check_button(check_button: CheckButton, signal_name: String = "") -> void:
	check_button.connect("toggled", self, "_on_toggled", [check_button])
	
	if not signal_name.empty():
		check_button.pressed = AM.cm.get_data(signal_name)
		AM.ps.register(self, signal_name, PubSubPayload.new({
			"args": [check_button],
			"callback": "_on_config_updated"
		}))

func _connect_line_edit(line_edit: LineEdit, signal_name: String) -> void:
	line_edit.connect("text_changed", self, "_on_text_changed", [line_edit])
	line_edit.connect("text_entered", self, "_on_text_entered")
	
	line_edit.text = str(AM.cm.get_data(signal_name))
	AM.ps.register(self, signal_name, PubSubPayload.new({
		"args": [line_edit],
		"callback": "_on_config_updated"
	}))

func _set_config_float_amount(signal_name: String, value: String) -> void:
	if not value.is_valid_float():
		return
	AM.ps.emit_signal(signal_name, value.to_float())

###############################################################################
# Public functions                                                            #
###############################################################################
