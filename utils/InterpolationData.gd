extends Reference

enum InterpolationDataType {
	NONE = 0,
	TRANSLATION,
	ROTATION,
	LEFT_EYE_ROTATION,
	RIGHT_EYE_ROTATION,
	LEFT_EYE_BLINK,
	RIGHT_EYE_BLINK,
	MOUTH_OPEN,
	MOUTH_WIDE
}

class ConfigValues:
	var should_interpolate: bool
	var interpolation_rate: float
	var last_interpolation_rate: float

	func set_both_rates(new_value: float) -> void:
		interpolation_rate = new_value
		last_interpolation_rate = new_value

	func base_rate_changed(new_value: float) -> void:
		"""
		Called when toggling base interpolation
		"""
		if not should_interpolate:
			interpolation_rate = new_value

	func maybe_reset_rate(base_rate: float) -> void:
		"""
		Called when setting specific interpolation values
		"""
		if should_interpolate:
			interpolation_rate = last_interpolation_rate
		else:
			last_interpolation_rate = interpolation_rate
			interpolation_rate = base_rate

var last_updated: float

# Interpolation config values

# TODO this name is a bit misleading, this is actually the body interpolation rate
# It gets reused for other facial features if there are no overrides
var base_interpolation := ConfigValues.new()

# TODO unused
var bone_interpolation := ConfigValues.new()
var gaze_interpolation := ConfigValues.new()
var blink_interpolation := ConfigValues.new()
var mouth_interpolation := ConfigValues.new()

class TargetValues:
	var last_value
	var target_value
	
	func _init(last_v, target_v) -> void:
		last_value = last_v
		target_value = target_v

var translation_values := TargetValues.new(Vector3.ZERO, Vector3.ZERO)
var rotation_values := TargetValues.new(Vector3.ZERO, Vector3.ZERO)

var left_eye_rotation_values := TargetValues.new(Vector3.ZERO, Vector3.ZERO)
var right_eye_rotation_values := TargetValues.new(Vector3.ZERO, Vector3.ZERO)

var left_eye_blink_values := TargetValues.new(0.0, 0.0)
var right_eye_blink_values := TargetValues.new(0.0, 0.0)

var mouth_open_values := TargetValues.new(0.0, 0.0)
var mouth_wide_values := TargetValues.new(0.0, 0.0)

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

###############################################################################
# Connections                                                                 #
###############################################################################

func _on_toggle_interpolation(value: bool, i_name: String) -> void:
	match i_name:
		"interpolate_model":
			base_interpolation.should_interpolate = value

			if value:
				base_interpolation.interpolation_rate = base_interpolation.last_interpolation_rate

				# Toggle off other options if they are already toggled off
				bone_interpolation.base_rate_changed(base_interpolation.interpolation_rate)
				gaze_interpolation.base_rate_changed(base_interpolation.interpolation_rate)
				blink_interpolation.base_rate_changed(base_interpolation.interpolation_rate)
				mouth_interpolation.base_rate_changed(base_interpolation.interpolation_rate)
			else:
				base_interpolation.last_interpolation_rate = base_interpolation.interpolation_rate
				base_interpolation.interpolation_rate = 1.0

				# Toggle off other options if they are already toggled off
				bone_interpolation.base_rate_changed(1.0)
				gaze_interpolation.base_rate_changed(1.0)
				blink_interpolation.base_rate_changed(1.0)
				mouth_interpolation.base_rate_changed(1.0)
		"interpolate_bones":
			bone_interpolation.should_interpolate = value
			bone_interpolation.maybe_reset_rate(base_interpolation.interpolation_rate)
		"interpolate_gaze":
			gaze_interpolation.should_interpolate = value
			gaze_interpolation.maybe_reset_rate(base_interpolation.interpolation_rate)
		"interpolate_blinking":
			blink_interpolation.should_interpolate = value
			blink_interpolation.maybe_reset_rate(base_interpolation.interpolation_rate)
		"interpolate_mouth":
			mouth_interpolation.should_interpolate = value
			mouth_interpolation.maybe_reset_rate(base_interpolation.interpolation_rate)

func _on_set_interpolation_rate(value: float, i_name: String) -> void:
	match i_name:
		"interpolation_rate":
			base_interpolation.set_both_rates(value)

			bone_interpolation.base_rate_changed(value)
			gaze_interpolation.base_rate_changed(value)
			blink_interpolation.base_rate_changed(value)
			mouth_interpolation.base_rate_changed(value)
		"bone_interpolation_rate":
			bone_interpolation.set_both_rates(value)
		"gaze_interpolation_rate":
			gaze_interpolation.set_both_rates(value)
		"blinking_interpolation_rate":
			blink_interpolation.set_both_rates(value)
		"mouth_interpolation_rate":
			mouth_interpolation.set_both_rates(value)

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
		p_target_mouth_open: float,
		p_target_mouth_wide: float
	)-> void:
	last_updated = p_last_updated
	translation_values.target_value = p_target_translation
	rotation_values.target_value = p_target_rotation
	left_eye_rotation_values.target_value = p_target_left_eye_rotation
	right_eye_rotation_values.target_value = p_target_right_eye_rotation
	left_eye_blink_values.target_value = p_target_left_eye_blink
	right_eye_blink_values.target_value = p_target_right_eye_blink
	mouth_open_values.target_value = p_target_mouth_open
	mouth_wide_values.target_value = p_target_mouth_wide

func interpolate(interpolation_data_type: int, damp_modifier: float):
	var result
	var values: TargetValues
	var rates: ConfigValues
	match interpolation_data_type:
		InterpolationDataType.TRANSLATION:
			values = translation_values
			rates = base_interpolation
		InterpolationDataType.ROTATION:
			values = rotation_values
			rates = base_interpolation
		InterpolationDataType.LEFT_EYE_ROTATION:
			values = left_eye_rotation_values
			rates = gaze_interpolation
		InterpolationDataType.RIGHT_EYE_ROTATION:
			values = right_eye_rotation_values
			rates = gaze_interpolation
		InterpolationDataType.LEFT_EYE_BLINK:
			values = left_eye_blink_values
			rates = blink_interpolation
		InterpolationDataType.RIGHT_EYE_BLINK:
			values = right_eye_blink_values
			rates = blink_interpolation
		InterpolationDataType.MOUTH_OPEN:
			values = mouth_open_values
			rates = mouth_interpolation
		InterpolationDataType.MOUTH_WIDE:
			values = mouth_wide_values
			rates = mouth_interpolation

	result = lerp(
		values.last_value,
		values.target_value * damp_modifier,
		rates.interpolation_rate)
	values.last_value = result

	return result
