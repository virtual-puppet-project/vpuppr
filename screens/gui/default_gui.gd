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

###############################################################################
# Builtin functions                                                           #
###############################################################################

func _ready() -> void:
	model.connect("pressed", self, "_on_pressed", [SidebarButtons.MODEL])
	bones.connect("pressed", self, "_on_pressed", [SidebarButtons.BONES])
	tracking.connect("pressed", self, "_on_pressed", [SidebarButtons.TRACKING])
	props.connect("pressed", self, "_on_pressed", [SidebarButtons.PROPS])
	presets.connect("pressed", self, "_on_pressed", [SidebarButtons.PRESETS])

###############################################################################
# Connections                                                                 #
###############################################################################

func _on_pressed(button_id: int) -> void:
	match button_id:
		SidebarButtons.MODEL:
			add_child(BasePopup.new("Model", Model))
		SidebarButtons.BONES:
			add_child(BasePopup.new("Bones", Bones))
		SidebarButtons.TRACKING:
			add_child(BasePopup.new("Tracking", Tracking))
		SidebarButtons.PROPS:
			add_child(BasePopup.new("Props", Props))
		SidebarButtons.PRESETS:
			add_child(BasePopup.new("Presets", Presets))

###############################################################################
# Private functions                                                           #
###############################################################################

###############################################################################
# Public functions                                                            #
###############################################################################
