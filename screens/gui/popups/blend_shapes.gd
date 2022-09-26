extends BaseLayout

class BlendShapeItem extends PanelContainer:
	var blend_shape_name := ""
	var value: float = 0.0
	
	func _init(
		p_blend_shape_name: String,
		p_value: float,
		options: Dictionary
	) -> void:
		var stylebox := StyleBoxFlat.new()
		stylebox.bg_color = Color("202431")
		stylebox.content_margin_top = 5
		stylebox.content_margin_bottom = 5
		stylebox.content_margin_left = 5
		stylebox.content_margin_right = 5
		set_indexed("custom_styles/panel", stylebox)
		
		blend_shape_name = p_blend_shape_name
		value = p_value
		
		var vbox := VBoxContainer.new()
		ControlUtil.h_expand_fill(vbox)
		
		add_child(vbox)
		
		var blend_shape_label := Label.new()
		ControlUtil.h_expand_fill(blend_shape_label)
		blend_shape_label.text = "Name: %s" % blend_shape_name
		
		vbox.add_child(blend_shape_label)
		
		var value_hbox := HBoxContainer.new()
		ControlUtil.h_expand_fill(value_hbox)
		
		vbox.add_child(value_hbox)
		
		var value_label := Label.new()
		ControlUtil.h_expand_fill(value_label)
		value_label.text = "Value:"
		
		value_hbox.add_child(value_label)
		
		var value_line_edit := LineEdit.new()
		ControlUtil.h_expand_fill(value_line_edit)
		
		value_hbox.add_child(value_line_edit)
		
		var value_slider := HSlider.new()
		
		vbox.add_child(value_slider)
		
		

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
	
	for mesh_name in blend_shape_mappings.keys():
		var blend_shapes: Array = blend_shape_mappings[mesh_name]
		
		for shape in blend_shapes:
			var item := BlendShapeItem.new(shape, 0.0, {})
			
			blend_shape_list.add_child(item)
	
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
