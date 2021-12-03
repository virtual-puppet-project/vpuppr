class_name InterpolationData
extends Reference

enum InterpolationDataType {
	NONE = 0,
	TRANSLATION,
	ROTATION,
	LEFT_EYE_ROTATION,
	RIGHT_EYE_ROTATION,
	LEFT_EYE_BLINK,
	RIGHT_EYE_BLINK,
	MOUTH_MOVEMENT
}

var last_updated: float

# Interpolation config values
var should_interpolate: bool
var base_interpolation_rate: float
var last_base_interpolation_rate: float

var should_interpolate_bones: bool
var bone_interpolation_rate: float
var last_bone_interpolation_rate: float

var should_interpolate_gaze: bool
var gaze_interpolation_rate: float
var last_gaze_interpolation_rate: float

var should_interpolate_blinking: bool
var blinking_interpolation_rate: float
var last_blinking_interpolation_rate: float

var should_interpolate_mouth: bool
var mouth_interpolation_rate: float
var last_mouth_interpolation_rate: float

# Actual values
var last_translation: Vector3
var last_rotation: Vector3

var last_left_eye_rotation: Vector3
var last_right_eye_rotation: Vector3

var last_left_eye_blink: float
var last_right_eye_blink: float

var last_mouth_movement: float

var target_translation: Vector3
var target_rotation: Vector3

var target_left_eye_rotation: Vector3
var target_right_eye_rotation: Vector3

var target_left_eye_blink: float
var target_right_eye_blink: float

var target_mouth_movement: float

###############################################################################
# Builtin functions                                                           #
###############################################################################

func _init() -> void:
	for i in [
		"interpolate_model",
		"interpolate_bones",
		"interpolate_gaze",
		"interpolate_blinking",
		"interpolate_mouth",
	]:
		AppManager.sb.connect(i, self, "_on_toggle_interpolation", [i])
		_on_toggle_interpolation(AppManager.cm.current_model_config.get(i), i)

	for i in [
		"interpolation_rate",
		"bone_interpolation_rate",
		"gaze_interpolation_rate",
		"blinking_interpolation_rate",
		"mouth_interpolation_rate"
	]:
		AppManager.sb.connect(i, self, "_on_set_interpolation_rate", [i])
		_on_set_interpolation_rate(AppManager.cm.current_model_config.get(i), i)

	last_updated = 0.0

	last_translation = Vector3.ZERO
	last_rotation = Vector3.ZERO

	target_translation = Vector3.ZERO
	target_rotation = Vector3.ZERO

###############################################################################
# Connections                                                                 #
###############################################################################

func _on_toggle_interpolation(value: bool, i_name: String) -> void:
	match i_name:
		"interpolate_model":
			should_interpolate = value
			if value:
				base_interpolation_rate = last_base_interpolation_rate
				# Toggle off other options if they are already toggled off
				if not should_interpolate_bones:
					bone_interpolation_rate = base_interpolation_rate
				if not should_interpolate_gaze:
					gaze_interpolation_rate = base_interpolation_rate
				if not should_interpolate_blinking:
					blinking_interpolation_rate = base_interpolation_rate
				if not should_interpolate_mouth:
					mouth_interpolation_rate = base_interpolation_rate
			else:
				last_base_interpolation_rate = base_interpolation_rate
				base_interpolation_rate = 1.0
				# Toggle off other options if they are already toggled off
				if not should_interpolate_bones:
					bone_interpolation_rate = 1.0
				if not should_interpolate_gaze:
					gaze_interpolation_rate = 1.0
				if not should_interpolate_blinking:
					blinking_interpolation_rate = 1.0
				if not should_interpolate_mouth:
					mouth_interpolation_rate = 1.0
		"interpolate_bones":
			should_interpolate_bones = value
			if value:
				bone_interpolation_rate = last_bone_interpolation_rate
			else:
				last_bone_interpolation_rate = bone_interpolation_rate
				bone_interpolation_rate = 1.0
		"interpolate_gaze":
			should_interpolate_gaze = value
			if value:
				gaze_interpolation_rate = last_gaze_interpolation_rate
			else:
				last_gaze_interpolation_rate = gaze_interpolation_rate
				gaze_interpolation_rate = 1.0
		"interpolate_blinking":
			should_interpolate_blinking = value
			if value:
				blinking_interpolation_rate = last_blinking_interpolation_rate
			else:
				last_blinking_interpolation_rate = blinking_interpolation_rate
				blinking_interpolation_rate = 1.0
		"interpolate_mouth":
			should_interpolate_mouth = value
			if value:
				mouth_interpolation_rate = last_mouth_interpolation_rate
			else:
				last_mouth_interpolation_rate = mouth_interpolation_rate
				mouth_interpolation_rate = 1.0

func _on_set_interpolation_rate(value: float, i_name: String) -> void:
	match i_name:
		"interpolation_rate":
			base_interpolation_rate = value
			last_base_interpolation_rate = value
			if not should_interpolate_bones:
				bone_interpolation_rate = value
			if not should_interpolate_gaze:
				gaze_interpolation_rate = value
			if not should_interpolate_blinking:
				blinking_interpolation_rate = value
			if not should_interpolate_mouth:
				mouth_interpolation_rate = value
		"bone_interpolation_rate":
			bone_interpolation_rate = value
			last_bone_interpolation_rate = value
		"gaze_interpolation_rate":
			gaze_interpolation_rate = value
			last_gaze_interpolation_rate = value
		"blinking_interpolation_rate":
			blinking_interpolation_rate = value
			last_blinking_interpolation_rate = value
		"mouth_interpolation_rate":
			mouth_interpolation_rate = value
			last_mouth_interpolation_rate = value

###############################################################################
# Private functions                                                           #
###############################################################################

###############################################################################
# Public functions                                                            #
###############################################################################

func update_values(
		p_last_updated: float,
		p_target_translation: Vector3,
		p_target_rotation: Vector3,
		p_target_left_eye_rotation: Vector3,
		p_target_right_eye_rotation: Vector3,
		p_target_left_eye_blink: float,
		p_target_right_eye_blink: float,
		p_target_mouth_movement: float
	)-> void:
	last_updated = p_last_updated
	target_translation = p_target_translation
	target_rotation = p_target_rotation
	target_left_eye_rotation = p_target_left_eye_rotation
	target_right_eye_rotation = p_target_right_eye_rotation
	target_left_eye_blink = p_target_left_eye_blink
	target_right_eye_blink = p_target_right_eye_blink
	target_mouth_movement = p_target_mouth_movement

func interpolate(interpolation_data_type: int, damp_modifier: float) -> Vector3:
	var result
	match interpolation_data_type:
		InterpolationDataType.TRANSLATION:
			result = lerp(last_translation, target_translation * damp_modifier, base_interpolation_rate)
			last_translation = result
		InterpolationDataType.ROTATION:
			result = lerp(last_rotation, target_rotation * damp_modifier, base_interpolation_rate)
			last_rotation = result
		InterpolationDataType.LEFT_EYE_ROTATION:
			result = lerp(last_left_eye_rotation, target_left_eye_rotation * damp_modifier, gaze_interpolation_rate)
			last_left_eye_rotation = result
		InterpolationDataType.RIGHT_EYE_ROTATION:
			result = lerp(last_right_eye_rotation, target_right_eye_rotation * damp_modifier, gaze_interpolation_rate)
			last_right_eye_rotation = result
		InterpolationDataType.LEFT_EYE_BLINK:
			result = lerp(last_left_eye_blink, target_left_eye_blink * damp_modifier, blinking_interpolation_rate)
			last_left_eye_blink = result
		InterpolationDataType.RIGHT_EYE_BLINK:
			result = lerp(last_right_eye_blink, target_right_eye_blink * damp_modifier, blinking_interpolation_rate)
			last_right_eye_blink = result
		InterpolationDataType.MOUTH_MOVEMENT:
			result = lerp(last_mouth_movement, target_mouth_movement * damp_modifier, mouth_interpolation_rate)
			last_mouth_movement = result

	return result
