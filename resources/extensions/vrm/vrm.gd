extends DefaultRunner

const VRM_LOADER_PATH := "res://addons/vrm/vrm_loader.gd"

###############################################################################
# Builtin functions                                                           #
###############################################################################

func _ready() -> void:
	var ext: Extension = AM.em.get_extension("VRM").unwrap()
	var ext_res: ExtensionResource = ext.resources["VRM Runner"]
	logger.info(str(ext_res.other))
	pass

func _unhandled_input(event: InputEvent) -> void:
	pass

func _setup_logger() -> void:
	logger = Logger.new("VRM Runner")

func _setup_scene() -> void:
	var camera := Camera.new()
	camera.current = true
	camera.translate(Vector3(0.0, 0.0, 3.0))
	add_child(camera)
	
	# TODO this is hardcoded for testing
	var default_model_path: String = "res://assets/vrm-models/alicia/AliciaSolid_vrm-0.51.vrm"

	var result := _try_load_model(default_model_path if not default_model_path.empty() else DEFAULT_MODEL)
	if result == null or result.is_err():
		logger.error(result.unwrap_err().to_string() if result != null else "Something super broke, please check the logs")
		# If this fails, something is very wrong
		result = _try_load_model(DEFAULT_MODEL)
		if result == null or result.is_err():
			logger.error(result.unwrap_err().to_string() if result != null else "Something super broke, please check the logs")
			logger.error("Failed loading the default Duck model")
			get_tree().change_scene(GlobalConstants.LANDING_SCREEN_PATH)

	model = result.unwrap()

	model_parent = Spatial.new()
	model_parent.add_child(model)

	call_deferred("add_child", model_parent)

	yield(model, "ready")

	# Set initial values from config
	# TODO add flag for vrm models to check and see if we should use the default model spin
	model_intitial_transform = AM.cm.get_data("model_transform")
	model_parent_initial_transform = AM.cm.get_data("model_parent_transform")
	model.transform = model_intitial_transform
	model_parent.transform = model_parent_initial_transform

	var bone_transforms: Dictionary = AM.cm.get_data("bone_transforms")
	for bone_idx in model.skeleton.get_bone_count():
		if not bone_idx in bone_transforms:
			continue
		model.skeleton.set_bone_pose(bone_idx, bone_transforms[bone_idx])

func _try_load_model(path: String) -> Result:
	logger.info("using vrm try load")
	var result := ._try_load_model(path)
	if result.is_err():
		return result

	if path.get_extension().to_lower() != "vrm":
		return result

	logger.info("spinning the model")

	var model: PuppetTrait = result.unwrap()
	# model.transform = model.transform.rotated(Vector3.UP, PI)

	translation_adjustment = Vector3(-1, -1, -1)
	rotation_adjustment = Vector3(1, -1, -1)

	return Result.ok(model)

###############################################################################
# Connections                                                                 #
###############################################################################

###############################################################################
# Private functions                                                           #
###############################################################################

###############################################################################
# Public functions                                                            #
###############################################################################

func load_vrm(path: String) -> Result:
	var vrm_loader = load(VRM_LOADER_PATH).new()

	var m = vrm_loader.import_scene(path, 1, 1000)
	if m == null:
		return Result.err(Error.Code.RUNNER_LOAD_FILE_FAILED)

	# TODO: this needs to be futher looked at, as it seems like a hack
	# vrm_meta needs to be read, stored in a var, and then AFTER
	# set_script it needs to be set again, otherwise it somehow 
	# isnt there when the script runs
	var vrm_meta = m.vrm_meta

	var script_res: Result = AM.em.find_in_extensions("VRM/resources/VRM Model/resource_entrypoint")
	if script_res.is_err():
		logger.error(script_res.to_string())
		return script_res
	m.set_script(load(script_res.unwrap()))

	m.vrm_meta = vrm_meta
	m.transform = m.transform.rotated(Vector3.UP, PI)

	return Result.ok(m)
