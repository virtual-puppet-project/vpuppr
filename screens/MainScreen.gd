extends Spatial

enum ModelType { VRM, GLB }

const DEV_UI: Resource = preload("res://utils/gui/DevUI.tscn")

const GLB_CONTAINER: String = "res://utils/OpenSee3DModelMapBasic.tscn"
const VRM_CONTAINER: String = "res://utils/OpenSeeVRMModelMap.tscn"

var debug: bool = true

export(ModelType) var current_model_type = ModelType.GLB

###############################################################################
# Builtin functions                                                           #
###############################################################################

func _ready() -> void:
	get_viewport().transparent_bg = true
	OS.window_per_pixel_transparency_enabled = true
	
	if OS.has_feature("standalone"):
		debug = false
	if not OS.is_debug_build():
		debug = false
	if debug:
		var dev_ui: Control = DEV_UI.instance()
		self.add_child(dev_ui)
	
	AppManager.connect("file_to_load_changed", self, "_on_file_to_load_changed")
	
	var container
	match current_model_type:
		ModelType.GLB:
			container = load(GLB_CONTAINER).instance()
		ModelType.VRM:
			container = load(VRM_CONTAINER).instance()
	container.name = "ModelContainer"
	add_child(container)

func _input(event: InputEvent) -> void:
	if(event.is_action_pressed("ui_cancel") and debug):
		get_tree().quit()

###############################################################################
# Connections                                                                 #
###############################################################################

func _on_file_to_load_changed(file_path: String, file_type: String) -> void:
	get_node("ModelContainer").free()
	var container
	match file_type:
		"basic":
			container = load(GLB_CONTAINER).instance()
		"vrm":
			container = load(VRM_CONTAINER).instance()
	container.name = "ModelContainer"
	container.model_resource_path = file_path
	add_child(container)

###############################################################################
# Private functions                                                           #
###############################################################################

###############################################################################
# Public functions                                                            #
###############################################################################


