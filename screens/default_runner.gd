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
# const SCENE_LISTEN_VALUES := [
# 	GlobalConstants.SceneSignals.MOVE_MODEL,
# 	GlobalConstants.SceneSignals.ROTATE_MODEL,
# 	GlobalConstants.SceneSignals.ZOOM_MODEL,

# 	GlobalConstants.SceneSignals.POSE_MODEL
# ]

## The default script to be applied to models
const PUPPET_TRAIT_SCRIPT_PATH := "res://model/extensions/puppet_trait.gd"

const MODEL_TO_LOAD := "model_to_load"

# TODO this might be bad?
var model_viewport := Viewport.new()

var model: PuppetTrait
var model_parent: Spatial
var props_node: Spatial

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
	# for i in SCENE_LISTEN_VALUES:
	# 	AM.ps.create_signal(i)
	# 	AM.ps.subscribe(self, i, {
	# 		"args": [i],
	# 		"callback": "_on_config_changed"
	# 	})

	var viewport_container := ViewportContainer.new()
	viewport_container.anchor_bottom = 1.0
	viewport_container.anchor_right = 1.0
	viewport_container.stretch = true
	viewport_container.mouse_filter = Control.MOUSE_FILTER_IGNORE

	add_child(viewport_container)
	move_child(viewport_container, 0)

	model_viewport.size = viewport_container.rect_size
	model_viewport.own_world = true

	viewport_container.add_child(model_viewport)

	var camera := Camera.new()
	camera.current = true
	camera.translate(Vector3(0.0, 0.0, 3.0))
	model_viewport.add_child(camera)

	var world := World.new()
	world.environment = load("res://assets/default_env.tres")
	model_viewport.world = world

func _setup_scene() -> void:
	var model_to_load_path := ""
	var model_to_load_res = AM.tcm.pull(MODEL_TO_LOAD, AM.cm.get_data("default_model_path"))
	if not model_to_load_res or model_to_load_res.is_err():
		logger.error("Unable to find a model to load")
		model_to_load_path = GlobalConstants.DEFAULT_MODEL_PATH
	else:
		model_to_load_path = model_to_load_res.unwrap()
	
	if model_to_load_path.empty():
		logger.error("Tried to load a model at an empty path")
		model_to_load_path = GlobalConstants.DEFAULT_MODEL_PATH

	model_parent = Spatial.new()
	load_model(model_to_load_path)

	model_viewport.call_deferred("add_child", model_parent)

	yield(model, "ready")

	model.transform = AM.cm.get_data("model_transform")
	model_parent.transform = AM.cm.get_data("model_parent_transform")

func _physics_step(_delta: float) -> void:
	if trackers.empty():
		return
	
	for tracker in trackers:
		tracker.apply(model, interpolation_data, {
			"stored_offsets": stored_offsets,
			"runner": self
		})
	
	model.apply_movement(
		interpolation_data.bone_translation.interpolate() * translation_adjustment if apply_translation 
			else Vector3.ZERO,
		interpolation_data.bone_rotation.interpolate() * rotation_adjustment if apply_rotation
			else Vector3.ZERO
	)

func _generate_preview() -> void:
	var image := model_viewport.get_texture().get_data()
	image.flip_y()

	var dir := Directory.new()
	if not dir.dir_exists(GlobalConstants.RUNNER_PREVIEW_DIR_PATH):
		if dir.make_dir_recursive(GlobalConstants.RUNNER_PREVIEW_DIR_PATH) != OK:
			logger.error("Unable to create %s, declining to create runner preview" %
				GlobalConstants.RUNNER_PREVIEW_DIR_PATH)
			return

	if image.save_png("%s/%s.%s" % [
		GlobalConstants.RUNNER_PREVIEW_DIR_PATH,
		name,
		GlobalConstants.RUNNER_PREVIEW_FILE_EXT
	]) != OK:
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
			model_viewport.transparent_bg = value
		"use_fxaa":
			ProjectSettings.set_setting("rendering/quality/filters/use_fxaa", value)
			get_viewport().fxaa = value
			model_viewport.fxaa = value
		
		#endregion

		#region Scene

		# GlobalConstants.SceneSignals.MOVE_MODEL:
		# 	should_move_model = value
		# GlobalConstants.SceneSignals.ROTATE_MODEL:
		# 	should_rotate_model = value
		# GlobalConstants.SceneSignals.ZOOM_MODEL:
		# 	should_zoom_model = value

		GlobalConstants.SceneSignals.POSE_MODEL:
			should_pose_model = value

		#endregion

		_:
			logger.error("Unhandled signal %s with value %s" % [signal_name, str(value)])

func _on_event_published(payload: SignalPayload) -> void:
	match payload.signal_name:
		GlobalConstants.SceneSignals.MOVE_MODEL:
			should_move_model = payload.data
		GlobalConstants.SceneSignals.ROTATE_MODEL:
			should_rotate_model = payload.data
		GlobalConstants.SceneSignals.ZOOM_MODEL:
			should_zoom_model = payload.data
		GlobalConstants.POSE_BONE:
			should_pose_model = payload.data
			bone_to_pose = model.skeleton.find_bone(payload.id)
		GlobalConstants.TRACKER_USE_AS_MAIN_TRACKER:
			for tracker in trackers:
				if tracker.get_name() == payload.data:
					main_tracker = tracker
					return
		GlobalConstants.RELOAD_RUNNER:
			var tcm: TempCacheManager = AM.tcm
			tcm.push(MODEL_TO_LOAD, payload.data)
			
			var runner_path := ""
			var res: Result = tcm.pull("runner_path")
			if res == null or res.is_err():
				logger.error(res.to_string())
				return
			runner_path = res.unwrap()

			var gui_path := ""
			res = tcm.pull("gui_path")
			if Result.failed(res):
				logger.error(Result.to_log_string(res))
				return
			gui_path = res.unwrap()

			res = FileUtil.switch_to_runner(runner_path, gui_path)
			if Result.failed(res):
				logger.error(Result.to_log_string(res))

#-----------------------------------------------------------------------------#
# Private functions                                                           #
#-----------------------------------------------------------------------------#

func _save_offsets() -> void:
	if main_tracker == null:
		logger.error("No main tracker defined")
		return

	main_tracker.set_offsets(stored_offsets)

#-----------------------------------------------------------------------------#
# Public functions                                                            #
#-----------------------------------------------------------------------------#

func load_model(path: String) -> void:
	logger.info("Starting load_model for %s" % path)

	var result := _try_load_model(path)
	if result == null or result.is_err():
		logger.error(result.unwrap_err().to_string() if result != null else "Something super broke, please check the logs")
		# If this fails, something is very very wrong
		result = _try_load_model(GlobalConstants.DEFAULT_MODEL_PATH)
		if result == null or result.is_err():
			logger.error(result.unwrap_err().to_string() if result != null else "Something super broke, please check the logs")
			logger.error("Failed loading the default Duck model")
			get_tree().change_scene(GlobalConstants.LANDING_SCREEN_PATH)
			return

	if model != null:
		model.free()
	model = result.unwrap()
	model_parent.add_child(model)

	var model_name := ConfigManager.path_to_stripped_name(path)
	# TODO this needs to pull the default config from metadata
	var config_result: Result = AM.cm.load_model_config("%s.%s" % [model_name, ConfigManager.CONFIG_FILE_EXTENSION])
	if config_result.is_err():
		logger.info("Config for %s not found. Creating new config" % model_name)
		
		var config_res: Result = AM.cm.create_new_model_config(model_name, path, model_name)
		if Result.failed(config_res):
			logger.error(Result.to_log_string(config_res))
			logger.error("Failed creating a new config, be aware things might be broken")
			return

		var model_config = config_res.unwrap()
		model_config.is_default_for_model = true # Must be default since we didn't find any default configs

		AM.cm.model_config = model_config

	logger.info("Finished load_model for %s" % path)

func load_glb(path: String) -> Result:
	var res := .load_glb(path)
	if res.is_err():
		return res

	var script: GDScript = load(PUPPET_TRAIT_SCRIPT_PATH)
	if script == null:
		return Result.err(Error.Code.RUNNER_LOAD_FILE_FAILED, "Unable to load puppet trait script")
	
	res.unwrap().set_script(script)

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
