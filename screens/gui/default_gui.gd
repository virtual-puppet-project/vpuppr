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

onready var model = $VBoxContainer/HSplitContainer/PanelContainer/PanelContainer/ScrollContainer/HBoxContainer/Model as Button
onready var bones = $VBoxContainer/HSplitContainer/PanelContainer/PanelContainer/ScrollContainer/HBoxContainer/Bones as Button
onready var tracking = $VBoxContainer/HSplitContainer/PanelContainer/PanelContainer/ScrollContainer/HBoxContainer/Tracking as Button
onready var props = $VBoxContainer/HSplitContainer/PanelContainer/PanelContainer/ScrollContainer/HBoxContainer/Props as Button
onready var presets = $VBoxContainer/HSplitContainer/PanelContainer/PanelContainer/ScrollContainer/HBoxContainer/Presets as Button

var runner

###############################################################################
# Builtin functions                                                           #
###############################################################################

func _ready() -> void:
	model.connect("pressed", self, "_on_pressed", [SidebarButtons.MODEL])
	bones.connect("pressed", self, "_on_pressed", [SidebarButtons.BONES])
	tracking.connect("pressed", self, "_on_pressed", [SidebarButtons.TRACKING])
	props.connect("pressed", self, "_on_pressed", [SidebarButtons.PROPS])
	presets.connect("pressed", self, "_on_pressed", [SidebarButtons.PRESETS])

func _input(event: InputEvent) -> void:
	if event.is_action_pressed("toggle_gui"):
		visible = not visible
		
		for child in get_children():
			child.visible = visible

###############################################################################
# Connections                                                                 #
###############################################################################

func _on_pressed(button_id: int) -> void:
	match button_id:
		SidebarButtons.MODEL:
			add_child(_create_popup("Model", Model))
		SidebarButtons.BONES:
			add_child(_create_popup("Bones", Bones))
		SidebarButtons.TRACKING:
			add_child(_create_popup("Tracking", Tracking))
		SidebarButtons.PROPS:
			add_child(_create_popup("Props", Props))
		SidebarButtons.PRESETS:
			add_child(_create_popup("Presets", Presets))

###############################################################################
# Private functions                                                           #
###############################################################################

func _create_popup(popup_name: String, scene: PackedScene) -> BasePopup:
	var popup: BasePopup = BasePopup.new(popup_name, scene)

	popup.set_runner(runner)

	return popup

###############################################################################
# Public functions                                                            #
###############################################################################
