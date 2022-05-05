class_name PuppetTrait
extends Spatial

const DEFAULT_CONFIG_VALUES := [
	"head_bone",
	"translation_damp",
	"rotation_damp",
	"additional_bone_damp",
	"gaze_strength",
	"additional_bones"
]

const SKELETON_NODE = "Skeleton"

var logger: Logger

var head_bone: String

var translation_damp: float
var rotation_damp: float
var additional_bone_damp: float

var gaze_strength: float

var skeleton: Skeleton
var head_bone_id: int
# Used to make the model lean with head movement
var additional_bones: Array # Bone id: int

# Used to reset to original pose
var initial_bone_poses: Dictionary # Bone id: int -> Pose: Transform

var has_custom_update := false

###############################################################################
# Builtin functions                                                           #
###############################################################################

func _ready() -> void:
	_setup_logger()

	# TODO this needs to change
#	AM.ps.connect("model_config_data_changed", self, "_on_model_config_changed")

	for i in DEFAULT_CONFIG_VALUES:
		set(i, AM.cm.model_config.get_data(i))

	skeleton = find_node(SKELETON_NODE)
	if skeleton == null:
		logger.error("No skeleton node found, bailing out early")
		AM.ps.broadcast_model_loaded(self)
		return

	head_bone_id = skeleton.find_bone(head_bone)
	if head_bone_id < 0:
		logger.info("No head bone found")

	for i in skeleton.get_bone_count():
		initial_bone_poses[i] = skeleton.get_bone_pose(i)

	AM.ps.broadcast_model_loaded(self)

###############################################################################
# Connections                                                                 #
###############################################################################

func _on_model_config_changed(key: String, data) -> void:
	match key:
		"head_bone":
			head_bone = data
		"translation_damp":
			translation_damp = data
		"rotation_damp":
			rotation_damp = data
		"additional_bone_damp":
			additional_bone_damp = data
		"gaze_strength":
			gaze_strength = data
		_:
			# Do nothing
			pass

###############################################################################
# Private functions                                                           #
###############################################################################

func _setup_logger() -> void:
	"""
	Virtual function, sets the logger name
	"""
	logger = Logger.new("PuppetTrait")

func _modify_blend_shape(mesh_instance: MeshInstance, blend_shape: String, value: float) -> void:
	"""
	Blend shapes should map directly back to whatever they are called on the model

	Blend shapes are generally on a scale from 0 -> 1
	"""
	mesh_instance.set(blend_shape, value)

func _get_blend_shape_weight(mesh_instance: MeshInstance, blend_shape: String) -> float:
	"""
	Blend shapes are generally on a scale from 0 -> 1
	"""
	return mesh_instance.get(blend_shape)

###############################################################################
# Public functions                                                            #
###############################################################################

func custom_update(_data: TrackingDataInterface, _interpolation_data: InterpolationData) -> void:
	logger.error("Model custom update not implemented")

func get_bone_names() -> Array:
	var r := []

	for i in skeleton.get_bone_count():
		r.append(skeleton.get_bone_name(i))

	return r

func reset_all_bone_poses() -> void:
	"""
	Resets all bones to their original pose
	"""
	for bone_id in initial_bone_poses.keys():
		skeleton.set_bone_pose(bone_id, initial_bone_poses[bone_id])

func apply_movement(translation: Vector3, rotation: Vector3) -> void:
	"""
	A head bone is always required to exist, even if the model doesn't have a head (e.g. a tank)
	"""
	if head_bone_id < 0:
		return
	
	var head_transform := Transform()
	head_transform = head_transform.translated(translation)
	head_transform = head_transform.rotated(Vector3.RIGHT, rotation.x)
	head_transform = head_transform.rotated(Vector3.UP, rotation.y)
	head_transform = head_transform.rotated(Vector3.BACK, rotation.z)
	skeleton.set_bone_pose(head_bone_id, head_transform)
	if not additional_bones.empty():
		var additional_transform = Transform()
		additional_transform = additional_transform.translated(translation * additional_bone_damp)
		additional_transform = additional_transform.rotated(Vector3.RIGHT, rotation.x * additional_bone_damp)
		additional_transform = additional_transform.rotated(Vector3.UP, rotation.y * additional_bone_damp)
		additional_transform = additional_transform.rotated(Vector3.BACK, rotation.z * additional_bone_damp)

		for bone in additional_bones:
			skeleton.set_bone_pose(bone, additional_transform)
