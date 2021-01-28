extends Spatial

const OPEN_SEE: Resource = preload("res://utils/OpenSeeGD.tscn")

onready var gltf2_util: Node = $GLTF2Util

export var vrm_model_path: String

var model
onready var model_parent: Spatial = $ModelParent

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

export var apply_translation: bool = true
export var translation_damp: float = 0.3
export var apply_rotation: bool = true
export var rotation_damp: float = 0.02

export var tracking_start_delay: float = 2.0

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
	gltf2_util.load_file(vrm_model_path)

###############################################################################
# Connections                                                                 #
###############################################################################

###############################################################################
# Private functions                                                           #
###############################################################################

###############################################################################
# Public functions                                                            #
###############################################################################


