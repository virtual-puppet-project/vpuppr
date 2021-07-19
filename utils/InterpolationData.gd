class_name InterpolationData
extends Reference

enum InterpolationDataType { NONE = 0, TRANSLATION, ROTATION, LEFT_EYE_ROTATION, RIGHT_EYE_ROTATION }

var last_updated: float

var rate: float

var last_translation: Vector3
var last_rotation: Vector3
var last_left_eye_rotation: Vector3
var last_right_eye_rotation: Vector3

var target_translation: Vector3
var target_rotation: Vector3
var target_left_eye_rotation: Vector3
var target_right_eye_rotation: Vector3

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
		p_target_right_eye_rotation: Vector3
	)-> void:
	last_updated = p_last_updated
	target_translation = p_target_translation
	target_rotation = p_target_rotation
	target_left_eye_rotation = p_target_left_eye_rotation
	target_right_eye_rotation = p_target_right_eye_rotation

func interpolate(interpolation_data_type: int, damp_modifier: float) -> Vector3:
	var result: Vector3
	match interpolation_data_type:
		InterpolationDataType.TRANSLATION:
			result = lerp(last_translation, target_translation * damp_modifier, rate)
			last_translation = result
		InterpolationDataType.ROTATION:
			result = lerp(last_rotation, target_rotation * damp_modifier, rate)
			last_rotation = result
		InterpolationDataType.LEFT_EYE_ROTATION:
			result = lerp(last_left_eye_rotation, target_left_eye_rotation * damp_modifier, rate)
			last_left_eye_rotation = result
		InterpolationDataType.RIGHT_EYE_ROTATION:
			result = lerp(last_right_eye_rotation, target_right_eye_rotation * damp_modifier, rate)
			last_right_eye_rotation = result

	return result
