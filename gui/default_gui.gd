class_name DefaultGui
extends CanvasLayer

var _logger := Logger.create("DefaultGui")

var context: Context = null

@onready
var _side_bar: VBoxContainer = %SideBar

#-----------------------------------------------------------------------------#
# Builtin functions
#-----------------------------------------------------------------------------#

func _ready() -> void:
	var h_split_container := $VBoxContainer/HSplitContainer
	h_split_container.split_offset = get_viewport().size.x * 0.15
	
	add_side_bar_item("Tracking", "res://gui/tracking/tracking.tscn")

#-----------------------------------------------------------------------------#
# Private functions
#-----------------------------------------------------------------------------#

#-----------------------------------------------------------------------------#
# Public functions
#-----------------------------------------------------------------------------#

## Add a button to the side bar that will display the contents stored at
## [param button_resource_path] in a popup window.
func add_side_bar_item(button_name: StringName, button_resource_path: StringName) -> Error:
	_logger.debug("Adding side bar item {0} for {1}".format([button_name, button_resource_path]))
	
	if _side_bar.has_node(NodePath(button_name)):
		_logger.error("Side bar item {0} already exists".format([button_name]))
		return ERR_ALREADY_EXISTS
	
	var button := Button.new()
	button.name = button_name
	button.text = button_name
	button.focus_mode = Control.FOCUS_NONE
	button.pressed.connect(func() -> void:
		var resource: Variant = load(String(button_resource_path))
		if resource == null:
			_logger.error("Unable to load resource at {0}".format([button_resource_path]))
			return
		
		# TODO add more checks
		var instance: Node = null
		if resource is PackedScene:
			instance = resource.instantiate()
		elif resource is GDScript:
			instance = resource.new()
		else:
			_logger.error("Unhandled resource type at {0}".format([button_resource_path]))
			return
		
		instance.set("context", context)
		
		var popup := PopupWindow.new(context, button_name, instance)
		add_child(popup)
		# TODO configure size somehow?
		popup.popup_centered_ratio()
	)
	
	_side_bar.add_child(button)
	
	return OK
