class_name ModelDisplayScreen
extends Spatial

const OPEN_SEE: Resource = preload("res://utils/OpenSeeGD.tscn")
const IFACIAL: Resource = preload("res://utils/iFacialGD.tscn")
const DEFAULT_GENERIC_MODEL: Resource = preload("res://entities/basic-models/Duck.tscn")
const GENERIC_MODEL_SCRIPT_PATH: String = "res://entities/BasicModel.gd"
const VRM_MODEL_SCRIPT_PATH: String = "res://entities/vrm/VRMModel.gd"
const VrmLoader: Resource = preload("res://addons/vrm/vrm_loader.gd")

export var model_resource_path: String

var script_to_use: String

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

#iFM
var ifm
var if_data
var if_features = iFacialGD.ifm.features
var if_data_map = {}

# OpenSeeData last updated time
var updated: float = 0.0

# Actual translation and rotation vectors used for manipulating the model
var head_translation: Vector3 = Vector3.ZERO
var head_rotation: Vector3 = Vector3.ZERO

class StoredOffsets:
	var translation_offset: Vector3 = Vector3.ZERO
	var rotation_offset: Vector3 = Vector3.ZERO
	var quat_offset: Quat = Quat()
	var euler_offset: Vector3 = Vector3.ZERO
	var left_eye_gaze_offset: Vector3 = Vector3.ZERO
	var right_eye_gaze_offset: Vector3 = Vector3.ZERO
var stored_offsets: StoredOffsets = StoredOffsets.new()

###
# Various tracking options
###
export var apply_translation: bool = false
var translation_adjustment: Vector3 = Vector3.ONE
export var apply_rotation: bool = true
var rotation_adjustment: Vector3 = Vector3.ONE
export var interpolate_model: bool = true # TODO may or may not be working correctly?
var last_interpolation_rate: float # Used for toggling interpolate model on/off
var interpolation_rate: float = 0.1 setget _set_interpolation_rate
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
	for i in ["apply_translation", "apply_rotation", "interpolate_model", "interpolation_rate", "should_track_eye"]:
		AppManager.sb.connect(i, self, "_on_%s" % i)
		set(i, AppManager.cm.current_model_config.get(i))

	if model_resource_path:
		match model_resource_path.get_extension():
			"glb":
				AppManager.log_message("Loading GLB file.")
				script_to_use = GENERIC_MODEL_SCRIPT_PATH
				model = load_external_model(model_resource_path)
				model.scale_object_local(Vector3(0.4, 0.4, 0.4))
				translation_adjustment = Vector3(1, -1, 1)
				rotation_adjustment = Vector3(-1, -1, 1)
			"vrm":
				AppManager.log_message("Loading VRM file.")
				script_to_use = VRM_MODEL_SCRIPT_PATH
				model = load_external_model(model_resource_path)
				model.transform = model.transform.rotated(Vector3.UP, PI)
				AppManager.cm.current_model_config.model_transform = model.transform
				translation_adjustment = Vector3(-1, -1, -1)
				rotation_adjustment = Vector3(1, 1, 1)
				
				# Grab vrm mappings
				model.vrm_mappings = AppManager.vrm_mappings
				# AppManager.vrm_mappings.dirty = false
			"tscn":
				AppManager.log_message("Loading TSCN file.")
				var model_resource = load(model_resource_path)
				model = model_resource.instance()
				# TODO might not want this for tscn
				model.scale_object_local(Vector3(0.4, 0.4, 0.4))
				translation_adjustment = Vector3(1, -1, 1)
				rotation_adjustment = Vector3(-1, -1, 1)
				# TODO i dont think this is used for tscn?
				script_to_use = GENERIC_MODEL_SCRIPT_PATH
			_:
				AppManager.log_message("File extension not recognized. %s" % model_resource_path)
				printerr("File extension not recognized. %s" % model_resource_path)
	
	# Load in generic model if nothing is loaded
	if not model:
		model = DEFAULT_GENERIC_MODEL.instance()
		model.scale_object_local(Vector3(0.4, 0.4, 0.4))
		translation_adjustment = Vector3(1, -1, 1)
		rotation_adjustment = Vector3(-1, -1, 1)
		# TODO i dont think this is used for tscn?
		script_to_use = GENERIC_MODEL_SCRIPT_PATH

	model_parent.call_deferred("add_child", model)
	
	# Wait until the model is loaded else we get IK errors
	yield(model, "ready")

	model_initial_transform = AppManager.cm.current_model_config.model_transform
	model_parent_initial_transform = AppManager.cm.current_model_config.model_parent_transform
	model.transform = model_initial_transform
	model_parent.transform = model_parent_initial_transform

func _physics_process(_delta: float) -> void:
	if not stored_offsets:
		return
	self.open_see_data = OpenSeeGd.get_open_see_data(face_id)
	
	self.if_data = iFacialGD.get_if_data()
	
	#rotation_degrees = Vector3(ifm.head[0],ifm.head[1],ifm.head[2])
	
	if (iFacialGD.is_listening):
		if_data_map.head_data = Vector3(if_features.head[0],if_features.head[1],if_features.head[2])
		if_data_map.head_transform = Vector3(if_features.head[3],if_features.head[4],if_features.head[5])
		
		var corrected_euler: Vector3 = if_data_map.head_data
		#if corrected_euler.x < 0.0:
		#	corrected_euler.x = 360 + corrected_euler.x
		
		interpolation_data.update_values(
			updated,
			stored_offsets.translation_offset - if_data.translation,
			stored_offsets.euler_offset - corrected_euler,
			(stored_offsets.left_eye_gaze_offset - Vector3(if_features.leftEye[0],if_features.leftEye[1],if_features.leftEye[2])) *
					float(should_track_eye),
			(stored_offsets.right_eye_gaze_offset - Vector3(if_features.rightEye[0],if_features.rightEye[1],if_features.rightEye[2])) *
					float(should_track_eye)
	)
		if_data = iFacialGD.ifm
	
	elif(not open_see_data or open_see_data.fit_3d_error > OpenSeeGd.max_fit_3d_error):
		return
	elif open_see_data.time > updated:
	# Don't return early if we are interpolating
		updated = open_see_data.time
		var corrected_euler: Vector3 = open_see_data.raw_euler
		if corrected_euler.x < 0.0:
			corrected_euler.x = 360 + corrected_euler.x
		interpolation_data.update_values(
			updated,
			stored_offsets.translation_offset - open_see_data.translation,
			stored_offsets.euler_offset - corrected_euler,
			(stored_offsets.left_eye_gaze_offset - open_see_data.left_gaze.get_euler()) *
					float(should_track_eye),
			(stored_offsets.right_eye_gaze_offset - open_see_data.right_gaze.get_euler()) *
					float(should_track_eye)
	)
		

	if apply_translation:
		head_rotation = interpolation_data.interpolate(InterpolationData.InterpolationDataType.ROTATION, model.rotation_damp)

	if apply_rotation:
		head_rotation = interpolation_data.interpolate(InterpolationData.InterpolationDataType.ROTATION, model.rotation_damp)

	if model.has_custom_update:
		if(open_see_data):
			model.custom_update(open_see_data, interpolation_data)
		elif(if_data):
			model.custom_update(if_data, interpolation_data)

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

func _on_offset_timer_timeout() -> void:
	get_node("OffsetTimer").queue_free()
	
	if open_see_data:
		open_see_data = OpenSeeGd.get_open_see_data(face_id)
		_save_offsets()
	elif if_data:
		#if_data = iFacialGD.get_if_data()
		_save_offsets()

func _on_apply_translation(value: bool) -> void:
	apply_translation = value

func _on_apply_rotation(value: bool) -> void:
	apply_rotation = value

func _on_interpolate_model(value: bool) -> void:
	interpolate_model = value
	if value:
		_set_interpolation_rate(last_interpolation_rate)
	else:
		last_interpolation_rate = interpolation_rate
		_set_interpolation_rate(1.0)

func _on_interpolation_rate(value: float) -> void:
	last_interpolation_rate = value
	_set_interpolation_rate(value)

func _on_should_track_eye(value: bool) -> void:
	should_track_eye = value

###############################################################################
# Private functions                                                           #
###############################################################################

# TODO probably incorrect?
static func _to_godot_quat(v: Quat) -> Quat:
	return Quat(v.x, -v.y, v.z, v.w)

func _save_offsets() -> void:
	if if_data: #new correction algorithm since iFM already outputs raw euler data
		stored_offsets.translation_offset = if_data.translation
		stored_offsets.rotation_offset = if_data.rotation
		stored_offsets.quat_offset = _to_godot_quat(if_data.raw_quaternion)
		stored_offsets.euler_offset = if_data_map.head_data
		stored_offsets.left_eye_gaze_offset = Vector3(if_features.leftEye[0],if_features.leftEye[1],if_features.leftEye[2])
		stored_offsets.right_eye_gaze_offset = Vector3(if_features.rightEye[0],if_features.rightEye[1],if_features.rightEye[2])
		AppManager.log_message("New offsets saved.")
		
	elif open_see_data:
		stored_offsets.translation_offset = open_see_data.translation
		stored_offsets.rotation_offset = open_see_data.rotation
		stored_offsets.quat_offset = _to_godot_quat(open_see_data.raw_quaternion)
		var corrected_euler: Vector3 = open_see_data.raw_euler
		if corrected_euler.x < 0.0:
			corrected_euler.x = 360 + corrected_euler.x
		stored_offsets.euler_offset = corrected_euler
		stored_offsets.left_eye_gaze_offset = open_see_data.left_gaze.get_euler()
		stored_offsets.right_eye_gaze_offset = open_see_data.right_gaze.get_euler()
		AppManager.log_message("New offsets saved.")

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
		AppManager.log_message("Tip bone %s is apparently has no parent bone. Unable to find IK chain." % str(tip_bone))
	# Recursively find the rest of the chain
	else:
		result.append_array(_find_bone_chain(skeleton, root_bone, bone_parent))

	return result

func _set_interpolation_rate(value: float) -> void:
	interpolation_rate = value
	interpolation_data.rate = value

###############################################################################
# Public functions                                                            #
###############################################################################

func load_external_model(file_path: String) -> Spatial:
	AppManager.log_message("Starting external loader.")
	var loaded_model: Spatial
	var vrm_meta: Dictionary
	
	match file_path.get_extension():
		"glb":
			var gltf := PackedSceneGLTF.new()
			loaded_model = gltf.import_gltf_scene(file_path)
		"vrm":
			var vrm_loader = VrmLoader.new()
			loaded_model = vrm_loader.import_scene(file_path, 1, 1000)
			vrm_meta = loaded_model.vrm_meta

	var model_script = load(script_to_use)
	loaded_model.set_script(model_script)

	if vrm_meta:
		loaded_model.vrm_meta = vrm_meta
	
	AppManager.log_message("External file loaded successfully.")
	
	return loaded_model

func tracking_started() -> void:
	if not open_see_data:
		var offset_timer: Timer = Timer.new()
		offset_timer.name = "OffsetTimer"
		offset_timer.connect("timeout", self, "_on_offset_timer_timeout")
		offset_timer.wait_time = tracking_start_delay
		offset_timer.autostart = true
		self.call_deferred("add_child", offset_timer)
