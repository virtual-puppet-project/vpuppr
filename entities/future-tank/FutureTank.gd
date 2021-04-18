extends BasicModel

const MAIN_CANNON_FLAP_SHAPE: String = "CannonFlap"
const SUB_CANNON_FLAP_SHAPE: String = "SubCannonFlap"
const MUSHROOM_WIGGLE_SHAPE: String = "MushroomWiggle"

onready var chassis_mesh_instance: MeshInstance = skeleton.get_node("TankBase")
onready var turret_mesh_instance: MeshInstance = skeleton.get_node("TankTurret")
onready var mushroom_mesh_instance: MeshInstance = skeleton.get_node("Mushroom")

onready var main_cannon_id: int = skeleton.find_bone("main_cannon")
onready var sub_cannon_id: int = skeleton.find_bone("sub_cannon")
onready var mushroom_id: int = skeleton.find_bone("mushroom")

var blink_threshold: float = 0.3
var gaze_strength: float = 1.0

var min_mouth_value: float = 0.0

onready var mushroom_tween: Tween = $MushroomTween
var tween_duration: float = 2.0
# Start by increasing, so this value should be false to start
var should_mushroom_wiggle_increase: bool = false
var mushroom_wiggle_amount: float = 0.05

###############################################################################
# Builtin functions                                                           #
###############################################################################

func _ready() -> void:
	has_custom_update = true

	head_bone_id = skeleton.find_bone("turret")

	mushroom_tween.connect("tween_all_completed", self, "_on_mushroom_tween_completed")
	mushroom_tween.interpolate_property(
		mushroom_mesh_instance,
		"blend_shapes/%s" % MUSHROOM_WIGGLE_SHAPE,
		1.0,
		-1.0,
		tween_duration,
		Tween.TRANS_LINEAR,
		Tween.EASE_OUT
	)
	mushroom_tween.start()

###############################################################################
# Connections                                                                 #
###############################################################################

func _on_mushroom_tween_completed() -> void:
	if should_mushroom_wiggle_increase:
		should_mushroom_wiggle_increase = false
		mushroom_tween.interpolate_property(
			mushroom_mesh_instance,
			"blend_shapes/%s" % MUSHROOM_WIGGLE_SHAPE,
			1.0,
			-1.0,
			tween_duration,
			Tween.TRANS_LINEAR,
			Tween.EASE_OUT
		)
	else:
		should_mushroom_wiggle_increase = true
		mushroom_tween.interpolate_property(
			mushroom_mesh_instance,
			"blend_shapes/%s" % MUSHROOM_WIGGLE_SHAPE,
			-1.0,
			1.0,
			tween_duration,
			Tween.TRANS_LINEAR,
			Tween.EASE_OUT
		)

	mushroom_tween.start()

###############################################################################
# Private functions                                                           #
###############################################################################

func _modify_blend_shape(mesh_instance: MeshInstance, blend_shape: String, value: float) -> void:
	mesh_instance.set("blend_shapes/%s" % blend_shape, value)

func _get_blend_shape_weight(mesh_instance: MeshInstance, blend_shape: String) -> float:
	return mesh_instance.get("blend_shapes/%s" % blend_shape)

###############################################################################
# Public functions                                                            #
###############################################################################

func custom_update(data: OpenSeeGD.OpenSeeData, interpolation_data: InterpolationData) -> void:
	# Blinking
	var eye_open_average: float = (data.left_eye_open + data.right_eye_open) / 2
	if eye_open_average >= blink_threshold:
		_modify_blend_shape(turret_mesh_instance, MAIN_CANNON_FLAP_SHAPE, 1.0 - eye_open_average)
	else:
		_modify_blend_shape(turret_mesh_instance, MAIN_CANNON_FLAP_SHAPE, 1.0)
	
	var left_eye_rotation: Vector3 = interpolation_data.interpolate(InterpolationData.InterpolationDataType.LEFT_EYE_ROTATION, gaze_strength)
	var right_eye_rotation: Vector3 = interpolation_data.interpolate(InterpolationData.InterpolationDataType.RIGHT_EYE_ROTATION, gaze_strength)
	var average_eye_rotation: Vector3 = (left_eye_rotation + right_eye_rotation) / 2

	var main_cannon_transform := Transform()
	main_cannon_transform = main_cannon_transform.rotated(Vector3.RIGHT, average_eye_rotation.x)
	main_cannon_transform = main_cannon_transform.rotated(Vector3.FORWARD, average_eye_rotation.y)

	var sub_cannon_transform := Transform()
	sub_cannon_transform = sub_cannon_transform.rotated(Vector3.RIGHT, average_eye_rotation.x)
	sub_cannon_transform = sub_cannon_transform.rotated(Vector3.FORWARD, average_eye_rotation.y)

	var mushroom_transform := Transform()
	mushroom_transform = mushroom_transform.rotated(Vector3.RIGHT, average_eye_rotation.x)
	mushroom_transform = mushroom_transform.rotated(Vector3.UP, average_eye_rotation.y)

	skeleton.set_bone_pose(main_cannon_id, main_cannon_transform)
	skeleton.set_bone_pose(sub_cannon_id, sub_cannon_transform)
	skeleton.set_bone_pose(mushroom_id, mushroom_transform)

	# Mouth tracking
	_modify_blend_shape(chassis_mesh_instance, SUB_CANNON_FLAP_SHAPE, min(max(min_mouth_value, data.features.mouth_open * 2.0), 1.0))
