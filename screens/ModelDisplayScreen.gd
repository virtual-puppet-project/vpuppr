class_name ModelDisplayScreen
extends Spatial

const OPEN_SEE: Resource = preload("res://utils/OpenSeeGD.tscn")

const DEFAULT_GENERIC_MODEL: Resource = preload("res://entities/basic-models/Duck.tscn")
const DEFAULT_VRM_MODEL: Resource = preload("res://entities/vrm/AliciaSolid_vrm-051.tscn")
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
export var apply_translation: bool = true
# export var translation_damp: float = 0.3
var translation_adjustment: Vector3 = Vector3.ONE
export var apply_rotation: bool = true
# export var rotation_damp: float = 0.02
var rotation_adjustment: Vector3 = Vector3.ONE

export var tracking_start_delay: float = 2.0

# OpenSeeData last updated time
var updated: float = 0.0

# Input
var can_manipulate_model: bool = false
var should_spin_model: bool = false
var should_move_model: bool = false

export var zoom_strength: float = 0.05
export var mouse_move_strength: float = 0.002

# TODO debug
var imported_model

###############################################################################
# Builtin functions                                                           #
###############################################################################

func _ready() -> void:
	if model_resource_path:
		match model_resource_path.get_extension():
			"glb":
				# TODO have to use an extra match in order to get the correct model script
				# there must be a better way
				match model_type:
					AppManager.ModelType.GENERIC:
						script_to_use = GENERIC_MODEL_SCRIPT_PATH
					AppManager.ModelType.VRM:
						script_to_use = VRM_MODEL_SCRIPT_PATH
				model = load_external_model(model_resource_path)
			"tscn":
				var model_resource = load(model_resource_path)
				model = model_resource.instance()
			_:
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
			if not model:
				model = DEFAULT_VRM_MODEL.instance()
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
	self.call_deferred("add_child", offset_timer)
	offset_timer.name = "OffsetTimer"
	offset_timer.connect("timeout", self, "_on_offset_timer_timeout")
	offset_timer.wait_time = tracking_start_delay
	offset_timer.autostart = true

func _process(_delta: float) -> void:
	if not stored_offsets:
		return

	self.open_see_data = open_see.get_open_see_data(face_id)

	if(not open_see_data or open_see_data.fit_3d_error > open_see.max_fit_3d_error):
		return
	
	if open_see_data.time > updated:
		updated = open_see_data.time
	else:
		return

	var head_translation: Vector3 = Vector3.ZERO
	var head_rotation: Vector3 = Vector3.ZERO
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
	if open_see_data:
		_save_offsets()
	else:
		push_error("OpenSeeData not found. Is OpenSeeFace running?")

###############################################################################
# Private functions                                                           #
###############################################################################

# TODO probably incorrect?
func _to_godot_quat(v: Quat) -> Quat:
	return Quat(v.x, -v.y, v.z, v.w)

func _save_offsets() -> void:
	stored_offsets.translation_offset = open_see_data.translation
	stored_offsets.rotation_offset = open_see_data.rotation
	stored_offsets.quat_offset = _to_godot_quat(open_see_data.raw_quaternion)
	var corrected_euler: Vector3 = open_see_data.raw_euler
	if corrected_euler.x < 0.0:
		corrected_euler.x = 360 + corrected_euler.x
	stored_offsets.euler_offset = corrected_euler

###############################################################################
# Public functions                                                            #
###############################################################################

func load_external_model(file_path: String) -> Spatial:
	var gltf_loader: DynamicGLTFLoader = DynamicGLTFLoader.new()
	var loaded_model: Spatial = gltf_loader.import_scene(file_path, 1, 1)

	var model_script = load(script_to_use)
	loaded_model.set_script(model_script)
	
	return loaded_model
