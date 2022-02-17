extends "res://tests/base_test.gd"

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
	var input_target_left_eye_blink: float = 1.0
	var input_target_right_eye_blink: float = 1.0 
	var input_target_mouth_open: float = 1.0
	var input_target_mouth_wide: float = 1.0

	interpolation_data.update_values(
		input_updated,
		input_target_translation,
		input_target_rotation,
		input_target_left_eye_rotation,
		input_target_right_eye_rotation,
		input_target_left_eye_blink,
		input_target_right_eye_blink,
		input_target_mouth_open,
		input_target_mouth_wide
	)

	# Check stored data
	assert_true(interpolation_data.last_updated == input_updated)
	assert_true(interpolation_data.translation_values.target_value == input_target_translation)
	assert_true(interpolation_data.rotation_values.target_value == input_target_translation)
	assert_true(interpolation_data.left_eye_rotation_values.target_value == input_target_left_eye_rotation)
	assert_true(interpolation_data.right_eye_rotation_values.target_value == input_target_right_eye_rotation)
	assert_true(interpolation_data.left_eye_blink_values.target_value == input_target_left_eye_blink)
	assert_true(interpolation_data.right_eye_blink_values.target_value == input_target_right_eye_blink)
	assert_true(interpolation_data.mouth_open_values.target_value == input_target_mouth_open)
	assert_true(interpolation_data.mouth_wide_values.target_value == input_target_mouth_wide)

func test_interpolate() -> void:
	var interpolation_data = INTERPOLATION_DATA.new()

	var interpolation_rate: float = 0.1

	var input_updated: float = 1.0
	var input_target_translation: Vector3 = Vector3(1, 1, 1)
	var input_target_rotation: Vector3 = Vector3(1, 1, 1)
	var input_target_left_eye_rotation: Vector3 = Vector3(1, 1, 1)
	var input_target_right_eye_rotation: Vector3 = Vector3(1, 1, 1)
	var input_target_left_eye_blink: float = 1.0
	var input_target_right_eye_blink: float = 1.0 
	var input_target_mouth_open: float = 1.0
	var input_target_mouth_wide: float = 1.0

	interpolation_data.update_values(
		input_updated,
		input_target_translation,
		input_target_rotation,
		input_target_left_eye_rotation,
		input_target_right_eye_rotation,
		input_target_left_eye_blink,
		input_target_right_eye_blink,
		input_target_mouth_open,
		input_target_mouth_wide
	)

	var i_translation: Vector3 = interpolation_data.interpolate(interpolation_data.InterpolationDataType.TRANSLATION, interpolation_rate)
	var i_rotation: Vector3 = interpolation_data.interpolate(interpolation_data.InterpolationDataType.ROTATION, interpolation_rate)
	var i_left_eye_rotation: Vector3 = interpolation_data.interpolate(interpolation_data.InterpolationDataType.LEFT_EYE_ROTATION, interpolation_rate)
	var i_right_eye_rotation: Vector3 = interpolation_data.interpolate(interpolation_data.InterpolationDataType.RIGHT_EYE_ROTATION, interpolation_rate)

	assert_true(i_translation == input_target_translation * interpolation_rate * interpolation_data.base_interpolation.interpolation_rate)
	assert_true(i_rotation == input_target_rotation * interpolation_rate * interpolation_data.base_interpolation.interpolation_rate)
	assert_true(i_left_eye_rotation == input_target_left_eye_rotation * interpolation_rate * interpolation_data.gaze_interpolation.interpolation_rate)
	assert_true(i_right_eye_rotation == input_target_right_eye_rotation * interpolation_rate * interpolation_data.gaze_interpolation.interpolation_rate)
