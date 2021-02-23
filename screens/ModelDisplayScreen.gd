class_name ModelDisplayScreen
extends Spatial

const OPEN_SEE: Resource = preload("res://utils/OpenSeeGD.tscn")

const DEFAULT_GENERIC_MODEL: Resource = preload("res://entities/basic-models/Duck.tscn")
#const DEFAULT_VRM_MODEL: Resource = preload("res://entities/vrm/AliciaSolid_vrm-051.tscn")
const GENERIC_MODEL_SCRIPT_PATH: String = "res://entities/BasicModel.gd"
const VRM_MODEL_SCRIPT_PATH: String = "res://entities/vrm/VRMModel.gd"

export(AppManager.ModelType) var model_type = AppManager.ModelType.GENERIC
export var model_resource_path: String

var script_to_use: String

# Model nodes
var model
onready var model_parent: Spatial = $ModelParent

# Store transforms so we can easily reset
var model_initial_transform: Transform
var model_parent_initial_transform: Transform

var open_see: OpenSeeGD
var open_see_data: OpenSeeGD.OpenSeeData

var head_translation: Vector3 = Vector3.ZERO
var head_rotation: Vector3 = Vector3.ZERO

class StoredOffsets:
	var translation_offset: Vector3
	var rotation_offset: Vector3
	var quat_offset: Quat
	var euler_offset: Vector3
var stored_offsets: StoredOffsets

export var face_id: int = 0
export var min_confidence: float = 0.2
export var show_gaze: bool = true

# Various tracking options
export var apply_translation: bool = false
var translation_adjustment: Vector3 = Vector3.ONE
export var apply_rotation: bool = true
var rotation_adjustment: Vector3 = Vector3.ONE
export var interpolate_model: bool = true
var interpolation_rate: float = 0.1
var interpolation_data: InterpolationData = InterpolationData.new()

class InterpolationData:
	var last_updated: float
	var last_translation: Vector3
	var last_rotation: Vector3
	var target_translation: Vector3
	var target_rotation: Vector3

	func _init() -> void:
		last_updated = 0.0
		last_translation = Vector3.ZERO
		last_rotation = Vector3.ZERO
		target_translation = Vector3.ZERO
		target_rotation = Vector3.ZERO

	func update_values(
		p_last_updated: float,
		p_target_translation: Vector3,
		p_target_rotation: Vector3
	) -> void:
		last_updated = p_last_updated
		target_translation = p_target_translation
		target_rotation = p_target_rotation


export var tracking_start_delay: float = 2.0

# OpenSeeData last updated time
var updated: float = 0.0

# Input
var can_manipulate_model: bool = false
var should_spin_model: bool = false
var should_move_model: bool = false

export var zoom_strength: float = 0.05
export var mouse_move_strength: float = 0.002

###############################################################################
# Builtin functions                                                           #
###############################################################################

func _ready() -> void:
	if model_resource_path:
		match model_resource_path.get_extension():
			"glb":
				AppManager.push_log("Loading GLB file.")
				# TODO have to use an extra match in order to get the correct model script
				# there must be a better way
				match model_type:
					AppManager.ModelType.GENERIC:
						script_to_use = GENERIC_MODEL_SCRIPT_PATH
					AppManager.ModelType.VRM:
						script_to_use = VRM_MODEL_SCRIPT_PATH
				model = load_external_model(model_resource_path)
			"vrm":
				AppManager.push_log("Loading VRM file.")
				script_to_use = VRM_MODEL_SCRIPT_PATH
				model = load_external_model(model_resource_path)
			"tscn":
				AppManager.push_log("Loading TSCN file.")
				var model_resource = load(model_resource_path)
				model = model_resource.instance()
			_:
				AppManager.push_log("File extension not recognized.")
				printerr("File extension not recognized.")
	
	match model_type:
		AppManager.ModelType.GENERIC:
			if not model:
				model = DEFAULT_GENERIC_MODEL.instance()
			model.scale_object_local(Vector3(0.4, 0.4, 0.4))
			translation_adjustment = Vector3(1, -1, 1)
			rotation_adjustment = Vector3(-1, -1, 1)

			script_to_use = GENERIC_MODEL_SCRIPT_PATH
		AppManager.ModelType.VRM:
#			if not model:
#				model = DEFAULT_VRM_MODEL.instance()
			model.transform = model.transform.rotated(Vector3.UP, PI)
			translation_adjustment = Vector3(-1, -1, -1)
			rotation_adjustment = Vector3(1, -1, -1)

			script_to_use = VRM_MODEL_SCRIPT_PATH
	model_initial_transform = model.transform
	model_parent_initial_transform = model_parent.transform
	model_parent.call_deferred("add_child", model)

	self.open_see = OPEN_SEE.instance()
	self.call_deferred("add_child", open_see)

	var offset_timer: Timer = Timer.new()
	offset_timer.name = "OffsetTimer"
	offset_timer.connect("timeout", self, "_on_offset_timer_timeout")
	offset_timer.wait_time = tracking_start_delay
	offset_timer.autostart = true
	self.call_deferred("add_child", offset_timer)

	AppManager.connect("properties_applied", self, "_on_properties_applied")

func _process(_delta: float) -> void:
	if not interpolate_model:
		if not stored_offsets:
			return
	
		self.open_see_data = open_see.get_open_see_data(face_id)
	
		if(not open_see_data or open_see_data.fit_3d_error > open_see.max_fit_3d_error):
			return
		
		if open_see_data.time > updated:
			updated = open_see_data.time
		else:
			return
		
		if apply_translation:
			head_translation = (stored_offsets.translation_offset - open_see_data.translation) * model.translation_damp

		if apply_rotation:
			var corrected_euler: Vector3 = open_see_data.raw_euler
			if corrected_euler.x < 0.0:
				corrected_euler.x = 360 + corrected_euler.x
			head_rotation = (stored_offsets.euler_offset - corrected_euler) * model.rotation_damp

		if model.has_custom_update:
			model.custom_update(open_see_data)

		model.move_head(
			head_translation * translation_adjustment,
			head_rotation * rotation_adjustment
		)

func _physics_process(_delta: float) -> void:
	if interpolate_model:
		if not stored_offsets:
			return
	
		self.open_see_data = open_see.get_open_see_data(face_id)
	
		if(not open_see_data or open_see_data.fit_3d_error > open_see.max_fit_3d_error):
			return
		
		# Don't return early if we are interpolating
		if open_see_data.time > updated:
			updated = open_see_data.time
			var corrected_euler: Vector3 = open_see_data.raw_euler
			if corrected_euler.x < 0.0:
				corrected_euler.x = 360 + corrected_euler.x
			interpolation_data.update_values(
				updated,
				(stored_offsets.translation_offset - open_see_data.translation),
				(stored_offsets.euler_offset - corrected_euler)
			)

		if apply_translation:
			head_translation = lerp(
				interpolation_data.last_translation,
				interpolation_data.target_translation * model.translation_damp,
				interpolation_rate
			)
			interpolation_data.last_translation = head_translation

		if apply_rotation:
			head_rotation = lerp(
				interpolation_data.last_rotation,
				interpolation_data.target_rotation * model.rotation_damp,
				interpolation_rate
			)
			interpolation_data.last_rotation = head_rotation

		if model.has_custom_update:
			model.custom_update(open_see_data)
	
		model.move_head(
			head_translation * translation_adjustment,
			head_rotation * rotation_adjustment
		)

func _unhandled_input(event: InputEvent) -> void:
	if event.is_action_pressed("ui_accept"):
		_save_offsets()

	if event.is_action_pressed("allow_move_model"):
		can_manipulate_model = true
	elif event.is_action_released("allow_move_model"):
		can_manipulate_model = false
		should_spin_model = false
		should_move_model = false

	if can_manipulate_model:
		if event.is_action_pressed("left_click"):
			should_spin_model = true
		elif event.is_action_released("left_click"):
			should_spin_model = false
		
		# Reset model
		if event.is_action_pressed("middle_click"):
			model.transform = model_initial_transform
			model_parent.transform = model_parent_initial_transform
		
		if event.is_action_pressed("right_click"):
			should_move_model = true
		elif event.is_action_released("right_click"):
			should_move_model = false

		if event.is_action("scroll_up"):
			model_parent.translate(Vector3(0.0, 0.0, zoom_strength))
		elif event.is_action("scroll_down"):
			model_parent.translate(Vector3(0.0, 0.0, -zoom_strength))

		if(should_spin_model and event is InputEventMouseMotion):
			model.rotate_x(event.relative.y * mouse_move_strength)
			model.rotate_y(event.relative.x * mouse_move_strength)
		
		if(should_move_model and event is InputEventMouseMotion):
			model_parent.translate(Vector3(event.relative.x, -event.relative.y, 0.0) * mouse_move_strength)

###############################################################################
# Connections                                                                 #
###############################################################################

func _on_offset_timer_timeout() -> void:
	get_node("OffsetTimer").queue_free()

	stored_offsets = StoredOffsets.new()
	open_see_data = open_see.get_open_see_data(face_id)
	_save_offsets()

func _on_properties_applied(property_data: Dictionary) -> void:
	model.translation_damp = property_data["translation_damp"]
	model.rotation_damp = property_data["rotation_damp"]
	model.additional_bone_damp = property_data["additional_bone_damp"]

	self.apply_translation = property_data["apply_translation"]
	self.apply_rotation = property_data["apply_rotation"]
	self.interpolate_model = property_data["interpolate_model"]
	self.interpolation_rate = property_data["interpolation_rate"]

###############################################################################
# Private functions                                                           #
###############################################################################

# TODO probably incorrect?
func _to_godot_quat(v: Quat) -> Quat:
	return Quat(v.x, -v.y, v.z, v.w)

func _save_offsets() -> void:
	if not open_see_data:
		AppManager.push_log("No face tracking data found.")
		return
	stored_offsets.translation_offset = open_see_data.translation
	stored_offsets.rotation_offset = open_see_data.rotation
	stored_offsets.quat_offset = _to_godot_quat(open_see_data.raw_quaternion)
	var corrected_euler: Vector3 = open_see_data.raw_euler
	if corrected_euler.x < 0.0:
		corrected_euler.x = 360 + corrected_euler.x
	stored_offsets.euler_offset = corrected_euler
	AppManager.push_log("New offsets saved.")

###############################################################################
# Public functions                                                            #
###############################################################################

func load_external_model(file_path: String) -> Spatial:
	AppManager.push_log("Starting external loader.")
	# var gltf_loader: DynamicGLTFLoader = DynamicGLTFLoader.new()
	# var loaded_model: Spatial = gltf_loader.import_scene(file_path, 1, 1)

	var import_vrm: ImportVRM = ImportVRM.new()
	var loaded_model: Spatial = import_vrm.import_scene(file_path, 1, 1000)

	var model_script = load(script_to_use)
	loaded_model.set_script(model_script)
	
	AppManager.push_log("External file loaded successfully.")
	
	return loaded_model
