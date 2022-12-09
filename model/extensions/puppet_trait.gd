class_name PuppetTrait
extends Spatial

const DEFAULT_CONFIG_VALUES := [
	"head_bone",
	"bone_translation_damping",
	"bone_rotation_damping",
	"additional_bone_damping",
	"gaze_strength",
	"additional_bones",
	"bone_transforms",
	Globals.BLEND_SHAPES
]

const SKELETON_NODE = "Skeleton"

var logger: Logger

var head_bone: String

var bone_translation_damping: float
var bone_rotation_damping: float
var additional_bone_damping: float

var gaze_strength: float

var skeleton: Skeleton
var head_bone_id: int
# Used to make the model lean with head movement
var additional_bones: Array # Bone id: int

# Used to reset to original pose
var initial_bone_poses: Dictionary # Bone id: int -> Pose: Transform

var has_custom_update := false

class BlendShapeMapping:
	var mesh: MeshInstance = null
	# NOTE: this is the property path to the blend shape, not just the name
	var blend_shape := ""
	var value: float = 0.0 setget _set_value

	func _init(p_mesh: MeshInstance, p_blend_shape: String, p_value: float) -> void:
		mesh = p_mesh
		blend_shape = p_blend_shape
		value = p_value
	
	func _set_value(p_value: float) -> void:
		value = p_value
		mesh.set(blend_shape, value)

# TODO this will break if there are blend shapes with the same name on different meshes
## Dictionary of blend shape to BlendShapeMapping
##
## @type: Dictionary<String, BlendShapeMapping>
var blend_shape_mappings := {}

#-----------------------------------------------------------------------------#
# Builtin functions                                                           #
#-----------------------------------------------------------------------------#

func _ready() -> void:
	_setup_logger()

	_pre_setup()
	_setup()
	_post_setup()

	AM.ps.publish(Globals.MODEL_LOADED, self)

func _exit_tree() -> void:
	_teardown()

## Virtual function, sets the logger name
func _setup_logger() -> void:
	logger = Logger.new("PuppetTrait")

func _pre_setup() -> void:
	AM.ps.subscribe(self, Globals.EVENT_PUBLISHED)

func _setup() -> void:
	for i in DEFAULT_CONFIG_VALUES:
		AM.ps.subscribe(self, i, "_on_event_published")

		set(i, AM.cm.get_data(i))

	skeleton = find_node(SKELETON_NODE)
	if skeleton == null:
		logger.error("No skeleton node found, bailing out early")
		return

	head_bone_id = skeleton.find_bone(head_bone)
	if head_bone_id < 0:
		logger.info("No head bone found")

	var bone_transforms: Dictionary = AM.cm.get_data(Globals.BONE_TRANSFORMS)
	for bone_name in bone_transforms.keys():
		skeleton.set_bone_pose(skeleton.find_bone(bone_name), bone_transforms[bone_name])

	for i in skeleton.get_bone_count():
		initial_bone_poses[i] = skeleton.get_bone_pose(i)
	
	for child in skeleton.get_children():
		if not child is MeshInstance:
			continue

		for i in child.mesh.get_blend_shape_count():
			var blend_shape_name: String = child.mesh.get_blend_shape_name(i)
			var blend_shape_property_path := "blend_shapes/%s" % blend_shape_name
			var value: float = child.get(blend_shape_property_path)

			blend_shape_mappings[blend_shape_name] = BlendShapeMapping.new(
				child, blend_shape_property_path, value)

func _post_setup() -> void:
	pass

func _teardown() -> void:
	pass

#-----------------------------------------------------------------------------#
# Connections                                                                 #
#-----------------------------------------------------------------------------#

func _on_event_published(payload: SignalPayload) -> void:
	match payload.signal_name:
		"additional_bones":
			if typeof(payload.data) != TYPE_DICTIONARY:
				logger.error("Unexpected value for additional_bones")
				return
			additional_bones = payload.data.values()
		"bone_transforms":
			var bone_id := skeleton.find_bone(payload.id)
			if bone_id < 0:
				logger.error("%s not found in skeleton" % payload.id)
				return

			skeleton.set_bone_pose(bone_id, payload.data)
		Globals.BLEND_SHAPES:
			if payload.id == null:
				logger.error("Expected an ID for a %s payload" % Globals.BLEND_SHAPES)
				return
			
			set_blend_shape(payload.id, payload.data)
		_:
			set(payload.signal_name, payload.data)

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

func custom_update(_interpolation_data: InterpolationData) -> void:
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

func set_blend_shape(blend_shape: String, value: float) -> void:
	blend_shape_mappings[blend_shape].value = value

func get_blend_shape(blend_shape: String) -> float:
	return blend_shape_mappings[blend_shape].value

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
		additional_transform = additional_transform.translated(tx * additional_bone_damping)
		additional_transform = additional_transform.rotated(Vector3.RIGHT, rt.x * additional_bone_damping)
		additional_transform = additional_transform.rotated(Vector3.UP, rt.y * additional_bone_damping)
		additional_transform = additional_transform.rotated(Vector3.BACK, rt.z * additional_bone_damping)

		for bone in additional_bones:
			skeleton.set_bone_pose(bone, additional_transform)
