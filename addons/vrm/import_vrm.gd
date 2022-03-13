tool
extends EditorSceneImporter

func _get_extensions():
	return ["vrm"]

func _get_import_flags():
	return EditorSceneImporter.IMPORT_SCENE

func _import_animation(path: String, flags: int, bake_fps: int) -> Animation:
	return Animation.new()

func _import_scene(path: String, flags: int, bake_fps: int):
	var vrm_loader = load("res://addons/vrm/vrm_loader.gd").new()
	
	var root_node = vrm_loader.import_scene(path, flags, bake_fps, true)

	if typeof(root_node) == TYPE_INT:
		return root_node # Error code
	else:
		# Remove references
		var packed_scene: PackedScene = PackedScene.new()
		packed_scene.pack(root_node)
		return packed_scene.instance(PackedScene.GEN_EDIT_STATE_INSTANCE)
