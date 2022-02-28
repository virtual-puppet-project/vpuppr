class_name PubSub
extends Reference

var logger := Logger.new("PubSub")

class RegisterPayload:
	var args := []
	var custom_callback := ""

	func _init(v = null) -> void:
		"""
		There are 3 supported arguments for init
		1. Dictionary - {"args": [connect args], "custom_callback": "value"}
		2. Array - [connect args]
		3. String - custom_callback
		"""
		if v == null:
			return

		match typeof(v):
			TYPE_DICTIONARY:
				args = v.get("args", [])
				if not args.empty():
					args = args.duplicate(true)

				custom_callback = v.get("custom_callback", "")
			TYPE_ARRAY:
				args = v.duplicate(true)
			TYPE_STRING:
				custom_callback = v
			_:
				AM.ps.logger.error("Unhandled PubSub Payload param")
				return

class ToggleToggled:
	"""
	Base class for toggle element data
	"""

	var toggle_name := ""
	var toggle_value := false
	
	func _init(p_toggle_name: String, p_toggle_value: bool):
		toggle_name = p_toggle_name
		toggle_value = p_toggle_value

class BoneToggled extends ToggleToggled:
	var toggle_type := ""

	func _init(p_toggle_name: String, p_toggle_type: String, p_toggle_value: bool).(p_toggle_name, p_toggle_value) -> void:
		toggle_type = p_toggle_type

class PropToggled extends ToggleToggled:
	pass

class PresetToggled extends ToggleToggled:
	pass

func register(o: Object, signal_name: String, payload: RegisterPayload = null) -> Result:
	"""
	Wrapper for subscribing (connecting) an object to the PubSub.

	An optional RegisterPayload can be defined to customize the connection args
	"""
	if not has_signal(signal_name):
		return Result.err(Error.Code.SIGNAL_DOES_NOT_EXIST)

	var args := []
	var custom_callback := ""

	if payload != null:
		args.append_array(payload.args)
		custom_callback = payload.custom_callback

	if connect(
		signal_name,
		o,
		"_on_%s" % signal_name if custom_callback.empty() else custom_callback,
		args
	) != OK:
		return Result.err(Error.Code.CONNECT_FAILED)

	return Result.ok()

#region Plugins

var plugins := {}

func register_plugin(plugin: Object, plugin_key: String) -> Result:
	"""
	Registers an external plugin with the PubSub. The plugin_key is generally the plugin's name

	Each plugin must emit a plugin_updated signal

	This signal is only connected upon request in register_for_plugin
	"""
	if plugins.has(plugin_key):
		return Result.err(Error.Code.PUBSUB_PLUGIN_ALREADY_EXISTS)
	
	plugins[plugin_key] = plugin

	return Result.ok()

func unregister_plugin(plugin_key: String) -> Result:
	"""
	Removes a plugin from being registered
	"""
	if plugins.erase(plugin_key):
		return Result.ok()
	return Result.err(Error.Code.PUBSUB_PLUGIN_NOT_FOUND)

func register_for_plugin(plugin_key: String, o: Object, payload: RegisterPayload = null) -> Result:
	if not plugins.has(plugin_key):
		return Result.err(Error.Code.PUBSUB_PLUGIN_NOT_FOUND)

	var args := []
	var custom_callback := ""

	if payload != null:
		args.append_array(payload.args)
		custom_callback = payload.custom_callback

	if plugins[plugin_key].connect(
		"plugin_updated",
		o,
		"_on_%s_updated" % plugin_key if custom_callback.empty() else custom_callback
	) != OK:
		return Result.err(Error.Code.CONNECT_FAILED)

	return Result.ok()

func unregister_for_plugin(o: Object, plugin_key: String, custom_callback: String = "") -> Result:
	if not plugins.has(plugin_key):
		return Result.err(Error.Code.PUBSUB_PLUGIN_NOT_FOUND)

	plugins[plugin_key].disconnect(
		"plugin_updated", o, "_on_%s_updated" % plugin_key if custom_callback.empty() else custom_callback)

	return Result.ok()

#endregion

signal metadata_changed(key, data)
func broadcast_metadata_changed(key: String, data) -> void:
	"""
	All metadata changes are broadcast through this signal

	Metadata values exist across configs
	"""
	emit_signal("metadata_changed", key, data)

signal model_config_data_changed(key, data)
func broadcast_model_config_data_changed(key: String, data) -> void:
	"""
	All config changes are broadcast through this signal.
	It is up to each subscriber to determine whether or not they will handle the changed data.
	"""
	emit_signal("model_config_data_changed", key, data)


signal update_label_text(element_name, value)
func broadcast_update_label_text(element_name: String, value: String) -> void:
	"""
	Usually emitted on a button press.
	
	This is received by a GUI element that changes its label text depending whether
	or not the element_name matches its own.
	"""
	emit_signal("update_label_text", element_name, value)

signal model_loaded(model)
func broadcast_model_loaded(model: BaseModel) -> void:
	"""
	Indicates when it's okay to start applying tracking data
	"""
	emit_signal("model_loaded", model)

#region Builtin screens

#region Model

signal move_model(should_move)
func broadcast_move_model(should_move: bool) -> void:
	"""
	Whether or not the model should be moveable by mouse drag
	"""
	emit_signal("move_model", should_move)

signal rotate_model(should_rotate)
func broadcast_rotate_model(should_rotate: bool) -> void:
	"""
	Whether or not the model should be rotateable by mouse drag
	"""
	emit_signal("rotate_model", should_rotate)

signal zoom_model(should_zoom)
func broadcast_zoom_model(should_zoom: bool) -> void:
	"""
	Whether or not the model should be zoomable by mouse scroll
	"""
	emit_signal("zoom_model", should_zoom)

# TODO should this be here?
signal load_model_dialogue()
func broadcast_load_model_dialogue() -> void:
	"""
	Shows the load model dialogue
	"""
	emit_signal("load_model_dialogue")

# TODO should this be here?
signal set_default_model()
func broadcast_set_default_model() -> void:
	"""
	Sets the current model as the default model
	"""
	emit_signal("set_default_model")

signal reset_model_transform()
func broadcast_reset_model_transform() -> void:
	"""
	Resets the currently loaded model's (plus its parent node's) transform
	"""
	emit_signal("reset_model_transform")

signal a_pose_model()
func broadcast_a_pose_model() -> void:
	"""
	Attempts the A-Pose the current model if possible
	"""
	emit_signal("a_pose_model")

signal t_pose_model()
func broadcast_t_pose_model() -> void:
	"""
	Attempts to T-Pose the current model if possible
	"""
	emit_signal("t_pose_model")

signal bone_toggled(bone_toggled)
func broadcast_bone_toggled(bone_toggled: BoneToggled) -> void:
	"""
	Usually emitted when toggling bones

	Requires a BoneToggled payload to be passed along
	"""
	emit_signal("bone_toggled", bone_toggled)

#endregion

#region Tracking

signal toggle_tracker()
func broadcast_toggle_tracker() -> void:
	"""
	Toggles the current tracker on/off
	"""
	emit_signal("toggle_tracker")

signal toggle_lip_sync()
func broadcast_toggle_lip_sync() -> void:
	"""
	Toggles lip sync on/off
	"""
	emit_signal("toggle_lip_sync")

# TODO started in Tracking.gd -> VRMModel, this is bad
signal blend_shape(shape)
func broadcast_blend_shape(shape: String) -> void:
	"""
	Toggles blend shape to the emitted shape
	"""
	emit_signal("blend_shape", shape)

#endregion

#region Features

# TODO should this be here?
signal add_prop_dialogue()
func broadcast_add_prop_dialogue() -> void:
	"""
	Shows the add prop dialogue popup
	"""
	emit_signal("add_prop_dialogue")

signal prop_toggle_created(element)
func broadcast_prop_toggle_created(element: BaseElement) -> void:
	"""
	Contains the associated toggle for a prop
	"""
	emit_signal("prop_toggle_created", element)

signal prop_toggled(prop_toggled_payload)
func broadcast_prop_toggled(prop_toggled_payload: PropToggled) -> void:
	"""
	Contains information about the prop toggle that was switched on/off
	"""
	emit_signal("prop_toggled", prop_toggled_payload)

signal move_prop(should_move)
func broadcast_move_prop(should_move: bool) -> void:
	"""
	Whether or not the currently selected prop should be moveable by the mouse
	"""
	emit_signal("move_prop", should_move)

signal rotate_prop(should_rotate)
func broadcast_rotate_prop(should_rotate: bool) -> void:
	"""
	Whether or not the currently selected prop should be rotateable by the mouse
	"""
	emit_signal("rotate_prop", should_rotate)

signal zoom_prop(should_zoom)
func broadcast_zoom_prop(should_zoom: bool) -> void:
	"""
	Whether or not the currently selected prop should be zoomable by mouse scroll
	"""
	emit_signal("zoom_prop", should_zoom)

signal delete_prop()
func broadcast_delete_prop() -> void:
	"""
	Indicates that the currently selected prop should be deleted
	"""
	emit_signal("delete_prop")

#endregion

#region Presets

signal new_preset(preset_name)
func broadcast_new_preset(preset_name: String) -> void:
	emit_signal("new_preset", preset_name)

signal preset_toggle_created(element)
func broadcast_preset_toggle_created(element: BaseElement) -> void:
	emit_signal("preset_toggle_created", element)

signal preset_toggled(preset_toggled_payload)
func broadcast_preset_toggled(preset_toggled_payload: PresetToggled) -> void:
	"""
	Contains information about the preset toggle that was switched on/off
	"""
	emit_signal("preset_toggled", preset_toggled_payload)

signal load_preset()
func broadcast_load_preset() -> void:
	"""
	Load the currently toggled preset
	"""
	emit_signal("load_preset")

signal delete_preset()
func broadcast_delete_preset() -> void:
	"""
	Delete the currently toggled preset
	"""
	emit_signal("delete_preset")

#endregion

#region App settings

# TODO should this be here?
signal view_licenses()
func broadcast_view_licenses() -> void:
	emit_signal("view_licenses")

signal reconstruct_views()
func broadcast_reconstruct_views() -> void:
	"""
	Reconstruct the GUI, generally when the user has changed some values
	"""
	emit_signal("reconstruct_views")

signal remove_control_data_received(data)
func broadcast_remote_control_data_received(data: Dictionary) -> void:
	"""
	Rebroadcast the signal and also call the associated signal
	"""
	call("broadcast_%s" % data["signal"], data["value"])
	emit_signal("remove_control_data_received", data)

#endregion

#endregion
