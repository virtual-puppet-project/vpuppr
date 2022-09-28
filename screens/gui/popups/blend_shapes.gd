extends BaseLayout

class BlendShapeItem extends VBoxContainer:
	var mesh_instance: MeshInstance
	var blend_shape_name := ""
	var value: float = 0.0
	
	var _value_line_edit: LineEdit
	var _value_slider: HSlider
	
	func _init(
		p_mesh_instance: MeshInstance,
		p_blend_shape_name: String,
		p_value: float
	) -> void:
		AM.ps.create_signal(Globals.BLEND_SHAPES)
		AM.ps.subscribe(self, Globals.BLEND_SHAPES, "_on_event_published")
		
		mesh_instance = p_mesh_instance
		blend_shape_name = p_blend_shape_name
		value = p_value

		ControlUtil.h_expand_fill(self)
		
		var blend_shape_label := Label.new()
		ControlUtil.h_expand_fill(blend_shape_label)
		blend_shape_label.text = "Name: %s" % blend_shape_name
		
		add_child(blend_shape_label)
		
		var value_hbox := HBoxContainer.new()
		ControlUtil.h_expand_fill(value_hbox)
		
		add_child(value_hbox)
		
		var value_label := Label.new()
		ControlUtil.h_expand_fill(value_label)
		value_label.text = "Value:"
		
		value_hbox.add_child(value_label)
		
		_value_line_edit = LineEdit.new()
		ControlUtil.h_expand_fill(_value_line_edit)
		_value_line_edit.text = str(value)
		_value_line_edit.connect("text_changed", self, "_on_line_edit_text_changed")
		
		value_hbox.add_child(_value_line_edit)
		
		_value_slider = HSlider.new()
		ControlUtil.h_expand_fill(_value_slider)
		_value_slider.scrollable = false
		_value_slider.connect("value_changed", self, "_on_slider_value_changed")
		
		add_child(_value_slider)
	
	func _on_event_published(payload: SignalPayload) -> void:
		if payload.signal_name != Globals.BLEND_SHAPES:
			return
		if payload.id != blend_shape_name:
			return
		
		_value_line_edit.text = str(payload.data)
		_value_line_edit.caret_position = _value_line_edit.text.length()

		_value_slider.ratio = payload.data
	
	func _on_line_edit_text_changed(text: String) -> void:
		if not text.is_valid_float():
			return
		
		AM.ps.publish(Globals.BLEND_SHAPES, text.to_float(), blend_shape_name)
	
	func _on_slider_value_changed(_value: float) -> void:
		AM.ps.publish(Globals.BLEND_SHAPES, _value_slider.ratio, blend_shape_name)

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
		
		blend_shape_list.add_child(
			BlendShapeItem.new(mapping.mesh, blend_shape, mapping.value))
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
