extends BaseLayout

const BlendShapeItem: PackedScene = preload("res://screens/gui/blend-shapes/blend_shape_item.tscn")

#-----------------------------------------------------------------------------#
# Builtin functions                                                           #
#-----------------------------------------------------------------------------#

func _init() -> void:
	pass

func _setup_logger() -> void:
	logger = Logger.new("BlendShapesPopup")

func _setup() -> Result:
	var blend_shape_list: VBoxContainer = $ScrollContainer/BlendShapeList
	
	var model = get_tree().current_scene.get("model")
	if model == null:
		return Result.err(Error.Code.NULL_VALUE, "Incompatible runner, no model found")
	
	var blend_shape_mappings = model.get("blend_shape_mappings")
	if typeof(blend_shape_mappings) == TYPE_NIL:
		return Result.err(Error.Code.NULL_VALUE,
			"Incompatible runner, no blend shape mappings found")
	
	for blend_shape in blend_shape_mappings.keys():
		# TODO this is too indirect
		# PuppetTrait::BlendShapeMapping
		var mapping: Reference = blend_shape_mappings[blend_shape]
		
		var item: Control = BlendShapeItem.instance()
		item.logger = logger
		item.mesh_instance = mapping.mesh
		item.blend_shape_name = blend_shape
		item.blend_shape_value = mapping.value

		blend_shape_list.add_child(item)
		blend_shape_list.add_child(HSeparator.new())
	
	return ._setup()

#-----------------------------------------------------------------------------#
# Connections                                                                 #
#-----------------------------------------------------------------------------#

#-----------------------------------------------------------------------------#
# Private functions                                                           #
#-----------------------------------------------------------------------------#

#-----------------------------------------------------------------------------#
# Public functions                                                            #
#-----------------------------------------------------------------------------#
