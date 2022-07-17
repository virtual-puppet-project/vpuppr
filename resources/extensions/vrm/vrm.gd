extends DefaultRunner

const VRM_LOADER_PATH := "res://addons/vrm/vrm_loader.gd"

#-----------------------------------------------------------------------------#
# Builtin functions                                                           #
#-----------------------------------------------------------------------------#

func _setup_logger() -> void:
	logger = Logger.new("VRM Runner")

func _setup_scene() -> void:
	# TODO this is hardcoded for testing
	# var default_model_path: String = "res://assets/vrm-models/alicia/AliciaSolid_vrm-0.51.vrm"

	# model_parent = Spatial.new()
	# load_model(default_model_path if not default_model_path.empty() else DEFAULT_MODEL)

	# call_deferred("add_child", model_parent)

	# yield(model, "ready")

	# # Set initial values from config
	# model_intitial_transform = AM.cm.get_data("model_transform")
	# model_parent_initial_transform = AM.cm.get_data("model_parent_transform")
	# model.transform = model_intitial_transform
	# model_parent.transform = model_parent_initial_transform

	# var bone_transforms: Dictionary = AM.cm.get_data("bone_transforms")
	# for bone_idx in model.skeleton.get_bone_count():
	# 	if not bone_idx in bone_transforms:
	# 		continue
	# 	model.skeleton.set_bone_pose(bone_idx, bone_transforms[bone_idx])
	._setup_scene()

func _physics_step(delta: float) -> void:
	._physics_step(delta)
	
	# if not trackers["OpenSeeFace"].is_listening():
	# 	return
	
	# var data = trackers["OpenSeeFace"].get_data()
	# if data == null:
	# 	return

	# TODO hardcoded for osf
	# model.custom_update(trackers["OpenSeeFace"].get_data(), interpolation_data)

#-----------------------------------------------------------------------------#
# Connections                                                                 #
#-----------------------------------------------------------------------------#

#-----------------------------------------------------------------------------#
# Private functions                                                           #
#-----------------------------------------------------------------------------#

#-----------------------------------------------------------------------------#
# Public functions                                                            #
#-----------------------------------------------------------------------------#

func load_vrm(path: String) -> Result:
	logger.info("Using vrm loader")

	var vrm_loader = load(VRM_LOADER_PATH).new()

	var m = vrm_loader.import_scene(path, 1, 1000)
	if m == null:
		return Safely.err(Error.Code.RUNNER_LOAD_FILE_FAILED)

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

	translation_adjustment = Vector3(-1, 1, -1)
	rotation_adjustment = Vector3(1, -1, -1)

	return Safely.ok(m)
