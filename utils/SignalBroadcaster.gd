extends Reference

# Gui signals

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
func broadcast_bone_toggled(bone_name: String, value: bool) -> void:
	emit_signal("bone_toggled", bone_name, value)

# File select popup

signal file_to_load_changed(file_path)
func set_file_to_load(file_path: String) -> void:
	AppManager.current_model_name = file_path.get_file()
	# Grab the full model path to allow setting model as default
	AppManager.current_model_path = file_path

	AppManager.cm.load_config(file_path)

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
