extends "res://tests/base_test.gd"

# https://github.com/bitwes/Gut/wiki/Quick-Start

#-----------------------------------------------------------------------------#
# Builtin functions                                                           #
#-----------------------------------------------------------------------------#

func before_all():
	.before_all()

func before_each():
	pass

func after_each():
	pass

func after_all():
	pass

#-----------------------------------------------------------------------------#
# Utils                                                                       #
#-----------------------------------------------------------------------------#

#-----------------------------------------------------------------------------#
# Tests                                                                       #
#-----------------------------------------------------------------------------#

func test_interpolate_vector3():
	var id := InterpolationData.new()
	
	id.left_gaze.last_value = Vector3.ZERO
	id.left_gaze.target_value = Vector3.ZERO
	
	if not assert_eq(id.left_gaze.last_value, id.left_gaze.target_value):
		return
	
	id.left_gaze.target_value = Vector3.ONE
	
	var interpolated_value: Vector3 = id.left_gaze.interpolate(0.5)
	
	assert_eq(id.left_gaze.target_value, Vector3.ONE)
	assert_eq(interpolated_value, Vector3.ONE * 0.5)
	assert_eq(id.left_gaze.last_value, interpolated_value)

func test_interpolate_float():
	var id := InterpolationData.new()
	
	id.right_blink.last_value = 0.0
	id.right_blink.target_value = 0.0
	
	if not assert_eq(id.right_blink.last_value, id.right_blink.target_value):
		return
	
	id.right_blink.target_value = 1.0
	
	var interpolated_value: float = id.right_blink.interpolate(0.5)
	
	assert_eq(id.right_blink.target_value, 1.0)
	assert_eq(interpolated_value, 1.0 * 0.5)
	assert_eq(id.right_blink.last_value, interpolated_value)

func test_update_config_pass():
	var id := InterpolationData.new()
	
	AM.ps.publish("base_interpolation_rate", 0.1)
	AM.ps.publish("bone_interpolation_rate", 1.0)

	assert_eq(id.global.should_interpolate, true)
	assert_eq(stepify(id.global.interpolation_rate, 0.00001), 0.1)

	assert_eq(id.bone_translation.should_interpolate, false)
	# The bone translation is overriden by the global rate, so only the last interpolation rate will change
	assert_eq(stepify(id.bone_translation.interpolation_rate, 0.01), 0.1)
	assert_eq(id.bone_translation.last_interpolation_rate, 1.0)

	id._on_model_config_changed(false, "interpolate_global")

	assert_eq(id.bone_translation.interpolation_rate, 1.0)
	assert_eq(id.bone_translation.last_interpolation_rate, 1.0)

	id._on_model_config_changed(true, "interpolate_global")

	assert_eq(stepify(id.bone_translation.interpolation_rate, 0.1), 0.1)
	assert_eq(id.bone_translation.last_interpolation_rate, 1.0)

	id._on_model_config_changed(true, "interpolate_bones")

	assert_eq(id.bone_translation.interpolation_rate, 1.0)
	assert_eq(id.bone_translation.last_interpolation_rate, 1.0)
	
	AM.ps.publish("bone_interpolation_rate", 0.5)
	
	assert_eq(id.bone_translation.interpolation_rate, 0.5)
