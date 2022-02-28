extends "res://tests/base_test.gd"

# https://github.com/bitwes/Gut/wiki/Quick-Start

###############################################################################
# Builtin functions                                                           #
###############################################################################

func before_all():
	.before_all()

func before_each():
	pass

func after_each():
	pass

func after_all():
	pass

###############################################################################
# Tests                                                                       #
###############################################################################

func test_update_values_pass():
	var id := InterpolationData.new()

	assert_eq(id.last_updated, 0.0)
	assert_eq(id.bone_translation.target_value, Vector3.ZERO)

	var last_updated: float = 1.0
	
	var target_translation := Vector3.ONE
	var target_rotation := Vector3.ONE

	var target_left_eye_rotation := Vector3.ONE
	var target_right_eye_rotation := Vector3.ONE

	var target_left_eye_blink: float = 1.0
	var target_right_eye_blink: float = 1.0

	var target_mouth_open: float = 1.0
	var target_mouth_wide: float = 1.0

	var target_eyebrow_steepness_left: float = 1.0
	var target_eyebrow_steepness_right: float = 1.0

	var target_eyebrow_up_down_left: float = 1.0
	var target_eyebrow_up_down_right: float = 1.0

	var target_eyebrow_quirk_left: float = 1.0
	var target_eyebrow_quirk_right: float = 1.0

	id.update_values(
		last_updated,

		target_translation,
		target_rotation,

		target_left_eye_rotation,
		target_right_eye_rotation,

		target_left_eye_blink,
		target_right_eye_blink,

		target_mouth_open,
		target_mouth_wide,

		target_eyebrow_steepness_left,
		target_eyebrow_steepness_right,

		target_eyebrow_up_down_left,
		target_eyebrow_up_down_right,

		target_eyebrow_quirk_left,
		target_eyebrow_quirk_right
	)

	assert_eq(id.last_updated, 1.0)
	
	assert_eq(id.bone_translation.target_value, Vector3.ONE)
	assert_eq(id.bone_rotation.target_value, Vector3.ONE)
	
	assert_eq(id.left_gaze.target_value, Vector3.ONE)
	assert_eq(id.right_gaze.target_value, Vector3.ONE)
	
	assert_eq(id.left_blink.target_value, 1.0)
	assert_eq(id.right_blink.target_value, 1.0)
	
	assert_eq(id.mouth_open.target_value, 1.0)
	assert_eq(id.mouth_wide.target_value, 1.0)

	assert_eq(id.eyebrow_steepness_left.target_value, 1.0)
	assert_eq(id.eyebrow_up_down_left.target_value, 1.0)
	assert_eq(id.eyebrow_quirk_left.target_value, 1.0)

	assert_eq(id.eyebrow_steepness_right.target_value, 1.0)
	assert_eq(id.eyebrow_up_down_right.target_value, 1.0)
	assert_eq(id.eyebrow_quirk_right.target_value, 1.0)

func test_update_config_pass():
	var id := InterpolationData.new()

	id._on_model_config_data_changed("interpolate_rate", 0.1)
	id._on_model_config_data_changed("bone_interpolation_rate", 1.0)

	assert_eq(id.global.should_interpolate, true)
	assert_eq(id.global.interpolation_rate, 0.1)

	assert_eq(id.bone_translation.should_interpolate, false)
	# The bone translation is overriden by the global rate, so only the last interpolation rate will change
	assert_eq(id.bone_translation.interpolation_rate, 0.1)
	assert_eq(id.bone_translation.last_interpolation_rate, 1.0)

	id._on_model_config_data_changed("interpolate_global", false)

	assert_eq(id.bone_translation.interpolation_rate, 1.0)
	assert_eq(id.bone_translation.last_interpolation_rate, 1.0)

	id._on_model_config_data_changed("interpolate_global", true)

	assert_eq(id.bone_translation.interpolation_rate, 0.1)
	assert_eq(id.bone_translation.last_interpolation_rate, 1.0)

	id._on_model_config_data_changed("interpolate_bones", true)

	assert_eq(id.bone_translation.interpolation_rate, 1.0)
	assert_eq(id.bone_translation.last_interpolation_rate, 1.0)
