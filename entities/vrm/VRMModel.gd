extends BasicModel

const MTOON_SHADER_COMPAT: Resource = preload("res://entities/vrm/MToonShader.tres")

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
	rotation_damp = 0.01
	additional_bone_damp = 0.6

	additional_bones_to_pose_names.append(NECK_BONE)
	additional_bones_to_pose_names.append(SPINE_BONE)

	scan_mapped_bones()
	
	# _apply_shader_to_all_meshes(self)

###############################################################################
# Connections                                                                 #
###############################################################################

###############################################################################
# Private functions                                                           #
###############################################################################

# TODO unused now that we are using godot-vrm
func _apply_shader_to_all_meshes(starting_node: Node) -> void:
	for c in starting_node.get_children():
		if c is MeshInstance:
			for i in range(c.mesh.get_surface_count()):
				var toon_shader = MTOON_SHADER_COMPAT.duplicate()
				toon_shader.set_shader_param("_MainTex", c.get_active_material(i).albedo_texture)
				c.set_surface_material(i, toon_shader)
		_apply_shader_to_all_meshes(c)

###############################################################################
# Public functions                                                            #
###############################################################################
