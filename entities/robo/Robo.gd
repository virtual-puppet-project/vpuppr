extends BasicModel

const MOUTH_OPEN_SHAPE: String = "MouthOpen"
const BLINK_SHAPE: String = "Blink"

onready var torso_mesh_instance: MeshInstance = skeleton.get_node("Torso")
onready var eye_bone_id: int = skeleton.find_bone("eye")

var blink_threshold: float = 0.3
var gaze_strength: float = 1.0

var min_mouth_value: float = 0.0

###############################################################################
# Builtin functions                                                           #
###############################################################################

func _ready() -> void:
	has_custom_update = true

###############################################################################
# Connections                                                                 #
###############################################################################

###############################################################################
# Private functions                                                           #
###############################################################################

func _modify_blend_shape(mesh_instance: MeshInstance, blend_shape: String, value: float) -> void:
	mesh_instance.set("blend_shapes/%s" % blend_shape, value)

func _set_blend_shape(shape_name: String, shape_weight: float) -> void:
	_modify_blend_shape(torso_mesh_instance, shape_name, shape_weight)

###############################################################################
# Public functions                                                            #
###############################################################################

func custom_update(data: OpenSeeGD.OpenSeeData, interpolation_data: InterpolationData) -> void:
	# Blinking
	var eye_open_average: float = (data.left_eye_open + data.right_eye_open) / 2
	if eye_open_average >= blink_threshold:
		_set_blend_shape(BLINK_SHAPE, 1.0 - eye_open_average)
	else:
		_set_blend_shape(BLINK_SHAPE, 1.0)
	
	var left_eye_rotation: Vector3 = interpolation_data.interpolate(InterpolationData.InterpolationDataType.LEFT_EYE_ROTATION, gaze_strength)
	var right_eye_rotation: Vector3 = interpolation_data.interpolate(InterpolationData.InterpolationDataType.RIGHT_EYE_ROTATION, gaze_strength)
	var average_eye_rotation: Vector3 = (left_eye_rotation + right_eye_rotation) / 2

	var eye_transform := Transform()
	eye_transform = eye_transform.rotated(Vector3.RIGHT, average_eye_rotation.x)
	eye_transform = eye_transform.rotated(Vector3.FORWARD, average_eye_rotation.y)

	skeleton.set_bone_pose(eye_bone_id, eye_transform)

	# Mouth tracking
	_set_blend_shape(MOUTH_OPEN_SHAPE, min(max(min_mouth_value, data.features.mouth_open * 2.0), 1.0))
