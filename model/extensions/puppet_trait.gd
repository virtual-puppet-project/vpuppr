class_name PuppetTrait
extends Spatial

const DEFAULT_CONFIG_VALUES := [
	"head_bone",
	"translation_damp",
	"rotation_damp",
	"additional_bone_damp",
	"gaze_strength",
	"additional_bones",
	"bone_transforms"
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

#-----------------------------------------------------------------------------#
# Builtin functions                                                           #
#-----------------------------------------------------------------------------#

func _ready() -> void:
	_setup_logger()

	_pre_setup()
	_setup()
	_post_setup()

	AM.ps.publish(GlobalConstants.MODEL_LOADED, self)

func _exit_tree() -> void:
	_teardown()

## Virtual function, sets the logger name
func _setup_logger() -> void:
	logger = Logger.new("PuppetTrait")

func _pre_setup() -> void:
	AM.ps.subscribe(self, GlobalConstants.EVENT_PUBLISHED)

func _setup() -> void:
	for i in DEFAULT_CONFIG_VALUES:
		AM.ps.subscribe(self, i, {
			"args": [i],
			"callback": "_on_config_changed"
		})

		set(i, AM.cm.get_data(i))

	skeleton = find_node(SKELETON_NODE)
	if skeleton == null:
		logger.error("No skeleton node found, bailing out early")
		return

	head_bone_id = skeleton.find_bone(head_bone)
	if head_bone_id < 0:
		logger.info("No head bone found")

	var bone_transforms: Dictionary = AM.cm.get_data(GlobalConstants.BONE_TRANSFORMS)
	for bone_name in bone_transforms.keys():
		skeleton.set_bone_pose(skeleton.find_bone(bone_name), bone_transforms[bone_name])

	for i in skeleton.get_bone_count():
		initial_bone_poses[i] = skeleton.get_bone_pose(i)

func _post_setup() -> void:
	pass

func _teardown() -> void:
	pass

#-----------------------------------------------------------------------------#
# Connections                                                                 #
#-----------------------------------------------------------------------------#

func _on_event_published(payload: SignalPayload) -> void:
	match payload.signal_name:
		_:
			pass

func _on_config_changed(value, signal_name: String) -> void:
	match signal_name:
		"head_bone":
			head_bone = value
		"translation_damp":
			translation_damp = value
		"rotation_damp":
			rotation_damp = value
		"additional_bone_damp":
			additional_bone_damp = value
		"gaze_strength":
			gaze_strength = value
		"additional_bones":
			if typeof(value.data) != TYPE_DICTIONARY:
				logger.error("Unexpected value for additional_bones")
				return
			additional_bones = value.data.values()
		"bone_transforms":
			var bone_id := skeleton.find_bone(value.id)
			if bone_id < 0:
				logger.error("%s not found in skeleton" % value.id)
				return

			skeleton.set_bone_pose(bone_id, value.data[value.id])
		_:
			# Do nothing
			pass

#-----------------------------------------------------------------------------#
# Private functions                                                           #
#-----------------------------------------------------------------------------#

## Blend shapes should map directly back to whatever they are called on the model
##
## Blend shapes are generally on a scale from 0 - 1
##
## @param: mesh_instance: MeshInstance - The mesh instance to access the blend shape on
## @param: blend_shape: String - The blend shape name
## @param: value: float - The blend shape weight
func _modify_blend_shape(mesh_instance: MeshInstance, blend_shape: String, value: float) -> void:
	mesh_instance.set(blend_shape, value)

## Gets the weight for a blend shape
##
## Blend shapes are generally on a scale from 0 - 1
##
## @param: mesh_instance: MeshInstance - The mesh instance to access the blend shape on
## @param: blend_shape: String - The blend shape name
##
## @return: float - The blend shape weight
func _get_blend_shape_weight(mesh_instance: MeshInstance, blend_shape: String) -> float:
	return mesh_instance.get(blend_shape)

#-----------------------------------------------------------------------------#
# Public functions                                                            #
#-----------------------------------------------------------------------------#

func custom_update(_data, _interpolation_data: InterpolationData) -> void:
	logger.error("Model custom update not implemented")

func get_bone_names() -> Array:
	var r := []

	for i in skeleton.get_bone_count():
		r.append(skeleton.get_bone_name(i))

	return r

## Resets all bones to their original pose
func reset_all_bone_poses() -> void:
	for bone_id in initial_bone_poses.keys():
		skeleton.set_bone_pose(bone_id, initial_bone_poses[bone_id])

# TODO looseness values should be pre-applied
## Applies movement to a model
##
## A head bone is always required to exist, even if the model doesn't have a head (e.g. a tank)
##
## @param: tx: Vector3 - The translation to apply
## @param: rt: Vector3 - The rotation to apply
func apply_movement(tx: Vector3, rt: Vector3) -> void:
	if head_bone_id < 0:
		return
	
	var head_transform := Transform()
	head_transform = head_transform.translated(tx)
	head_transform = head_transform.rotated(Vector3.RIGHT, rt.x)
	head_transform = head_transform.rotated(Vector3.UP, rt.y)
	head_transform = head_transform.rotated(Vector3.BACK, rt.z)
	skeleton.set_bone_pose(head_bone_id, head_transform)
	if not additional_bones.empty():
		var additional_transform = Transform()
		additional_transform = additional_transform.translated(tx * additional_bone_damp)
		additional_transform = additional_transform.rotated(Vector3.RIGHT, rt.x * additional_bone_damp)
		additional_transform = additional_transform.rotated(Vector3.UP, rt.y * additional_bone_damp)
		additional_transform = additional_transform.rotated(Vector3.BACK, rt.z * additional_bone_damp)

		for bone in additional_bones:
			skeleton.set_bone_pose(bone, additional_transform)
