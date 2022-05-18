class_name DefaultRunner
extends RunnerTrait

const CONFIG_LISTEN_VALUES := [
	"apply_translation",
	"apply_rotation",
	"should_track_eye"
]

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
var stored_offsets := StoredOffsets.new()
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

var is_left_clicking := false
var zoom_strength: float = 0.05 # TODO might want to move this to config
var mouse_move_strength: float = 0.002 # TODO might want to move this to config

#endregion

#-----------------------------------------------------------------------------#
# Builtin functions                                                           #
#-----------------------------------------------------------------------------#

func _unhandled_input(event: InputEvent) -> void:
	if event.is_action_pressed("ui_accept"):
		# TODO stub
		pass

	elif event.is_action_pressed("left_click"):
		is_left_clicking = true
	elif event.is_action_released("left_click"):
		is_left_clicking = false
	
	# TODO refactor to reuse logic for posing the model
	if is_left_clicking and event is InputEventMouseMotion:
		if should_move_model:
			model_parent.translate(Vector3(event.relative.x, -event.relative.y, 0.0) * mouse_move_strength)
			get_tree().set_input_as_handled()
		if should_rotate_model:
			model.rotate_x(event.relative.y * mouse_move_strength)
			model.rotate_y(event.relative.x * mouse_move_strength)
			get_tree().set_input_as_handled()
	elif should_zoom_model:
		if event.is_action("scroll_up"):
			model_parent.translate(Vector3(0.0, 0.0, zoom_strength))
			get_tree().set_input_as_handled()
		elif event.is_action("scroll_down"):
			model_parent.translate(Vector3(0.0, 0.0, -zoom_strength))
			get_tree().set_input_as_handled()

func _setup_logger() -> void:
	logger = Logger.new("DefaultRunner")

func _setup_config() -> void:
	for i in CONFIG_LISTEN_VALUES:
		AM.ps.subscribe(self, i, {
			"args": [i],
			"callback": "_on_config_changed"
		})

func _setup_scene() -> void:
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

func _physics_step(delta: float) -> void:
	if not tracker.is_listening():
		return

	# TODO hardcoded for OpenSeeFace
	var data: OpenSeeFaceData = tracker.get_data()
	
	if not data or data.get_confidence() > 100.0: # TODO 100.0 is hardcoded from the osf impl
		return

	if data.get_updated_time() > updated_time:
		updated_time = data.get_updated_time()
		var corrected_euler := data.get_euler()
		if corrected_euler.x < 0.0:
			corrected_euler.x = 360.0 + corrected_euler.x

		# TODO hardcoded for osf
		var osf_features: OpenSeeFaceFeatures = data.get_additional_info()

		interpolation_data.update_values(
			updated_time,
			
			stored_offsets.translation_offset - data.get_translation(),
			stored_offsets.euler_offset - corrected_euler,
			
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
		interpolation_data.bone_translation.interpolate(delta),
		interpolation_data.bone_rotation.interpolate(delta)
	)

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

#-----------------------------------------------------------------------------#
# Private functions                                                           #
#-----------------------------------------------------------------------------#

func _try_load_model(path: String) -> Result:
	var result := ._try_load_model(path)
	if result.is_err():
		return result

	match path.get_extension().to_lower():
		"glb":
			translation_adjustment = Vector3(1, -1, 1)
			rotation_adjustment = Vector3(-1, -1, 1)
		"tscn", "scn":
			translation_adjustment = Vector3(1, -1, 1)
			rotation_adjustment = Vector3(-1, -1, 1)

	return result

#-----------------------------------------------------------------------------#
# Public functions                                                            #
#-----------------------------------------------------------------------------#

func load_model(path: String) -> void:
	logger.info("Starting load_model for %s" % path)

	.load_model(path)

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
