extends Reference

# Model gui

signal move_model(value)
func broadcast_move_model(value: bool) -> void:
	emit_signal("move_model", value)

signal rotate_model(value)
func broadcast_rotate_model(value: bool) -> void:
	emit_signal("rotate_model", value)

signal zoom_model(value)
func broadcast_zoom_model(value: bool) -> void:
	emit_signal("zoom_model", value)

signal load_model()
func broadcast_load_model() -> void:
	emit_signal("load_model")

signal set_model_as_default()
func broadcast_set_model_as_default() -> void:
	emit_signal("set_model_as_default")

signal reset_model_transform()
func broadcast_reset_model_transform() -> void:
	emit_signal("reset_model_transform")

signal reset_model_pose()
func broadcast_reset_model_pose() -> void:
	emit_signal("reset_model_pose")

signal bone_toggled()
func broadcast_bone_toggled(value: Array) -> void:
	"""
	value param contains bone name, toggle type, and toggle value
	"""
	emit_signal("bone_toggled", value[0], value[1], value[2])

# Tracking

signal translation_damp(value)
func broadcast_translation_damp(value: float) -> void:
	emit_signal("translation_damp", value)

signal rotation_damp(value)
func broadcast_rotation_damp(value: float) -> void:
	emit_signal("rotation_damp", value)

signal additional_bone_damp(value)
func broadcast_additional_bone_damp(value: float) -> void:
	emit_signal("additional_bone_damp", value)

signal head_bone(value)
func broadcast_head_bone(value: String) -> void:
	emit_signal("head_bone", value)

signal apply_translation(value)
func broadcast_apply_translation(value: bool) -> void:
	emit_signal("apply_translation", value)

signal apply_rotation(value)
func broadcast_apply_rotation(value: bool) -> void:
	emit_signal("apply_rotation", value)

signal interpolate_model(value)
func broadcast_interpolate_model(value: bool) -> void:
	emit_signal("interpolate_model", value)

signal interpolation_rate(value)
func broadcast_interpolation_rate(value: float) -> void:
	emit_signal("interpolation_rate", value)

signal should_track_eye(value)
func broadcast_should_track_eye(value: bool) -> void:
	emit_signal("should_track_eye", value)

signal gaze_strength(value)
func broadcast_gaze_strength(value: bool) -> void:
	emit_signal("gaze_strength", value)

# Features gui

signal add_custom_prop()
func broadcast_add_custom_prop() -> void:
	emit_signal("add_custom_prop")

signal custom_prop_toggle_created(value)
func broadcast_custom_prop_toggle_created(value: BaseElement) -> void:
	emit_signal("custom_prop_toggle_created", value)

# Props

signal prop_toggled(prop_name, value)
func broadcast_prop_toggled(value: Array) -> void:
	emit_signal("prop_toggled", value[0], value[1])

signal move_prop(prop_name)
func broadcast_move_prop(value: bool) -> void:
	emit_signal("move_prop", value)

signal rotate_prop(prop_name)
func broadcast_rotate_prop(value: bool) -> void:
	emit_signal("rotate_prop", value)

signal zoom_prop(prop_name)
func broadcast_zoom_prop(value: bool) -> void:
	emit_signal("zoom_prop", value)

signal main_light(prop_name, value)
func broadcast_main_light(value: Array) -> void:
	emit_signal("main_light", value[0], value[1])

signal world_environment(prop_name, value)
func broadcast_world_environment(value: Array) -> void:
	emit_signal("world_environment", value[0], value[1])

signal delete_prop()
func broadcast_delete_prop() -> void:
	emit_signal("delete_prop")

# Presets

signal new_preset(preset_name)
func broadcast_new_preset(value: String) -> void:
	emit_signal("new_preset", value)

signal preset_toggle_created(value)
func broadcast_preset_toggle_created(value: BaseElement) -> void:
	emit_signal("preset_toggle_created", value)

signal preset_toggled(preset_name, value)
func broadcast_preset_toggled(value: Array) -> void:
	emit_signal("preset_toggled", value[0], value[1])

signal config_name(value)
func broadcast_config_name(value: String) -> void:
	emit_signal("config_name", value)

# TODO might be worth it to prepend all config signals with 'config'
signal description(value)
func broadcast_description(value: String) -> void:
	emit_signal("description", value)

signal hotkey(value)
func broadcast_hotkey(value: String) -> void:
	emit_signal("hotkey", value)

signal notes(value)
func broadcast_notes(value: String) -> void:
	emit_signal("notes", value)

signal is_default_for_model(value)
func broadcast_is_default_for_model(value: bool) -> void:
	emit_signal("is_default_for_model", value)

signal load_preset()
func broadcast_load_preset() -> void:
	emit_signal("load_preset")

signal delete_preset()
func broadcast_delete_preset() -> void:
	emit_signal("delete_preset")

# File select popup

signal file_to_load_changed(file_path)
func set_file_to_load(file_path: String) -> void:
	AppManager.current_model_name = file_path.get_file()
	# Grab the full model path to allow setting model as default
	AppManager.current_model_path = file_path

	AppManager.cm.load_config_and_set_as_current(file_path)

	emit_signal("file_to_load_changed", file_path)

# Model

signal model_loaded(model) # Used by model scripts to indicate when they are ready
func model_is_loaded(model: BasicModel) -> void:
	emit_signal("model_loaded", model)

# Legacy gui

signal properties_applied()
func apply_properties() -> void:
	emit_signal("properties_applied")

signal properties_reset()
func reset_properties() -> void:
	emit_signal("properties_reset")

signal gui_toggle_set(toggle_name, view_name)
# TODO pose/feature/preset view all use this
# If a prop and a preset both share the same name, then they will both be toggled on
func gui_toggle_set(toggle_name: String, view_name: String) -> void:
	emit_signal("gui_toggle_set", toggle_name, view_name)

signal face_tracker_offsets_set()
func save_facetracker_offsets() -> void:
	emit_signal("face_tracker_offsets_set")

signal preset_changed(preset) # TODO might not need this
func change_preset(preset: String) -> void:
	emit_signal(preset)

signal default_model_set()
func set_model_as_default() -> void:
	AppManager.cm.metadata_config.default_model_to_load_path = AppManager.current_model_path
	AppManager.cm.save_config()
	emit_signal("default_model_set")
