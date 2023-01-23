extends VBoxContainer

const ReplaceTypes := {
	"REPLACE": "DEFAULT_GUI_BLEND_SHAPE_ITEM_REPLACE_TYPE_OVERRIDE",
	"ADD": "DEFAULT_GUI_BLEND_SHAPE_ITEM_REPLACE_TYPE_ADD",
	"COMPLEX": "DEFAULT_GUI_BLEND_SHAPE_ITEM_REPLACE_TYPE_COMPLEX"
}

var logger: Logger

var mesh_instance: MeshInstance = null
var blend_shape_name := ""
var blend_shape_value: float = 0.0

onready var value_line_edit := $Value/Value
onready var value_slider := $HSlider

var is_slider_dragging := false
var last_slider_ratio: float = 0.0

#-----------------------------------------------------------------------------#
# Builtin functions                                                           #
#-----------------------------------------------------------------------------#

func _ready() -> void:
	$BlendShapeName/Value.text = blend_shape_name
	value_line_edit.text = str(blend_shape_value)
	value_line_edit.connect("text_changed", self, "_on_value_line_edit_changed")
	
	value_slider.value = blend_shape_value
	value_slider.connect("value_changed", self, "_on_slider_value_changed")

	AM.ps.subscribe(self, Globals.BLEND_SHAPES, "_on_blend_shape_modified")

func _process(_delta: float) -> void:
	var current_value: float = mesh_instance.get("blend_shapes/%s" % blend_shape_name)
	
	value_line_edit.text = str(current_value)
	value_slider.ratio = current_value

#-----------------------------------------------------------------------------#
# Connections                                                                 #
#-----------------------------------------------------------------------------#

func _on_event_published(payload: SignalPayload) -> void:
	match payload.signal_name:
		Globals.BLEND_SHAPES:
			if payload.id != blend_shape_name:
				return
			value_line_edit.text = str(payload.data)
			value_line_edit.caret_position = value_line_edit.text.length()
			
			value_slider.ratio = payload.data
		_:
			logger.error("Unhandled signal payload %s" % payload.to_string())

func _on_value_line_edit_changed(text: String) -> void:
	if not text.is_valid_float():
		return
	if text == value_line_edit.text: # Avoid infinite loop
		return
	
	mesh_instance.set("blend_shapes/%s" % blend_shape_name, text.to_float())

func _on_slider_value_changed(_value: float) -> void:
	mesh_instance.set("blend_shapes/%s" % blend_shape_name, value_slider.ratio)

func _on_blend_shape_modified(payload: SignalPayload) -> void:
	if payload.id != blend_shape_name:
		return
	
	value_line_edit.text = str(payload.data)
	value_slider.value = payload.data

#-----------------------------------------------------------------------------#
# Private functions                                                           #
#-----------------------------------------------------------------------------#

#-----------------------------------------------------------------------------#
# Public functions                                                            #
#-----------------------------------------------------------------------------#
