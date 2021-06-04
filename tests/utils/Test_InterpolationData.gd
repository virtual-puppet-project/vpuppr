extends BaseTest

const INTERPOLATION_DATA: Resource = preload("res://utils/InterpolationData.gd")

###############################################################################
# Builtin functions                                                           #
###############################################################################

###############################################################################
# Utils                                                                       #
###############################################################################

###############################################################################
# Tests                                                                       #
###############################################################################

func test_update_values() -> void:
	var interpolation_data = INTERPOLATION_DATA.new()

	var input_updated: float = 1.0
	var input_target_translation: Vector3 = Vector3(1, 1, 1)
	var input_target_rotation: Vector3 = Vector3(1, 1, 1)
	var input_target_left_eye_rotation: Vector3 = Vector3(1, 1, 1)
	var input_target_right_eye_rotation: Vector3 = Vector3(1, 1, 1)

	interpolation_data.update_values(
		input_updated,
		input_target_translation,
		input_target_rotation,
		input_target_left_eye_rotation,
		input_target_right_eye_rotation
	)

	# Check stored data
	assert(interpolation_data.last_updated == input_updated)
	assert(interpolation_data.target_translation == input_target_translation)
	assert(interpolation_data.target_rotation == input_target_translation)
	assert(interpolation_data.target_left_eye_rotation == input_target_left_eye_rotation)
	assert(interpolation_data.target_right_eye_rotation == input_target_right_eye_rotation)

func test_interpolate() -> void:
	var interpolation_data = INTERPOLATION_DATA.new()

	var interpolation_rate: float = 0.1

	var input_updated: float = 1.0
	var input_target_translation: Vector3 = Vector3(1, 1, 1)
	var input_target_rotation: Vector3 = Vector3(1, 1, 1)
	var input_target_left_eye_rotation: Vector3 = Vector3(1, 1, 1)
	var input_target_right_eye_rotation: Vector3 = Vector3(1, 1, 1)

	interpolation_data.update_values(
		input_updated,
		input_target_translation,
		input_target_rotation,
		input_target_left_eye_rotation,
		input_target_right_eye_rotation
	)

	var i_translation: Vector3 = interpolation_data.interpolate(interpolation_data.InterpolationDataType.TRANSLATION, interpolation_rate)
	var i_rotation: Vector3 = interpolation_data.interpolate(interpolation_data.InterpolationDataType.ROTATION, interpolation_rate)
	var i_left_eye_rotation: Vector3 = interpolation_data.interpolate(interpolation_data.InterpolationDataType.LEFT_EYE_ROTATION, interpolation_rate)
	var i_right_eye_rotation: Vector3 = interpolation_data.interpolate(interpolation_data.InterpolationDataType.RIGHT_EYE_ROTATION, interpolation_rate)

	assert(i_translation == input_target_translation * interpolation_rate * interpolation_data.rate)
	assert(i_rotation == input_target_rotation * interpolation_rate * interpolation_data.rate)
	assert(i_left_eye_rotation == input_target_left_eye_rotation * interpolation_rate * interpolation_data.rate)
	assert(i_right_eye_rotation == input_target_right_eye_rotation * interpolation_rate * interpolation_data.rate)
