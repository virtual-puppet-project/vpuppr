extends Spatial

const CONFIG_LISTEN_VALUES := [
	"apply_translation",
	"apply_rotation",
	"should_track_eye"
]

const DUCK_PATH := "res://entities/duck/duck.tscn"

const BASE_MODEL_SCRIPT_PATH := "res://entities/base_model.gd"
const VRM_MODEL_SCRIPT_PATH := "res://entities/vrm_model.gd"

const VrmLoader = preload("res://addons/vrm/vrm_loader.gd")

var model: BaseModel
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

func _ready() -> void:
	for i in CONFIG_LISTEN_VALUES:
		AM.ps.register(self, i, PubSubPayload.new({
			"args": [i],
			"callback": "_on_config_changed"
		}))
	
	var default_model_path: String = AM.cm.get_data("default_model_path")

	var result := _try_load_model(default_model_path if not default_model_path.empty() else DUCK_PATH)
	if result == null or result.is_err():
		AM.logger.error(result.unwrap_err().to_string() if result != null else "Something super broke, please check the logs")
		# If this fails, something is very wrong
		result = _try_load_model(DUCK_PATH)
		if result == null or result.is_err():
			AM.logger.error(result.unwrap_err().to_string() if result != null else "Something super broke, please check the logs")
			AM.logger.error("Failed loading the default Duck model")
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

func _physics_process(delta: float) -> void:
	
	pass

###############################################################################
# Connections                                                                 #
###############################################################################

func _on_config_changed(data, key: String) -> void:
	set(key, data)

###############################################################################
# Private functions                                                           #
###############################################################################

func _try_load_model(path: String) -> Result:
	var file := File.new()
	if not file.file_exists(path):
		return Result.err(Error.Code.VIEWER_FILE_NOT_FOUND)

	match path.get_extension().to_lower():
		"glb":
			AM.logger.info("Loading GLB %s" % path)
			
			var gltf_loader := PackedSceneGLTF.new()
			
			var m = gltf_loader.import_gltf_scene(path)
			m.set_script(load(BASE_MODEL_SCRIPT_PATH))
			# TODO check against OpenSeeFaceData, maybe this isn't necessary
			translation_adjustment = Vector3(1.0, -1.0, 1.0)
			rotation_adjustment = Vector3(-1.0, -1.0, 1.0)

			AM.logger.info("Loaded GLB!")

			return Result.ok(m)
		"vrm":
			AM.logger.info("Loading VRM %s" % path)
			
			var vrm_loader := VrmLoader.new()

			var m = vrm_loader.import_scene(path, 1, 1000)
			# TODO: this needs to be futher looked at, as it seems like a hack
			# vrm_meta needs to be read, stored in a var, and then AFTER
			# set_script it needs to be set again, otherwise it somehow 
			# isnt there when the script runs
			var vrm_meta = m.vrm_meta

			m.set_script(load(VRM_MODEL_SCRIPT_PATH))
			m.vrm_meta = vrm_meta # TODO see above todo about figuring out vrm_meta disappearing
			m.transform = m.transform.rotated(Vector3.UP, PI)
			translation_adjustment = Vector3(-1.0, -1.0, -1.0)
			rotation_adjustment = Vector3(1.0, -1.0, -1.0)

			AM.logger.info("Loaded VRM!")

			return Result.ok(m)
		"scn", "tscn":
			AM.logger.info("Loading Godot scene %s" % path)
			
			var m = load(path).instance()
			translation_adjustment = Vector3(1.0, -1.0, 1.0)
			rotation_adjustment = Vector3(-1.0, -1.0, 1.0)

			AM.logger.info("Loaded Godot scene!")

			return Result.ok(m)
		_:
			return Result.err(Error.Code.VIEWER_UNHANDLED_FILE_FORMAT)

###############################################################################
# Public functions                                                            #
###############################################################################
