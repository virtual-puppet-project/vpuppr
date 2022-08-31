class_name InterpolationData
extends Reference

const INTERPOLATE_FLAGS := [
	"interpolate_global",

	"interpolate_bones",
	"interpolate_gaze",
	"interpolate_blinks",
	"interpolate_mouth",
	"interpolate_eyebrows"
]

const INTERPOLATE_RATES := [
	"base_interpolation_rate",

	"bone_interpolation_rate",
	"gaze_interpolation_rate",
	"blinks_interpolation_rate",
	"mouth_interpolation_rate",
	"eyebrow_interpolation_rate"
]

const DAMPS := [
	"bone_translation_damping",
	"bone_rotation_damping",

	"left_gaze_damping",
	"right_gaze_damping",

	"left_blink_damping",
	"right_blink_damping",

	"mouth_open_damping",
	"mouth_wide_damping",

	"eyebrow_steepness_left_damping",
	"eyebrow_up_down_left_damping",
	"eyebrow_quirk_left_damping",
	"eyebrow_steepness_right_damping",
	"eyebrow_up_down_right_damping",
	"eyebrow_quirk_right_damping"
]

class InterpolationBundle:
	## Wrapper class for applying rates to a group of InterpolationHelper classes

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
var global := InterpolationHelper.new()

var bone_translation := InterpolationHelper.new()
var bone_rotation := InterpolationHelper.new()
var bone_helper := InterpolationBundle.new([bone_translation, bone_rotation])

var left_gaze := InterpolationHelper.new()
var right_gaze := InterpolationHelper.new()
var gaze_helper := InterpolationBundle.new([left_gaze, right_gaze])

var left_blink := InterpolationHelper.new()
var right_blink := InterpolationHelper.new()
var blink_helper := InterpolationBundle.new([left_blink, right_blink])

var mouth_open := InterpolationHelper.new()
var mouth_wide := InterpolationHelper.new()
var mouth_helper := InterpolationBundle.new([mouth_open, mouth_wide])

var eyebrow_steepness_left := InterpolationHelper.new()
var eyebrow_up_down_left := InterpolationHelper.new()
var eyebrow_quirk_left := InterpolationHelper.new()
var eyebrow_steepness_right := InterpolationHelper.new()
var eyebrow_up_down_right := InterpolationHelper.new()
var eyebrow_quirk_right := InterpolationHelper.new()
var eyebrow_helper := InterpolationBundle.new([
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
	for i in INTERPOLATE_RATES:
		AM.ps.subscribe(self, i, {"args": [i], "callback": "_on_model_config_changed"})
		_on_model_config_changed(AM.cm.model_config.get(i), i)
	
	for i in DAMPS:
		AM.ps.subscribe(self, i, {"args": [i], "callback": "_on_model_config_changed"})
		_on_model_config_changed(AM.cm.model_config.get(i), i)

	for i in INTERPOLATE_FLAGS:
		AM.ps.subscribe(self, i, {"args": [i], "callback": "_on_model_config_changed"})
		_on_model_config_changed(AM.cm.model_config.get(i), i)

	global.target_value = 0.0
	global.last_value = 0.0

	bone_translation.target_value = Vector3.ZERO
	bone_translation.last_value = Vector3.ZERO
	bone_rotation.target_value = Vector3.ZERO
	bone_rotation.last_value = Vector3.ZERO

	left_gaze.target_value = Vector3.ZERO
	left_gaze.last_value = Vector3.ZERO
	right_gaze.target_value = Vector3.ZERO
	right_gaze.last_value = Vector3.ZERO

	left_blink.target_value = 0.0
	left_blink.last_value = 0.0
	right_blink.target_value = 0.0
	right_blink.last_value = 0.0

	mouth_open.target_value = 0.0
	mouth_open.last_value = 0.0
	mouth_wide.target_value = 0.0
	mouth_wide.last_value = 0.0

	eyebrow_steepness_left.target_value = 0.0
	eyebrow_steepness_left.last_value = 0.0
	eyebrow_up_down_left.target_value = 0.0
	eyebrow_up_down_left.last_value = 0.0
	eyebrow_quirk_left.target_value = 0.0
	eyebrow_quirk_left.last_value = 0.0

	eyebrow_steepness_right.target_value = 0.0
	eyebrow_steepness_right.last_value = 0.0
	eyebrow_up_down_right.target_value = 0.0
	eyebrow_up_down_right.last_value = 0.0
	eyebrow_quirk_right.target_value = 0.0
	eyebrow_quirk_right.last_value = 0.0

#-----------------------------------------------------------------------------#
# Connections                                                                 #
#-----------------------------------------------------------------------------#

func _on_model_config_changed(data, key: String) -> void:
	var value = data.data if data is SignalPayload else data
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
		"base_interpolation_rate":
			global.set_both_rates(value)

			for i in non_global_interpolations:
				i.global_rate_changed(value)
		
		"interpolate_bones":
			bone_helper.set_should_interpolate(value)
			bone_helper.maybe_reset_rate(global.interpolation_rate)
		"bone_interpolation_rate":
			bone_helper.set_both_rates(value)
		"bone_translation_damping":
			bone_translation.damping = value
		"bone_rotation_damping":
			bone_rotation.damping = value
		
		"interpolate_gaze":
			gaze_helper.set_should_interpolate(value)
			gaze_helper.maybe_reset_rate(global.interpolation_rate)
		"gaze_interpolation_rate":
			gaze_helper.set_both_rates(value)
		"left_gaze_damping":
			left_gaze.damping = value
		"right_gaze_damping":
			right_gaze.damping = value

		"interpolate_blinks":
			blink_helper.set_should_interpolate(value)
			blink_helper.maybe_reset_rate(global.interpolation_rate)
		"blinks_interpolation_rate":
			blink_helper.set_both_rates(value)
		"left_blink_damping":
			left_blink.damping = value
		"right_blink_damping":
			right_blink.damping = value
		
		"interpolate_mouth":
			mouth_helper.set_should_interpolate(value)
			mouth_helper.maybe_reset_rate(global.interpolation_rate)
		"mouth_interpolation_rate":
			mouth_helper.set_both_rates(value)
		"mouth_open_damping":
			mouth_open.damping = value
		"mouth_wide_damping":
			mouth_wide.damping = value

		"interpolate_eyebrows":
			eyebrow_helper.set_should_interpolate(value)
			eyebrow_helper.maybe_reset_rate(global.interpolation_rate)
		"eyebrow_interpolation_rate":
			eyebrow_helper.set_both_rates(value)
		"eyebrow_steepness_left_damping":
			eyebrow_steepness_left.damping = value
		"eyebrow_up_down_left_damping":
			eyebrow_up_down_left.damping = value
		"eyebrow_quirk_left_damping":
			eyebrow_quirk_left.damping = value
		"eyebrow_steepness_right_damping":
			eyebrow_steepness_right.damping = value
		"eyebrow_up_down_right_damping":
			eyebrow_up_down_right.damping = value
		"eyebrow_quirk_right_damping":
			eyebrow_quirk_right.damping = value

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
