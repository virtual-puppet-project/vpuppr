extends BaseLayout

const BlendShapeItem: PackedScene = preload("res://screens/gui/blend-shapes/blend_shape_item.tscn")

onready var filter_bar := $TopBar/Filter
onready var _blend_shape_list: VBoxContainer = $ScrollContainer/BlendShapeList

#-----------------------------------------------------------------------------#
# Builtin functions                                                           #
#-----------------------------------------------------------------------------#

func _init() -> void:
	pass

func _setup_logger() -> void:
	logger = Logger.new("BlendShapesPopup")

func _setup() -> Result:
	# TODO this sucks
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
		
		_blend_shape_list.add_child(item)
		_blend_shape_list.add_child(HSeparator.new())
	
	filter_bar.connect("text_changed", self, "_on_filter_changed")
	
	return ._setup()

#-----------------------------------------------------------------------------#
# Connections                                                                 #
#-----------------------------------------------------------------------------#

func _on_filter_changed(text: String) -> void:
	var should_hide_separator := false
	for child in _blend_shape_list.get_children():
		if child is Separator:
			if should_hide_separator:
				child.hide()
				should_hide_separator = false
			continue
		if text.empty():
			child.show()
			continue
		
		if child.blend_shape_name.similarity(text) > 0.3:
			child.show()
		else:
			child.hide()
			should_hide_separator = true

#-----------------------------------------------------------------------------#
# Private functions                                                           #
#-----------------------------------------------------------------------------#

#-----------------------------------------------------------------------------#
# Public functions                                                            #
#-----------------------------------------------------------------------------#
