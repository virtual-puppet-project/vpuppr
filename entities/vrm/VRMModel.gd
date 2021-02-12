extends BasicModel

# VRM guarantees neck and spine to exist
const NECK_BONE = "neck"
const SPINE_BONE = "spine"

onready var neck_bone_id: int = skeleton.find_bone(NECK_BONE)
onready var spine_bone_id: int = skeleton.find_bone(SPINE_BONE)

###############################################################################
# Builtin functions                                                           #
###############################################################################

func _ready() -> void:
	translation_damp = 0.1
	rotation_damp = 0.02
	additional_bone_damp = 0.6

	additional_bones_to_pose_names.append(NECK_BONE)
	additional_bones_to_pose_names.append(SPINE_BONE)

	scan_mapped_bones()

###############################################################################
# Connections                                                                 #
###############################################################################

###############################################################################
# Private functions                                                           #
###############################################################################

###############################################################################
# Public functions                                                            #
###############################################################################
