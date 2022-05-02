class_name DefaultGui
extends Control

enum SidebarButtons {
	NONE = 0,
	
	MODEL,
	BONES,
	TRACKING,
	PROPS,
	PRESETS
}

const Model = preload("res://screens/gui/popups/model.tscn")
const Bones = preload("res://screens/gui/popups/bones.tscn")
const Tracking = preload("res://screens/gui/popups/tracking.tscn")
const Props = preload("res://screens/gui/popups/props.tscn")
const Presets = preload("res://screens/gui/popups/presets.tscn")

const BUILTIN_MENUS := [
	Model,
	Bones,
	Tracking,
	Props,
	Presets
]

var grabber_grabbed := false

###############################################################################
# Builtin functions                                                           #
###############################################################################

func _ready() -> void:
	var menu_list := $VBoxContainer/HSplitContainer/PanelContainer/PanelContainer/ScrollContainer/MenuList as VBoxContainer

	for menu in BUILTIN_MENUS:
		var button := Button.new()
		button.text = menu.resource_path.get_file().get_basename().capitalize()
		button.connect("pressed", self, "_on_pressed", [menu])

		menu_list.add_child(button)

	for ext in AM.em.query_extensions_for_type(GlobalConstants.ExtensionTypes.GUI):
		if not ext.other.get(GlobalConstants.ExtensionOtherKeys.ADD_GUI_AS_DEFAULT, false):
			continue
		
		var button := Button.new()
		button.text = ext.resource_name
		button.connect("pressed", self, "_on_pressed", [load(ext.resource_entrypoint)])

		menu_list.add_child(button)
	
	var grabber := $VBoxContainer/HSplitContainer/PanelContainer/Anchor/Grabber as Control
	grabber.connect("gui_input", self, "_on_grabber_input", [$VBoxContainer/HSplitContainer])
	grabber.mouse_default_cursor_shape = Control.CURSOR_HSIZE

func _input(event: InputEvent) -> void:
	if event.is_action_pressed("toggle_gui"):
		visible = not visible
		
		for child in get_children():
			child.visible = visible

###############################################################################
# Connections                                                                 #
###############################################################################

func _on_pressed(scene) -> void:
	add_child(_create_popup(scene.resource_path.get_file().get_basename().capitalize(), scene))

func _on_grabber_input(event: InputEvent, split_container: SplitContainer) -> void:
	if event.is_action_pressed("left_click"):
		grabber_grabbed = true
	elif event.is_action_released("left_click"):
		grabber_grabbed = false
	
	if grabber_grabbed and event is InputEventMouseMotion:
		split_container.split_offset += event.relative.x

func _on_grabber_mouse(entered: bool) -> void:
	Input.set_default_cursor_shape(Input.CURSOR_HSIZE if entered else Input.CURSOR_ARROW)

###############################################################################
# Private functions                                                           #
###############################################################################

func _create_popup(popup_name: String, scene) -> BasePopup:
	var popup: BasePopup = BasePopup.new(popup_name, scene)

	return popup

###############################################################################
# Public functions                                                            #
###############################################################################
