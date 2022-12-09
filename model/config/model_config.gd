class_name ModelConfig
extends BaseConfig

#region Metadata

var config_name := ""
var description := ""
var hotkey := ""
var notes := ""
# Models can have 1-many configs
# The setter automatically flags the value as dirty when changed
var is_default_for_model := false setget _set_is_default_for_model
# Whether or not the default config in Metadata needs to be changed
var is_default_dirty := false

var model_name := ""
var model_path := ""

#endregion

#region Model

var model_transform := Transform()
var model_parent_transform := Transform()

#endregion

#region Bones

# Additional bones to be tracked
var additional_bones := {} # Bone name: String -> Bone id: int
# Bone pose positions
var bone_transforms := {} # Bone name: String -> Bone transform: Transform
var bones_to_interpolate := {} # Bone name: String -> Bones id: int
var bone_interpolation_rates := {} # Bone id: int -> Interpolation rate: float

#endregion

#region Tracking

## Not applied to any interpolation data but instead directly on the model
var additional_bone_damping: float = 0.3

var bone_translation_damping: float = 0.3
var bone_rotation_damping: float = 0.02

var left_gaze_damping: float = 1.0
var right_gaze_damping: float = 1.0

var left_blink_damping: float = 1.0
var right_blink_damping: float = 1.0

var mouth_open_damping: float = 1.0
var mouth_wide_damping: float = 1.0

var eyebrow_steepness_left_damping: float = 1.0
var eyebrow_up_down_left_damping: float = 1.0
var eyebrow_quirk_left_damping: float = 1.0

var eyebrow_steepness_right_damping: float = 1.0
var eyebrow_up_down_right_damping: float = 1.0
var eyebrow_quirk_right_damping: float = 1.0

# This is always overridden when loading a VRM file
var head_bone := "head"

var apply_translation := false
var apply_rotation := true

#region Interpolation

var interpolate_global := true
var base_interpolation_rate := 0.1

# Overrideable interpolation values that ignore interpolate_global
var interpolate_bones := false
var bone_interpolation_rate := 0.1
var interpolate_gaze := false
var gaze_interpolation_rate := 0.1
var interpolate_blinks := false
var blinks_interpolation_rate := 0.1
var interpolate_mouth := true # NOTE It's better to use rawer data for mouth
var mouth_interpolation_rate := 0.8
var interpolate_eyebrows := false
var eyebrow_interpolation_rate := 0.1

#endregion

var should_track_eye := true
var gaze_strength := 0.5
var blink_threshold := 0.2
var link_eye_blinks := false
var use_raw_eye_rotation := false
var use_blend_shapes_for_blinking := false

#region Mouth tracking values

# var mouth_open_max: float = 2.0
# var mouth_open_group_1: float = 0.25
# var mouth_open_group_2: float = 0.3
# var mouth_wide_max: float = 2.0
# var mouth_wide_group_1: float = 0.25
# var mouth_wide_group_2: float = 0.3

#endregion

#endregion

#region Blend shapes

## Blend shape names to blend shape values
##
## @type: Dictionary<String, float>
var blend_shapes := {}

## Blend shape name to an array of Action structs
##
## @type: Dictionary<String, Array<Action>>
var blend_shape_actions := {}

#endregion

#region Features

var main_light := {}

var main_world_environment := {}

var instanced_props := {} # Prop name: String -> PropData

#endregion

func _set_is_default_for_model(value: bool) -> void:
	if is_default_for_model != value:
		is_default_for_model = value
		is_default_dirty = true
