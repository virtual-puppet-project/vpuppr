class_name DefaultRunner
extends RunnerTrait

## Config-specific pubsub values to listen for
const CONFIG_LISTEN_VALUES := [
	"apply_translation",
	"apply_rotation",
	"should_track_eye",

	"stage_world_background_color",

	"use_transparent_background",
	"use_fxaa"
]

## The default script to be applied to models
const PUPPET_TRAIT_SCRIPT_PATH := "res://model/extensions/puppet_trait.gd"

const MODEL_TO_LOAD := "model_to_load"
const MODEL_INITIAL_TRANSFORM := "model_initial_transform"
const MODEL_PARENT_INITIAL_TRANSFORM := "model_parent_initial_transform"

var model_viewport := Viewport.new()

var model: PuppetTrait
var model_parent: Spatial

var main_light: Light
var main_camera: Camera
var main_world: World

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
			AM.ps.publish("model_parent_transform", model_parent.transform)
			get_tree().set_input_as_handled()

	# TODO how data is published here is pretty gross
	if should_pose_model and bone_to_pose > 0:
		var config_data = AM.cm.get_data(Globals.BONE_TRANSFORMS)
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
		AM.ps.publish(Globals.BONE_TRANSFORMS, config_data, model.skeleton.get_bone_name(bone_to_pose))

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
		_on_config_changed(SignalPayload.new(i, val), i)

func _pre_setup_scene() -> void:
	AM.ps.subscribe(self, Globals.EVENT_PUBLISHED)
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

	# TODO pull settings from config
	main_light = DirectionalLight.new()
	main_light.light_energy = 0.5
	model_viewport.add_child(main_light)

	main_camera = Camera.new()
	main_camera.current = true
	main_camera.translate(Vector3(0.0, 0.0, 3.0))
	model_viewport.add_child(main_camera)

	main_world = World.new()
	main_world.environment = load("res://assets/default_env.tres")
	model_viewport.world = main_world

	model_parent = Spatial.new()

func _setup_scene() -> void:
	var model_to_load_path := ""
	var res := Safely.wrap(AM.tcm.pull(MODEL_TO_LOAD, AM.cm.get_data("default_model_path")))
	if res.is_err():
		logger.error("Unable to find a model to load")
		res = Safely.wrap(Globals.DEFAULT_MODEL_PATH)

	AM.cm.model_config = ModelConfig.new()

	if res.unwrap().ends_with(".json"):
		AM.cm.load_model_config(res.unwrap())
		model_to_load_path = AM.cm.model_config.model_path
	else:
		model_to_load_path = res.unwrap()
	
	if model_to_load_path.empty():
		logger.error("Tried to load a model at an empty path")
		model_to_load_path = Globals.DEFAULT_MODEL_PATH

	res = load_model(model_to_load_path)
	if res.is_err():
		logger.error(res)
		return

	model_viewport.call_deferred("add_child", model_parent)

	yield(model, "ready")

	var model_transform = AM.cm.get_data("model_transform")
	if model_transform != null and model_transform != Transform.IDENTITY:
		model.transform = model_transform
	var model_parent_transform = AM.cm.get_data("model_parent_transform")
	if model_parent_transform != null and model_parent_transform != Transform.IDENTITY:
		model_parent.transform = model_parent_transform

	AM.tcm.push(MODEL_INITIAL_TRANSFORM, model.transform).cleanup_on_signal(self, "tree_exiting")
	AM.tcm.push(MODEL_PARENT_INITIAL_TRANSFORM, model_parent.transform).cleanup_on_signal(self, "tree_exiting")

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

func _teardown() -> void:
	._teardown()

func _generate_preview() -> void:
	var image := model_viewport.get_texture().get_data()
	image.flip_y()

	var dir := Directory.new()
	if not dir.dir_exists(Globals.RUNNER_PREVIEW_DIR_PATH):
		if dir.make_dir_recursive(Globals.RUNNER_PREVIEW_DIR_PATH) != OK:
			logger.error("Unable to create %s, declining to create runner preview" %
				Globals.RUNNER_PREVIEW_DIR_PATH)
			return

	if image.save_png("%s/%s.%s" % [
		Globals.RUNNER_PREVIEW_DIR_PATH,
		name,
		Globals.RUNNER_PREVIEW_FILE_EXT
	]) != OK:
		logger.error("Unable to save image preview")

#-----------------------------------------------------------------------------#
# Connections                                                                 #
#-----------------------------------------------------------------------------#

# TODO consolidate with event published
func _on_config_changed(payload: SignalPayload, signal_name: String) -> void:
	match signal_name:
		#region Config

		"apply_translation":
			apply_translation = payload.data
		"apply_rotation":
			apply_rotation = payload.data
		"should_track_eye":
			should_track_eye = payload.data

		"use_transparent_background":
			ProjectSettings.set_setting("display/window/per_pixel_transparency/allowed", payload.data)
			ProjectSettings.set_setting("display/window/per_pixel_transparency/enabled", payload.data)
			get_viewport().transparent_bg = payload.data
			model_viewport.transparent_bg = payload.data
		"use_fxaa":
			ProjectSettings.set_setting("rendering/quality/filters/use_fxaa", payload.data)
			get_viewport().fxaa = payload.data
			model_viewport.fxaa = payload.data
		
		#endregion

		#region Scene

		Globals.SceneSignals.POSE_MODEL:
			should_pose_model = payload.data

		#endregion

		_:
			logger.error("Unhandled signal %s with value %s" % [signal_name, str(payload)])

func _on_event_published(payload: SignalPayload) -> void:
	match payload.signal_name:
		Globals.SceneSignals.MOVE_MODEL:
			should_move_model = payload.data
		Globals.SceneSignals.ROTATE_MODEL:
			should_rotate_model = payload.data
		Globals.SceneSignals.ZOOM_MODEL:
			should_zoom_model = payload.data
		Globals.POSE_BONE:
			should_pose_model = payload.data
			bone_to_pose = model.skeleton.find_bone(payload.id)
		Globals.TRACKER_USE_AS_MAIN_TRACKER:
			for tracker in trackers:
				if tracker.get_name() == payload.data:
					main_tracker = tracker
					return
		Globals.RELOAD_RUNNER:
			if typeof(payload.data) != TYPE_STRING:
				logger.error("Invalid type for %s, data must be a String" % Globals.RELOAD_RUNNER)
				return

			var tcm: TempCacheManager = AM.tcm
			tcm.push(MODEL_TO_LOAD, payload.data).cleanup_on_pull()
			
			var runner_path := ""
			var res: Result = Safely.wrap(tcm.pull("runner_path"))
			if res.is_err():
				logger.error(res)
				return
			runner_path = res.unwrap()

			var gui_path := ""
			res = Safely.wrap(tcm.pull("gui_path"))
			if res.is_err():
				logger.error(res)
				return
			gui_path = res.unwrap()

			res = Safely.wrap(FileUtil.switch_to_runner(runner_path, gui_path))
			if res.is_err():
				logger.error(res)
		"stage_world_background_color":
			main_world.environment.background_color = payload.data

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

func get_stage() -> Dictionary:
	return {
		"main_camera": main_camera,
		"main_light": main_light,
		"main_world": main_world
	}

func load_model(path: String) -> Result:
	logger.info("Starting load_model for %s" % path)

	var res := Safely.wrap(_try_load_model(path))
	if res.is_err():
		logger.error(res)
		# If this fails, something is very very wrong
		res = Safely.wrap(_try_load_model(Globals.DEFAULT_MODEL_PATH))
		if res.is_err():
			get_tree().change_scene(Globals.LANDING_SCREEN_PATH)
			return res

	if model != null:
		model.free()
	model = res.unwrap()
	model_parent.add_child(model)

	var model_name := FileUtil.path_to_stripped_name(path)
	if AM.cm.model_config.model_name.empty():
		logger.info("Loading config for model")

		res = Safely.wrap(AM.cm.load_model_config("%s.%s" % [model_name, ConfigManager.CONFIG_FILE_EXTENSION]))
		if res.is_err():
			logger.info("No existing config found, creating new config")

			res = Safely.wrap(AM.cm.create_new_model_config(model_name, path, model_name))
			if res.is_err():
				return res

			AM.cm.model_config = res.unwrap()
			AM.ps.publish("is_default_for_model", true)

		logger.info("Finished loading config")

	logger.info("Finished load_model for %s" % path)

	return Safely.ok()

func load_glb(path: String) -> Result:
	var res := .load_glb(path)
	if res.is_err():
		return res

	var script: GDScript = load(PUPPET_TRAIT_SCRIPT_PATH)
	if script == null:
		return Safely.err(Error.Code.RUNNER_LOAD_FILE_FAILED, "Unable to load puppet trait script")
	
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
