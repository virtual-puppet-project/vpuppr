class_name MenuBar
extends PanelContainer

enum ButtonGrouping {
	NONE = 0,

	APP,
	LAYOUT,
	DEBUG,
	HELP
}

enum AppButtons {
	NONE = 0,

	MAIN_MENU,
	SETTINGS,
	LOGS,
	QUIT
}

enum LayoutButtons {
	NONE = 0,
	
	SAVE,
	LOAD,
	RESET,
	DEFAULT
}

enum DebugButtons {
	NONE = 0,

	SHOW_RAW_MESH,
	DEBUG_CONSOLE
}

enum HelpButtons {
	NONE = 0,

	IN_APP_HELP,
	ABOUT,
	GITHUB,
	DISCORD,
	LICENSES
}

const Logs = preload("res://screens/gui/popups/logs.tscn")
const Settings = preload("res://screens/gui/settings.tscn")

const DebugConsole = preload("res://screens/gui/popups/debug_console.tscn")

const InAppHelp = preload("res://screens/gui/popups/in_app_help.tscn")
const About = preload("res://screens/gui/popups/about.tscn")
const Licenses = preload("res://screens/gui/popups/licenses.tscn")

onready var app = $HBoxContainer/App as MenuButton
onready var debug = $HBoxContainer/Debug as MenuButton
onready var help = $HBoxContainer/Help as MenuButton

#-----------------------------------------------------------------------------#
# Builtin functions                                                           #
#-----------------------------------------------------------------------------#

func _ready() -> void:
	#region Application setup
	
	var popup: PopupMenu = app.get_popup()
	popup.connect("id_pressed", self, "_on_popup_item_pressed", [ButtonGrouping.APP])
	popup.hide_on_checkable_item_selection = false
	
	popup.add_item("Main Menu", AppButtons.MAIN_MENU)
	
	popup.add_separator()
	
	popup.add_item("Settings", AppButtons.SETTINGS)
	popup.add_item("Logs", AppButtons.LOGS)
	
	popup.add_separator()
	
	popup.add_item("Quit", AppButtons.QUIT)
	
	#endregion
	
	#region Debug setup
	
	popup = debug.get_popup()
	popup.connect("id_pressed", self, "_on_popup_item_pressed", [ButtonGrouping.DEBUG])
	popup.hide_on_checkable_item_selection = false
	
	popup.add_check_item("Show Raw Mesh", DebugButtons.SHOW_RAW_MESH)
	
	popup.add_separator()
	
	popup.add_item("Debug Console", DebugButtons.DEBUG_CONSOLE)
	
	#endregion
	
	#region Help setup
	
	popup = help.get_popup()
	popup.connect("id_pressed", self, "_on_popup_item_pressed", [ButtonGrouping.HELP])
	popup.hide_on_checkable_item_selection = false
	
	popup.add_item("In-app Help", HelpButtons.IN_APP_HELP)
	popup.add_item("About", HelpButtons.ABOUT)
	
	popup.add_separator()
	
	popup.add_item("GitHub", HelpButtons.GITHUB)
	popup.add_item("Discord", HelpButtons.DISCORD)

	popup.add_separator()

	popup.add_item("Licenses", HelpButtons.LICENSES)
	
	#endregion

#-----------------------------------------------------------------------------#
# Connections                                                                 #
#-----------------------------------------------------------------------------#

func _on_popup_item_pressed(id: int, group: int) -> void:
	match group:
		ButtonGrouping.APP:
			_handle_app_button(id)
		ButtonGrouping.DEBUG:
			_handle_debug_button(id)
		ButtonGrouping.HELP:
			_handle_help_button(id)

#-----------------------------------------------------------------------------#
# Private functions                                                           #
#-----------------------------------------------------------------------------#

func _handle_app_button(id: int) -> void:
	match id:
		AppButtons.MAIN_MENU:
			get_tree().change_scene(GlobalConstants.LANDING_SCREEN_PATH)
		AppButtons.SETTINGS:
			add_child(BasePopup.new("Settings", Settings))
		AppButtons.LOGS:
			add_child(BasePopup.new("Logs", Logs))
		AppButtons.QUIT:
			get_tree().quit()

func _handle_debug_button(id: int) -> void:
	match id:
		DebugButtons.SHOW_RAW_MESH:
			var popup: PopupMenu = debug.get_popup()
			var idx: int = popup.get_item_index(DebugButtons.SHOW_RAW_MESH)
			popup.set_item_checked(idx, not popup.is_item_checked(idx))
			# TODO toggle textures somehow?
		DebugButtons.DEBUG_CONSOLE:
			add_child(BasePopup.new("Debug Console", DebugConsole))

func _handle_help_button(id: int) -> void:
	match id:
		HelpButtons.IN_APP_HELP:
			add_child(BasePopup.new("In-app Help", InAppHelp))
		HelpButtons.ABOUT:
			add_child(BasePopup.new("About", About))
		HelpButtons.GITHUB:
			OS.shell_open(GlobalConstants.PROJECT_GITHUB_REPO)
		HelpButtons.DISCORD:
			OS.shell_open(GlobalConstants.DISCORD_INVITE)
		HelpButtons.LICENSES:
			add_child(BasePopup.new("Licenses", Licenses))

func _create_popup(popup_resource: PackedScene) -> void:
	var popup: Popup = popup_resource.instance()

	add_child(popup)

	popup.popup_centered_ratio()

#-----------------------------------------------------------------------------#
# Public functions                                                            #
#-----------------------------------------------------------------------------#
