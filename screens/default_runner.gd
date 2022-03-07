class_name DefaultRunner
extends RunnerTrait

const CONFIG_LISTEN_VALUES := [
	"apply_translation",
	"apply_rotation",
	"should_track_eye"
]

const DUCK_PATH := "res://entities/duck/duck.tscn"

const BASE_MODEL_SCRIPT_PATH := "res://entities/base_model.gd"

var model: PuppetTrait
var model_parent: Spatial
var props_node: Spatial

# Store transforms se we can easily reset
var model_intitial_transform := Transform()
var model_parent_initial_transform := Transform()

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

var zoom_strength: float = 0.05
var mouse_move_strength: float = 0.002

#endregion

###############################################################################
# Builtin functions                                                           #
###############################################################################

func _physics_process(delta: float) -> void:
	
	pass

func _setup_logger() -> void:
	logger = Logger.new("DefaultRunner")

func _setup_config() -> void:
	._setup_config()

func _setup_scene() -> void:
	var camera := Camera.new()
	camera.current = true
	camera.translate(Vector3(0.0, 0.0, 3.0))
	add_child(camera)
	
	var default_model_path: String = AM.cm.get_data("default_model_path")

	var result := _try_load_model(default_model_path if not default_model_path.empty() else DUCK_PATH)
	if result == null or result.is_err():
		logger.error(result.unwrap_err().to_string() if result != null else "Something super broke, please check the logs")
		# If this fails, something is very wrong
		result = _try_load_model(DUCK_PATH)
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

###############################################################################
# Connections                                                                 #
###############################################################################

###############################################################################
# Private functions                                                           #
###############################################################################

###############################################################################
# Public functions                                                            #
###############################################################################
