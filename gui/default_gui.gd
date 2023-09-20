class_name DefaultGui
extends CanvasLayer

const SPACER := "__spacer__"

const AppMenu := {
	HOME = "Home",
	s0 = SPACER,
	LOGS = "Logs",
	SETTINGS = "Settings",
	s1 = SPACER,
	QUIT = "Quit"
}

const DebugMenu := {
	TERMINAL = "Terminal",
}

const HelpMenu := {
	ABOUT = "About",
	s0 = SPACER,
	GITHUB = "GitHub",
	DISCORD = "Discord",
	s1 = SPACER,
	LICENSES = "Licenses"
}

var _logger := Logger.create("DefaultGui")

var context: Context = null

@onready
var _side_bar: VBoxContainer = %SideBar
## Button name to resource path. Used for configuring side bar buttons. [br]
## [br]
## [b]THESE MUST ONLY BE [code]res://[/code] PATHS.[b]
@export
var side_bar_items := {
	Tracking = "res://gui/tracking/tracking.tscn"
}

#-----------------------------------------------------------------------------#
# Builtin functions
#-----------------------------------------------------------------------------#

func _ready() -> void:
	var app_menu := %App.get_popup() as PopupMenu
	for val in AppMenu.values():
		if val == SPACER:
			app_menu.add_separator()
		else:
			app_menu.add_item(val)
	app_menu.index_pressed.connect(func(idx: int) -> void:
		match app_menu.get_item_text(idx):
			AppMenu.HOME:
				get_tree().change_scene_to_file("res://screens/home/home.tscn")
				return
			AppMenu.LOGS:
				_logger.error("Not yet implemented!")
				pass
			AppMenu.SETTINGS:
				_logger.error("Not yet implemented!")
				pass
			AppMenu.QUIT:
				get_tree().quit()
				return
	)
	
	var debug_menu := %Debug.get_popup() as PopupMenu
	for val in DebugMenu.values():
		if val == SPACER:
			debug_menu.add_separator()
		else:
			debug_menu.add_item(val)
	debug_menu.index_pressed.connect(func(idx: int) -> void:
		match debug_menu.get_item_text(idx):
			DebugMenu.TERMINAL:
				_logger.error("Not yet implemented!")
				pass
	)
	
	var help_menu := %Help.get_popup() as PopupMenu
	for val in HelpMenu.values():
		if val == SPACER:
			help_menu.add_separator()
		else:
			help_menu.add_item(val)
	help_menu.index_pressed.connect(func(idx: int) -> void:
		match help_menu.get_item_text(idx):
			HelpMenu.ABOUT:
				_logger.error("Not yet implemented!")
				pass
			HelpMenu.GITHUB:
				if OS.shell_open("https://github.com/virtual-puppet-project/vpuppr") != OK:
					_logger.error("Unable to open link to GitHub")
				return
			HelpMenu.DISCORD:
				if OS.shell_open("https://discord.gg/6mcdWWBkrr") != OK:
					_logger.error("Unable to open link to Discord")
				return
			HelpMenu.LICENSES:
				var popup := PopupWindow.new("Licenses", preload("res://gui/licenses.tscn").instantiate())
				
				add_child(popup)
				popup.popup_centered_ratio(0.5)
				return
	)
	
	var h_split_container := $VBoxContainer/HSplitContainer
	h_split_container.split_offset = get_viewport().size.x * 0.15
	
	for key in side_bar_items.keys():
		add_side_bar_item(key, side_bar_items[key])

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
	
	if not ResourceLoader.exists(button_resource_path):
		_logger.error("Resource does not exist for {0} at path {1}".format([
			button_name, button_resource_path]))
		return ERR_DOES_NOT_EXIST
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
		
		var popup := PopupWindow.new(button_name, instance)
		popup.name = button_name
		add_child(popup)
		# TODO configure size somehow?
		popup.popup_centered_ratio(0.5)
	)
	
	_side_bar.add_child(button)
	
	return OK
