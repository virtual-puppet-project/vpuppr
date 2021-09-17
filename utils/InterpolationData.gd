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

var rate: float

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
	last_updated = 0.0

	rate = 0.1

	last_translation = Vector3.ZERO
	last_rotation = Vector3.ZERO

	target_translation = Vector3.ZERO
	target_rotation = Vector3.ZERO

###############################################################################
# Connections                                                                 #
###############################################################################

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
			result = lerp(last_translation, target_translation * damp_modifier, AppManager.cm.current_model_config.interpolation_rate)
			last_translation = result
		InterpolationDataType.ROTATION:
			result = lerp(last_rotation, target_rotation * damp_modifier, AppManager.cm.current_model_config.interpolation_rate)
			last_rotation = result
		InterpolationDataType.LEFT_EYE_ROTATION:
			result = lerp(last_left_eye_rotation, target_left_eye_rotation * damp_modifier, AppManager.cm.current_model_config.interpolation_rate)
			last_left_eye_rotation = result
		InterpolationDataType.RIGHT_EYE_ROTATION:
			result = lerp(last_right_eye_rotation, target_right_eye_rotation * damp_modifier, AppManager.cm.current_model_config.interpolation_rate)
			last_right_eye_rotation = result
		InterpolationDataType.LEFT_EYE_BLINK:
			result = lerp(last_left_eye_blink, target_left_eye_blink * damp_modifier, AppManager.cm.current_model_config.interpolation_rate)
			last_left_eye_blink = result
		InterpolationDataType.RIGHT_EYE_BLINK:
			result = lerp(last_right_eye_blink, target_right_eye_blink * damp_modifier, AppManager.cm.current_model_config.interpolation_rate)
			last_right_eye_blink = result
		InterpolationDataType.MOUTH_MOVEMENT:
			result = lerp(last_mouth_movement, target_mouth_movement * damp_modifier, AppManager.cm.current_model_config.interpolation_rate)
			last_mouth_movement = result

	return result
