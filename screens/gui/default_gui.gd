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
const BlendShapes = preload("res://screens/gui/blend-shapes/blend_shapes.tscn")
const Props = preload("res://screens/gui/popups/props.tscn")
const Presets = preload("res://screens/gui/popups/presets.tscn")

const BUILTIN_MENUS := {
	"DEFAULT_GUI_MODEL": Model,
	"DEFAULT_GUI_BONES": Bones,
	"DEFAULT_GUI_TRACKING": Tracking,
	"DEFAULT_GUI_BLEND_SHAPES": BlendShapes,
	"DEFAULT_GUI_PROPS": Props,
	"DEFAULT_GUI_PRESETS": Presets
}

var logger: Logger
onready var menu_bar: MenuBar = $VBoxContainer/MenuBar

var grabber_grabbed := false

#-----------------------------------------------------------------------------#
# Builtin functions                                                           #
#-----------------------------------------------------------------------------#

func _init() -> void:
	logger = Logger.new("DefaultGui")

func _ready() -> void:
	menu_bar.parent = self

	var menu_list := $VBoxContainer/HSplitContainer/PanelContainer/PanelContainer/ScrollContainer/MenuList as VBoxContainer

	for menu_name in BUILTIN_MENUS.keys():
		var button := Button.new()
		button.text = tr(menu_name)
		button.connect("pressed", self, "_on_pressed", [BUILTIN_MENUS[menu_name], tr(menu_name)])

		menu_list.add_child(button)

	for ext in AM.em.query_extensions_for_tag(Globals.ExtensionTypes.GUI):
		if not ext.extra.get(Globals.ExtensionExtraKeys.CAN_POPUP, false):
			continue
		
		var button := Button.new()
		button.text = tr(ext.translation_key)
		button.connect("pressed", self, "_on_pressed", [load(ext.entrypoint), tr(ext.translation_key)])

		menu_list.add_child(button)
	
	var grabber := $VBoxContainer/HSplitContainer/PanelContainer/Anchor/Grabber as Control
	grabber.connect("gui_input", self, "_on_grabber_input", [$VBoxContainer/HSplitContainer])
	grabber.mouse_default_cursor_shape = Control.CURSOR_HSIZE

func _input(event: InputEvent) -> void:
	if event.is_action_pressed("toggle_gui"):
		visible = not visible
		
		for child in get_children():
			child.visible = visible

#-----------------------------------------------------------------------------#
# Connections                                                                 #
#-----------------------------------------------------------------------------#

func _on_pressed(scene, popup_name: String) -> void:
	var popup: WindowDialog

	var res := Safely.wrap(AM.tcm.pull(popup_name))
	if res.is_err():
		if res.unwrap_err().code != Error.Code.TEMP_CACHE_MANAGER_KEY_NOT_FOUND:
			logger.error(res)
			return
		popup = _create_popup(scene, popup_name)

		AM.tcm.push(popup_name, popup).cleanup_on_signal(popup, "tree_exiting")

		add_child(popup)
	else:
		popup = res.unwrap()
		move_child(popup, get_child_count() - 1)

func _on_grabber_input(event: InputEvent, split_container: SplitContainer) -> void:
	if event.is_action_pressed("left_click"):
		grabber_grabbed = true
	elif event.is_action_released("left_click"):
		grabber_grabbed = false
	
	if grabber_grabbed and event is InputEventMouseMotion:
		split_container.split_offset += event.relative.x

func _on_grabber_mouse(entered: bool) -> void:
	Input.set_default_cursor_shape(Input.CURSOR_HSIZE if entered else Input.CURSOR_ARROW)

func _on_popup_clicked(event: InputEvent, popup: Control) -> void:
	if not event is InputEventMouseButton or not event.pressed:
		return

	move_child(popup, get_child_count() - 1)

#-----------------------------------------------------------------------------#
# Private functions                                                           #
#-----------------------------------------------------------------------------#

func _create_popup(scene, popup_name: String) -> BasePopup:
	var popup: BasePopup = BasePopup.new(scene, popup_name)

	return popup

#-----------------------------------------------------------------------------#
# Public functions                                                            #
#-----------------------------------------------------------------------------#

func add_child(node: Node, legible_unique_name: bool = false) -> void:
	if node is BasePopup:
		(node as BasePopup).connect("gui_input", self, "_on_popup_clicked", [node])
	
	.add_child(node, legible_unique_name)
