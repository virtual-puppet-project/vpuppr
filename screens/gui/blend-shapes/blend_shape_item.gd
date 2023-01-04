extends VBoxContainer

const BlendShapeItemHotkey: PackedScene = preload(
	"res://screens/gui/blend-shapes/blend_shape_item_hotkey.tscn")

const ReplaceTypes := {
	"REPLACE": "DEFAULT_GUI_BLEND_SHAPE_ITEM_REPLACE_TYPE_OVERRIDE",
	"ADD": "DEFAULT_GUI_BLEND_SHAPE_ITEM_REPLACE_TYPE_ADD",
	"COMPLEX": "DEFAULT_GUI_BLEND_SHAPE_ITEM_REPLACE_TYPE_COMPLEX"
}

onready var replace_type := $ReplaceType as MenuButton
onready var hotkey_list := $Hotkeys/List as VBoxContainer

var logger: Logger

var mesh_instance: MeshInstance
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

	$Hotkeys/AddSequence.connect("pressed", self, "_on_add_sequence")
	
	value_slider.value = blend_shape_value
	value_slider.connect("value_changed", self, "_on_slider_value_changed")
#	value_slider.connect("drag_started", self, "_on_slider_drag_started")
#	value_slider.connect("drag_ended", self, "_on_slider_drag_ended")

	AM.ps.subscribe(self, Globals.BLEND_SHAPES, "_on_blend_shape_modified")
	AM.ps.subscribe(self, "action_pressed")

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
		Globals.HOTKEY_ACTION_RECEIVED:
			# TODO stub
			pass
		_:
			logger.error("Unhandled signal payload %s" % payload.to_string())

func _on_add_sequence() -> void:
	var hotkey_item: Control = BlendShapeItemHotkey.instance()
	hotkey_item.logger = logger
	
	hotkey_list.add_child(hotkey_item)
	hotkey_item.blend_shape_name = blend_shape_name

func _on_value_line_edit_changed(text: String) -> void:
	if not text.is_valid_float():
		return
	if text == value_line_edit.text: # Avoid infinite loop
		return
	
	AM.ps.publish(Globals.BLEND_SHAPES, text.to_float(), blend_shape_name)

func _on_slider_value_changed(_value: float) -> void:
	AM.ps.publish(Globals.BLEND_SHAPES, value_slider.ratio, blend_shape_name)

func _on_blend_shape_modified(payload: SignalPayload) -> void:
	if payload.id != blend_shape_name:
		return
	
	value_line_edit.text = str(payload.data)
	value_slider.value = payload.data

func _on_action_pressed(action_name: String) -> void:
	if action_name != blend_shape_name:
		return

	# TODO implement hotkey support

#-----------------------------------------------------------------------------#
# Private functions                                                           #
#-----------------------------------------------------------------------------#

#-----------------------------------------------------------------------------#
# Public functions                                                            #
#-----------------------------------------------------------------------------#
