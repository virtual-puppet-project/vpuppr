class_name DefaultRunner
extends RunnerTrait

## Config-specific pubsub values to listen for
const CONFIG_LISTEN_VALUES := [
	"apply_translation",
	"apply_rotation",
	"should_track_eye",

	"use_transparent_background",
	"use_fxaa"
]

## Scene-specific pubsub values to listen for
const SCENE_LISTEN_VALUES := [
	GlobalConstants.SceneSignals.MOVE_MODEL,
	GlobalConstants.SceneSignals.ROTATE_MODEL,
	GlobalConstants.SceneSignals.ZOOM_MODEL,

	GlobalConstants.SceneSignals.POSE_MODEL
]

var model: PuppetTrait
var model_parent: Spatial
var props_node: Spatial

# Store transforms se we can easily reset
var model_intitial_transform := Transform()
var model_parent_initial_transform := Transform()

var updated_time: float = 0.0
var stored_offsets: StoredOffsets
var interpolation_data := InterpolationData.new()

var translation_adjustment := Vector3.ONE
var rotation_adjustment := Vector3.ONE

#region Tracking options from ConfigManager

var apply_translation := false
var apply_rotation := true
var should_track_eye := true

#endregion

#region Input

var should_move_model := false
var should_rotate_model := false
var should_zoom_model := false

var should_pose_model := false
var bone_to_pose: int = -1

var is_left_clicking := false
var zoom_strength: float = 0.05 # TODO might want to move this to config
var mouse_move_strength: float = 0.002 # TODO might want to move this to config

#endregion

#-----------------------------------------------------------------------------#
# Builtin functions                                                           #
#-----------------------------------------------------------------------------#

func _unhandled_input(event: InputEvent) -> void:
	if event.is_action_pressed("ui_accept"):
		_save_offsets()

	elif event.is_action_pressed("left_click"):
		is_left_clicking = true
	elif event.is_action_released("left_click"):
		is_left_clicking = false
	
	if is_left_clicking and event is InputEventMouseMotion:
		if should_move_model:
			model_parent.translate(Vector3(event.relative.x, -event.relative.y, 0.0) * mouse_move_strength)
			AM.ps.publish("model_parent_transform", model_parent.transform)
			get_tree().set_input_as_handled()
		if should_rotate_model:
			model.rotate_x(event.relative.y * mouse_move_strength)
			model.rotate_y(event.relative.x * mouse_move_strength)
			AM.ps.publish("model_transform", model.transform)
			get_tree().set_input_as_handled()
	elif should_zoom_model:
		if event.is_action("scroll_up"):
			model_parent.translate(Vector3(0.0, 0.0, zoom_strength))
			AM.ps.publish("model_parent_transform", model_parent.transform)
			get_tree().set_input_as_handled()
		elif event.is_action("scroll_down"):
			model_parent.translate(Vector3(0.0, 0.0, -zoom_strength))
			AM.ps.publish("model_transform", model.transform)
			get_tree().set_input_as_handled()

	# TODO how data is published here is pretty gross
	if should_pose_model and bone_to_pose > 0:
		var config_data = AM.cm.get_data(GlobalConstants.BONE_TRANSFORMS)
		var transform: Transform = model.skeleton.get_bone_pose(bone_to_pose)

		if is_left_clicking and event is InputEventMouseMotion:
			transform = transform.rotated(Vector3.UP, event.relative.x * mouse_move_strength)
			transform = transform.rotated(Vector3.RIGHT, event.relative.y * mouse_move_strength)

			model.skeleton.set_bone_pose(bone_to_pose, transform)
			
			get_tree().set_input_as_handled()
		
		if event.is_action("scroll_up"):
			transform = transform.rotated(Vector3.FORWARD, zoom_strength)
			model.skeleton.set_bone_pose(bone_to_pose, transform)
			get_tree().set_input_as_handled()
		elif event.is_action("scroll_down"):
			transform = transform.rotated(Vector3.FORWARD, -zoom_strength)
			model.skeleton.set_bone_pose(bone_to_pose, transform)
			get_tree().set_input_as_handled()

		config_data[model.skeleton.get_bone_name(bone_to_pose)] = transform
		AM.ps.publish(GlobalConstants.BONE_TRANSFORMS, config_data, model.skeleton.get_bone_name(bone_to_pose))

func _setup_logger() -> void:
	logger = Logger.new("DefaultRunner")

func _setup_config() -> void:
	for i in CONFIG_LISTEN_VALUES:
		AM.ps.subscribe(self, i, {
			"args": [i],
			"callback": "_on_config_changed"
		})

		var val = AM.cm.get_data(i)
		if typeof(val) == TYPE_NIL:
			logger.error("Config value %s is null" % i)
			continue
		_on_config_changed(val, i)

func _pre_setup_scene() -> void:
	AM.ps.subscribe(self, GlobalConstants.EVENT_PUBLISHED)
	for i in SCENE_LISTEN_VALUES:
		AM.ps.create_signal(i)
		AM.ps.subscribe(self, i, {
			"args": [i],
			"callback": "_on_config_changed"
		})

	var camera := Camera.new()
	camera.current = true
	camera.translate(Vector3(0.0, 0.0, 3.0))
	add_child(camera)

	var world_environment := WorldEnvironment.new()
	world_environment.environment = load("res://assets/default_env.tres")
	add_child(world_environment)

	# TODO this shouldn't be done like this
	var open_see_face_res: Result = AM.em.load_resource("OpenSeeFace", "open_see_face.gd")
	if not open_see_face_res or open_see_face_res.is_err():
		logger.err(open_see_face_res.unwrap_err().to_string() if open_see_face_res else "Unable to load face tracker")
		return
	trackers["OpenSeeFace"] = open_see_face_res.unwrap().new()
	add_child(trackers["OpenSeeFace"])

func _setup_scene() -> void:
	var default_model_path: String = AM.cm.get_data("default_model_path")

	model_parent = Spatial.new()
	load_model(default_model_path if not default_model_path.empty() else DEFAULT_MODEL)

	call_deferred("add_child", model_parent)

	yield(model, "ready")

	# Set initial values from config
	model_intitial_transform = AM.cm.get_data("model_transform")
	model_parent_initial_transform = AM.cm.get_data("model_parent_transform")
	model.transform = model_intitial_transform
	model_parent.transform = model_parent_initial_transform

	var bone_transforms: Dictionary = AM.cm.get_data("bone_transforms")
	for bone_idx in model.skeleton.get_bone_count():
		if not bone_idx in bone_transforms:
			continue
		model.skeleton.set_bone_pose(bone_idx, bone_transforms[bone_idx])

func _physics_step(_delta: float) -> void:
	# TODO hardcoded for OpenSeeFace
	if not trackers["OpenSeeFace"].is_listening():
		return

	# TODO hardcoded for OpenSeeFace
	var data: TrackingDataInterface = trackers["OpenSeeFace"].get_data()
	
	if not data or data.get_confidence() > 100.0: # TODO 100.0 is hardcoded from the osf impl
		return

	if stored_offsets == null:
		_save_offsets()

	if data.get_updated_time() > updated_time:
		updated_time = data.get_updated_time()
		var corrected_euler = data.get_euler()

		# TODO hardcoded for osf
		var osf_features = data.get_additional_info()

		interpolation_data.update_values(
			updated_time,
			
			stored_offsets.translation_offset - data.get_translation(),
			stored_offsets.rotation_offset - corrected_euler,
			
			stored_offsets.left_eye_gaze_offset - data.get_left_eye_rotation().get_euler(),
			stored_offsets.right_eye_gaze_offset - data.get_right_eye_rotation().get_euler(),
			data.get_left_eye_open_amount(),
			data.get_right_eye_open_amount(),
			
			data.get_mouth_open_amount(),
			data.get_mouth_wide_amount(),
			
			osf_features.eyebrow_steepness_left,
			osf_features.eyebrow_steepness_right,
			
			osf_features.eyebrow_up_down_left,
			osf_features.eyebrow_up_down_right,
			
			osf_features.eyebrow_quirk_left,
			osf_features.eyebrow_quirk_right
		)
	
	model.apply_movement(
		interpolation_data.bone_translation.interpolate() * translation_adjustment if apply_translation 
			else Vector3.ZERO,
		interpolation_data.bone_rotation.interpolate() * rotation_adjustment if apply_rotation
			else Vector3.ZERO
	)

func _generate_preview() -> void:
	

	var image := get_viewport().get_texture().get_data()
	image.flip_y()

	if image.save_png("user://%s.png" % name) != OK:
		logger.error("Unable to save image preview")

#-----------------------------------------------------------------------------#
# Connections                                                                 #
#-----------------------------------------------------------------------------#

func _on_config_changed(value, signal_name: String) -> void:
	match signal_name:
		#region Config

		"apply_translation":
			apply_translation = value
		"apply_rotation":
			apply_rotation = value
		"should_track_eye":
			should_track_eye = value

		"use_transparent_background":
			ProjectSettings.set_setting("display/window/per_pixel_transparency/allowed", value)
			ProjectSettings.set_setting("display/window/per_pixel_transparency/enabled", value)
			get_viewport().transparent_bg = value
		"use_fxaa":
			ProjectSettings.set_setting("rendering/quality/filters/use_fxaa", value)
			get_viewport().fxaa = value
		
		#endregion

		#region Scene

		GlobalConstants.SceneSignals.MOVE_MODEL:
			should_move_model = value
		GlobalConstants.SceneSignals.ROTATE_MODEL:
			should_rotate_model = value
		GlobalConstants.SceneSignals.ZOOM_MODEL:
			should_zoom_model = value

		GlobalConstants.SceneSignals.POSE_MODEL:
			should_pose_model = value

		#endregion

		_:
			logger.error("Unhandled signal %s with value %s" % [signal_name, str(value)])

func _on_event_published(payload: SignalPayload) -> void:
	match payload.signal_name:
		GlobalConstants.POSE_BONE:
			should_pose_model = payload.data
			bone_to_pose = model.skeleton.find_bone(payload.id)

#-----------------------------------------------------------------------------#
# Private functions                                                           #
#-----------------------------------------------------------------------------#

func _save_offsets() -> void:
	# TODO hardcoded for OpenSeeFace
	if not trackers["OpenSeeFace"].is_listening():
		return

	if stored_offsets == null:
		stored_offsets = StoredOffsets.new()

	# TODO hardcoded for osf
	var data: TrackingDataInterface = trackers["OpenSeeFace"].get_data()

	stored_offsets.translation_offset = data.get_translation()
	stored_offsets.rotation_offset = data.get_euler()
	stored_offsets.quat_offset = data.get_rotation()
	stored_offsets.left_eye_gaze_offset = data.get_left_eye_euler()
	stored_offsets.right_eye_gaze_offset = data.get_right_eye_euler()

#-----------------------------------------------------------------------------#
# Public functions                                                            #
#-----------------------------------------------------------------------------#

func load_model(path: String) -> void:
	logger.info("Starting load_model for %s" % path)

	var result := _try_load_model(path)
	if result == null or result.is_err():
		logger.error(result.unwrap_err().to_string() if result != null else "Something super broke, please check the logs")
		# If this fails, something is very very wrong
		result = _try_load_model(DEFAULT_MODEL)
		if result == null or result.is_err():
			logger.error(result.unwrap_err().to_string() if result != null else "Something super broke, please check the logs")
			logger.error("Failed loading the default Duck model")
			get_tree().change_scene(GlobalConstants.LANDING_SCREEN_PATH)
			return

	if model != null:
		model.free()
	model = result.unwrap()
	model_parent.add_child(model)

	var model_name := path.get_file().get_basename()
	var config_result: Result = AM.cm.load_model_config("%s.%s" % [model_name, ConfigManager.CONFIG_FILE_EXTENSION])
	if config_result.is_err():
		logger.info("Config for %s not found. Creating new config" % model_name)

		var mc := ModelConfig.new()
		mc.config_name = model_name
		mc.model_name = model_name
		mc.model_path = path

		AM.cm.model_config = mc

	logger.info("Finished load_model for %s" % path)

func load_glb(path: String) -> Result:
	var res := .load_glb(path)
	if res.is_err():
		return res

	translation_adjustment = Vector3.ONE
	rotation_adjustment = Vector3(-1, -1, 1)

	return res

func load_scn(path: String) -> Result:
	var res := .load_scn(path)
	if res.is_err():
		return res

	translation_adjustment = Vector3.ONE
	rotation_adjustment = Vector3(-1, -1, 1)

	return res

func load_tscn(path: String) -> Result:
	return .load_tscn(path)
