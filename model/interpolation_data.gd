class_name InterpolationData
extends Reference

const LISTEN_VALUES := [
	"interpolate_global",
	"base_interpolation_rate",
	
	"interpolate_bones",
	"bone_interpolation_rate",
	"interpolate_gaze",
	"gaze_interpolation_rate",
	"interpolate_blinks",
	"blinks_interpolation_rate",
	"interpolate_mouth",
	"mouth_interpolation_rate",
	"interpolate_eyebrows",
	"eyebrow_interpolation_rate"
]

class Interpolation:
	var should_interpolate := false
	var interpolation_rate: float = 0.0
	var last_interpolation_rate: float = 0.0

	# Basically easing the target value lower so we don't snap to a stop when we are done interpolating
	var damping: float = 1.0

	var last_value
	var target_value

	func _init(p_last_value, p_target_value) -> void:
		last_value = p_last_value
		target_value = p_target_value

	func set_both_rates(new_value: float) -> void:
		if should_interpolate:
			interpolation_rate = new_value
		last_interpolation_rate = new_value

	func global_rate_changed(new_value: float) -> void:
		"""
		Called when toggling base interpolation
		"""
		if not should_interpolate:
			interpolation_rate = new_value

	func maybe_reset_rate(global_rate: float) -> void:
		"""
		Called when setting specific interpolation rates
		"""
		if should_interpolate:
			interpolation_rate = last_interpolation_rate
		else:
			last_interpolation_rate = interpolation_rate
			interpolation_rate = global_rate

	func interpolate(rate: float = interpolation_rate):
		"""
		Interpolate the value, update the stored floating target, and return the result
		"""
		last_value = lerp(last_value, target_value * damping, rate)

		return last_value

	func interpolate_no_update(rate: float = interpolation_rate):
		"""
		Interpolate the value and return the result. Does not update the stored floating target
		"""
		return lerp(last_value, target_value * damping, rate)

class InterpolationHelper:
	"""
	Wrapper class for applying rates to a group of Interpolation classes
	"""
	var interpolations: Array

	func _init(p_interpolations: Array) -> void:
		interpolations = p_interpolations

	func set_should_interpolate(value: bool) -> void:
		for i in interpolations:
			i.should_interpolate = value

	func global_rate_changed(rate: float) -> void:
		for i in interpolations:
			i.global_rate_changed(rate)

	func maybe_reset_rate(rate: float) -> void:
		for i in interpolations:
			i.maybe_reset_rate(rate)

	func set_both_rates(value) -> void:
		for i in interpolations:
			i.set_both_rates(value)

var last_updated: float = 0.0

# The fallback rate for non-overridden Interpolaters
var global := Interpolation.new(0.0, 0.0)

var bone_translation := Interpolation.new(Vector3.ZERO, Vector3.ZERO)
var bone_rotation := Interpolation.new(Vector3.ZERO, Vector3.ZERO)
var bone_helper := InterpolationHelper.new([bone_translation, bone_rotation])

var left_gaze := Interpolation.new(Vector3.ZERO, Vector3.ZERO)
var right_gaze := Interpolation.new(Vector3.ZERO, Vector3.ZERO)
var gaze_helper := InterpolationHelper.new([left_gaze, right_gaze])

var left_blink := Interpolation.new(0.0, 0.0)
var right_blink := Interpolation.new(0.0, 0.0)
var blink_helper := InterpolationHelper.new([left_blink, right_blink])

var mouth_open := Interpolation.new(0.0, 0.0)
var mouth_wide := Interpolation.new(0.0, 0.0)
var mouth_helper := InterpolationHelper.new([mouth_open, mouth_wide])

var eyebrow_steepness_left := Interpolation.new(0.0, 0.0)
var eyebrow_up_down_left := Interpolation.new(0.0, 0.0)
var eyebrow_quirk_left := Interpolation.new(0.0, 0.0)
var eyebrow_steepness_right := Interpolation.new(0.0, 0.0)
var eyebrow_up_down_right := Interpolation.new(0.0, 0.0)
var eyebrow_quirk_right := Interpolation.new(0.0, 0.0)
var eyebrow_helper := InterpolationHelper.new([
	eyebrow_steepness_left,
	eyebrow_up_down_left,
	eyebrow_quirk_left,

	eyebrow_steepness_right,
	eyebrow_up_down_right,
	eyebrow_quirk_right
])

# Helper for applying reset values when modifying the global rate
var non_global_interpolations := [
	bone_helper,
	gaze_helper,
	blink_helper,
	mouth_helper,
	eyebrow_helper
]

#-----------------------------------------------------------------------------#
# Builtin functions                                                           #
#-----------------------------------------------------------------------------#

func _init() -> void:
	for i in LISTEN_VALUES:
		AM.ps.register(self, i, PubSubRegisterPayload.new({"args": [i], "callback": "_on_model_config_changed"}))
		_on_model_config_changed(AM.cm.model_config.get(i), i)

#-----------------------------------------------------------------------------#
# Connections                                                                 #
#-----------------------------------------------------------------------------#

func _on_model_config_changed(value, key: String) -> void:
	match key:
		"interpolate_global":
			global.should_interpolate = value

			if value:
				global.interpolation_rate = global.last_interpolation_rate

				# Toggle off other options if they are already toggled off
				for i in non_global_interpolations:
					i.global_rate_changed(global.interpolation_rate)
			else:
				global.last_interpolation_rate = global.interpolation_rate
				global.interpolation_rate = 1.0

				# Toggle off other options if they are already toggled off
				for i in non_global_interpolations:
					i.global_rate_changed(1.0)
		"interpolate_rate":
			global.set_both_rates(value)

			for i in non_global_interpolations:
				i.global_rate_changed(value)
		"interpolate_bones":
			bone_helper.set_should_interpolate(value)
			bone_helper.maybe_reset_rate(global.interpolation_rate)
		"bone_interpolation_rate":
			bone_helper.set_both_rates(value)
		"interpolate_gaze":
			gaze_helper.set_should_interpolate(value)
			gaze_helper.maybe_reset_rate(global.interpolation_rate)
		"gaze_interpolation_rate":
			gaze_helper.set_both_rates(value)
		"interpolate_blinks":
			blink_helper.set_should_interpolate(value)
			blink_helper.maybe_reset_rate(global.interpolation_rate)
		"blinks_interpolation_rate":
			blink_helper.set_both_rates(value)
		"interpolate_mouth":
			mouth_helper.set_should_interpolate(value)
			mouth_helper.maybe_reset_rate(global.interpolation_rate)
		"mouth_interpolation_rate":
			mouth_helper.set_both_rates(value)
		"interpolate_eyebrows":
			eyebrow_helper.set_should_interpolate(value)
			eyebrow_helper.maybe_reset_rate(global.interpolation_rate)
		"eyebrow_interpolation_rate":
			eyebrow_helper.set_both_rates(value)

#-----------------------------------------------------------------------------#
# Private functions                                                           #
#-----------------------------------------------------------------------------#

#-----------------------------------------------------------------------------#
# Public functions                                                            #
#-----------------------------------------------------------------------------#

func update_values(
	p_last_updated: float,
	
	p_target_translation: Vector3,
	p_target_rotation: Vector3,
	
	p_target_left_eye_rotation: Vector3,
	p_target_right_eye_rotation: Vector3,

	p_target_left_eye_blink: float,
	p_target_right_eye_blink: float,

	p_target_mouth_open: float,
	p_target_mouth_wide: float,

	p_target_eyebrow_steepness_left: float,
	p_target_eyebrow_steepness_right: float,

	p_target_eyebrow_up_down_left: float,
	p_target_eyebrow_up_down_right: float,

	p_target_eyebrow_quirk_left: float,
	p_target_eyebrow_quirk_right: float
) -> void:
	last_updated = p_last_updated

	bone_translation.target_value = p_target_translation
	bone_rotation.target_value = p_target_rotation

	left_gaze.target_value = p_target_left_eye_rotation
	right_gaze.target_value = p_target_right_eye_rotation

	left_blink.target_value = p_target_left_eye_blink
	right_blink.target_value = p_target_right_eye_blink

	mouth_open.target_value = p_target_mouth_open
	mouth_wide.target_value = p_target_mouth_wide

	eyebrow_steepness_left.target_value = p_target_eyebrow_steepness_left
	eyebrow_steepness_right.target_value = p_target_eyebrow_steepness_right

	eyebrow_up_down_left.target_value = p_target_eyebrow_up_down_left
	eyebrow_up_down_right.target_value = p_target_eyebrow_up_down_right

	eyebrow_quirk_left.target_value = p_target_eyebrow_quirk_left
	eyebrow_quirk_right.target_value = p_target_eyebrow_quirk_right
