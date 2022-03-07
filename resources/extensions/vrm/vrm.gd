extends RunnerTrait

const VRM_LOADER_PATH := "res://addons/vrm/vrm_loader.gd"
const VRM_MODEL_SCRIPT_PATH := "res://entities/vrm_model.gd"

###############################################################################
# Builtin functions                                                           #
###############################################################################

func _ready() -> void:
	pass

###############################################################################
# Connections                                                                 #
###############################################################################

###############################################################################
# Private functions                                                           #
###############################################################################

func _setup_logger() -> void:
	logger = Logger.new("VRM Runner")

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

	m.set_script(load(VRM_MODEL_SCRIPT_PATH))

	m.vrm_meta = vrm_meta
	m.transform = m.transform.rotated(Vector3.UP, PI)

	return Result.ok(m)
