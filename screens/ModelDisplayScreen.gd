class_name ModelDisplayScreen
extends Spatial

const OPEN_SEE: Resource = preload("res://utils/OpenSeeGD.tscn")

const DEFAULT_GENERIC_MODEL_PATH: String = "res://entities/basic-models/Duck.tscn"
const GENERIC_MODEL_SCRIPT_PATH: String = "res://entities/BasicModel.gd"
const VRM_MODEL_SCRIPT_PATH: String = "res://entities/vrm/VRMModel.gd"
const VrmLoader: Resource = preload("res://addons/vrm/vrm_loader.gd")

export var model_resource_path: String

# Model nodes
var model
var model_skeleton: Skeleton
onready var model_parent: Spatial = $ModelParent
onready var props: Spatial = $Props

# Store transforms so we can easily reset
var model_initial_transform: Transform
var model_parent_initial_transform: Transform

# OpenSee
var open_see_data
export var face_id: int = 0
export var min_confidence: float = 0.2
export var show_gaze: bool = true

# OpenSeeData last updated time
var updated: float = 0.0

# Actual translation and rotation vectors used for manipulating the model
var head_translation: Vector3 = Vector3.ZERO
var head_rotation: Vector3 = Vector3.ZERO

var is_tracking: bool = false

class StoredOffsets:
	var translation_offset: Vector3 = Vector3.ZERO
	var rotation_offset: Vector3 = Vector3.ZERO
	var quat_offset: Quat = Quat()
	var euler_offset: Vector3 = Vector3.ZERO
	var left_eye_gaze_offset: Vector3 = Vector3.ZERO
	var right_eye_gaze_offset: Vector3 = Vector3.ZERO
var stored_offsets: StoredOffsets = null

###
# Various tracking options
###
export var apply_translation: bool = false
var translation_adjustment: Vector3 = Vector3.ONE
export var apply_rotation: bool = true
var rotation_adjustment: Vector3 = Vector3.ONE
export var interpolate_model: bool = true # TODO may or may not be working correctly?
# var last_interpolation_rate: float # Used for toggling interpolate model on/off
# var interpolation_rate: float = 0.1 setget _set_interpolation_rate
var interpolation_data: InterpolationData = InterpolationData.new()
var should_track_eye: bool = true

export var tracking_start_delay: float = 3.0

###
# Input
###
var can_manipulate_model: bool = false
var should_spin_model: bool = false
var should_move_model: bool = false

export var zoom_strength: float = 0.05
export var mouse_move_strength: float = 0.002

###############################################################################
# Builtin functions                                                           #
###############################################################################

func _ready() -> void:
	for i in ["apply_translation", "apply_rotation", "should_track_eye"]:
		AppManager.sb.connect(i, self, "_on_%s" % i)
		set(i, AppManager.cm.current_model_config.get(i))

	if model_resource_path:
		_try_load_model(model_resource_path)

	# Load in generic model if nothing is loaded
	if not model:
		AppManager.logger.info("Loading Default Model.")
		_try_load_model(DEFAULT_GENERIC_MODEL_PATH)

	model_parent.call_deferred("add_child", model)
	
	yield(model, "ready")

	# Set model initial values from config
	model_initial_transform = AppManager.cm.current_model_config.model_transform
	model_parent_initial_transform = AppManager.cm.current_model_config.model_parent_transform
	model.transform = model_initial_transform
	model_parent.transform = model_parent_initial_transform

	for bone_index in model.skeleton.get_bone_count():
		var bone_name: String = model.skeleton.get_bone_name(bone_index)
		# Courtesy null check
		if not AppManager.cm.current_model_config.bone_transforms.has(bone_name):
			continue
		var bone_transform: Transform = AppManager.cm.current_model_config.bone_transforms[bone_name]

		model.skeleton.set_bone_pose(bone_index, bone_transform)
	
	# TODO consequence of async signal system, this seems wrong
	is_tracking = OpenSeeGd.is_tracking

func _physics_process(_delta: float) -> void:
	# Not tracking, so nothing to process
	if not is_tracking:
		return

	# Get the latest tracking data, and return early if there is none or not accurate enough
	open_see_data = OpenSeeGd.get_open_see_data(face_id)
	if(not open_see_data or open_see_data.fit_3d_error > OpenSeeGd.max_fit_3d_error):
		return

	if not stored_offsets:
		_save_offsets()
	
	# Don't return early if we are interpolating
	if open_see_data.time > updated:
		updated = open_see_data.time
		var corrected_euler: Vector3 = open_see_data.raw_euler
		if corrected_euler.x < 0.0:
			corrected_euler.x = 360 + corrected_euler.x
		interpolation_data.update_values(
			updated,
			stored_offsets.translation_offset - open_see_data.translation,
			stored_offsets.euler_offset - corrected_euler,
			stored_offsets.left_eye_gaze_offset - open_see_data.left_gaze.get_euler() if should_track_eye else Vector3.ZERO,
			stored_offsets.right_eye_gaze_offset - open_see_data.right_gaze.get_euler() if should_track_eye else Vector3.ZERO,
			open_see_data.left_eye_open,
			open_see_data.right_eye_open,
			open_see_data.features.mouth_open,
			open_see_data.features.mouth_wide
		)

	if apply_translation:
		head_translation = interpolation_data.interpolate(InterpolationData.InterpolationDataType.TRANSLATION, model.translation_damp)

	if apply_rotation:
		head_rotation = interpolation_data.interpolate(InterpolationData.InterpolationDataType.ROTATION, model.rotation_damp)

	if model.has_custom_update:
		model.custom_update(open_see_data, interpolation_data)

	model.move_head(
		head_translation * translation_adjustment,
		head_rotation * rotation_adjustment
	)

func _unhandled_input(event: InputEvent) -> void:
	if event.is_action_pressed("ui_accept"):
		_save_offsets()

	elif event.is_action_pressed("allow_move_model"):
		can_manipulate_model = true
	elif event.is_action_released("allow_move_model"):
		can_manipulate_model = false
		should_spin_model = false
		should_move_model = false

	elif can_manipulate_model:
		if event.is_action_pressed("left_click"):
			should_spin_model = true
		elif event.is_action_released("left_click"):
			should_spin_model = false
		
		# Reset model
		elif event.is_action_pressed("middle_click"):
			model.transform = model_initial_transform
			model_parent.transform = model_parent_initial_transform
		
		elif event.is_action_pressed("right_click"):
			should_move_model = true
		elif event.is_action_released("right_click"):
			should_move_model = false

		elif event.is_action("scroll_up"):
			model_parent.translate(Vector3(0.0, 0.0, zoom_strength))
		elif event.is_action("scroll_down"):
			model_parent.translate(Vector3(0.0, 0.0, -zoom_strength))

		elif(should_spin_model and event is InputEventMouseMotion):
			model.rotate_x(event.relative.y * mouse_move_strength)
			model.rotate_y(event.relative.x * mouse_move_strength)
		
		elif(should_move_model and event is InputEventMouseMotion):
			model_parent.translate(Vector3(event.relative.x, -event.relative.y, 0.0) * mouse_move_strength)

###############################################################################
# Connections                                                                 #
###############################################################################

func _on_apply_translation(value: bool) -> void:
	apply_translation = value

func _on_apply_rotation(value: bool) -> void:
	apply_rotation = value

func _on_should_track_eye(value: bool) -> void:
	should_track_eye = value

###############################################################################
# Private functions                                                           #
###############################################################################

func _try_load_model(file_path):
	var dir := Directory.new()
	if not dir.file_exists(file_path):
		AppManager.logger.error("File path not found: %s" % file_path)
		AppManager.logger.notify("File path not found: %s" % file_path)
		return

	match file_path.get_extension():
		"glb":
			AppManager.logger.info("Loading GLB file.")
			var gltf_loader := PackedSceneGLTF.new()
			model = gltf_loader.import_gltf_scene(file_path)
			model.set_script(load(GENERIC_MODEL_SCRIPT_PATH))
			model.scale_object_local(Vector3(0.4, 0.4, 0.4))
			translation_adjustment = Vector3(1, -1, 1)
			rotation_adjustment = Vector3(-1, -1, 1)
			AppManager.logger.info("GLB file loaded successfully.")
		"vrm":
			AppManager.logger.info("Loading VRM file.")
			var vrm_loader = VrmLoader.new()
			# TODO: this needs to be futher looked at, as it seems like a hack
			# vrm_meta needs to be read, stored in a var, and then AFTER
			# set_script it needs to be set again, otherwise it somehow 
			# isnt there when the script runs
			var vrm_meta
			model = vrm_loader.import_scene(file_path, 1, 1000)
			vrm_meta = model.vrm_meta
			model.set_script(load(VRM_MODEL_SCRIPT_PATH))
			model.vrm_meta = vrm_meta
			model.transform = model.transform.rotated(Vector3.UP, PI)
			AppManager.cm.current_model_config.model_transform = model.transform
			translation_adjustment = Vector3(-1, -1, -1)
			rotation_adjustment = Vector3(1, -1, -1)
			# Grab vrm mappings
			# model.vrm_mappings = AppManager.vrm_mappings
			# AppManager.vrm_mappings.dirty = false
			AppManager.logger.info("VRM file loaded successfully.")
		"tscn", "scn":
			AppManager.logger.info("Loading PackedScene file.")
			var model_resource = load(file_path)
			model = model_resource.instance()
			# TODO might not want this for tscn
			model.scale_object_local(Vector3(0.4, 0.4, 0.4))
			translation_adjustment = Vector3(1, -1, 1)
			rotation_adjustment = Vector3(-1, -1, 1)
			AppManager.logger.info("PackedScene file loaded successfully.")
		_:
			AppManager.logger.notify("File extension not recognized. %s" % file_path)
			printerr("File extension not recognized. %s" % file_path)

# TODO probably incorrect?
static func _to_godot_quat(v: Quat) -> Quat:
	return Quat(v.x, -v.y, v.z, v.w)

func _save_offsets() -> void:
	if not open_see_data:
		AppManager.logger.info("No face tracking data found.")
		return
	stored_offsets = StoredOffsets.new()
	stored_offsets.translation_offset = open_see_data.translation
	stored_offsets.rotation_offset = open_see_data.rotation
	stored_offsets.quat_offset = _to_godot_quat(open_see_data.raw_quaternion)
	var corrected_euler: Vector3 = open_see_data.raw_euler
	if corrected_euler.x < 0.0:
		corrected_euler.x = 360 + corrected_euler.x
	stored_offsets.euler_offset = corrected_euler
	stored_offsets.left_eye_gaze_offset = open_see_data.left_gaze.get_euler()
	stored_offsets.right_eye_gaze_offset = open_see_data.right_gaze.get_euler()
	AppManager.logger.info("New offsets saved.")

static func _find_bone_chain(skeleton: Skeleton, root_bone: int, tip_bone: int) -> Array:
	var result: Array = []

	result.append(tip_bone)

	# Work our way up from the tip bone since each bone only has 1 bone parent but
	# potentially more than 1 bone child
	var bone_parent: int = skeleton.get_bone_parent(tip_bone)
	
	# We found the entire chain
	if bone_parent == root_bone:
		result.append(bone_parent)
	# Shouldn't happen but who knows
	elif bone_parent == -1:
		AppManager.logger.info("Tip bone %s is apparently has no parent bone. Unable to find IK chain." % str(tip_bone))
	# Recursively find the rest of the chain
	else:
		result.append_array(_find_bone_chain(skeleton, root_bone, bone_parent))

	return result

# func _set_interpolation_rate(value: float) -> void:
# 	interpolation_rate = value
# 	interpolation_data.rate = value

###############################################################################
# Public functions                                                            #
###############################################################################

func tracking_started() -> void:
	is_tracking = true

func tracking_stopped() -> void:
	is_tracking = false
	stored_offsets = null
