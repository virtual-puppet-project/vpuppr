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

## The node to create popups on. Needed to play nice with other gui controllers
var parent: Node

#-----------------------------------------------------------------------------#
# Builtin functions                                                           #
#-----------------------------------------------------------------------------#

func _ready() -> void:
	#region Application setup
	
	var popup: PopupMenu = app.get_popup()
	popup.connect("about_to_show", self, "_on_about_to_show", [popup])
	popup.connect("id_pressed", self, "_on_popup_item_pressed", [ButtonGrouping.APP])
	popup.hide_on_checkable_item_selection = false
	
	popup.add_item(tr("DEFAULT_GUI_MENU_BAR_APP_MAIN_MENU"), AppButtons.MAIN_MENU)
	
	popup.add_separator()
	
	popup.add_item(tr("DEFAULT_GUI_MENU_BAR_APP_SETTINGS"), AppButtons.SETTINGS)
	popup.add_item(tr("DEFAULT_GUI_MENU_BAR_APP_LOGS"), AppButtons.LOGS)
	
	popup.add_separator()
	
	popup.add_item(tr("DEFAULT_GUI_MENU_BAR_APP_QUIT"), AppButtons.QUIT)
	
	#endregion
	
	#region Debug setup
	
	popup = debug.get_popup()
	popup.connect("about_to_show", self, "_on_about_to_show", [popup])
	popup.connect("id_pressed", self, "_on_popup_item_pressed", [ButtonGrouping.DEBUG])
	popup.hide_on_checkable_item_selection = false
	
	popup.add_check_item(tr("DEFAULT_GUI_MENU_BAR_DEBUG_SHOW_RAW_MESH"), DebugButtons.SHOW_RAW_MESH)
	
	popup.add_separator()
	
	popup.add_item(tr("DEFAULT_GUI_MENU_BAR_DEBUG_DEBUG_CONSOLE"), DebugButtons.DEBUG_CONSOLE)
	
	#endregion
	
	#region Help setup
	
	popup = help.get_popup()
	popup.connect("about_to_show", self, "_on_about_to_show", [popup])
	popup.connect("id_pressed", self, "_on_popup_item_pressed", [ButtonGrouping.HELP])
	popup.hide_on_checkable_item_selection = false
	
	popup.add_item(tr("DEFAULT_GUI_MENU_BAR_HELP_IN_APP_HELP"), HelpButtons.IN_APP_HELP)
	popup.add_item(tr("DEFAULT_GUI_MENU_BAR_HELP_ABOUT"), HelpButtons.ABOUT)
	
	popup.add_separator()
	
	popup.add_item(tr("DEFAULT_GUI_MENU_BAR_HELP_GITHUB"), HelpButtons.GITHUB)
	popup.add_item(tr("DEFAULT_GUI_MENU_BAR_HELP_DISCORD"), HelpButtons.DISCORD)

	popup.add_separator()

	popup.add_item(tr("DEFAULT_GUI_MENU_BAR_HELP_LICENSES"), HelpButtons.LICENSES)
	
	#endregion

#-----------------------------------------------------------------------------#
# Connections                                                                 #
#-----------------------------------------------------------------------------#

# TODO this relies on the popup existing in the SceneTree. This could break if the ordering changes
func _on_about_to_show(popup: PopupMenu) -> void:
	popup.get_parent().remove_child(popup)
	parent.add_child(popup)

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
			get_tree().change_scene(Globals.LANDING_SCREEN_PATH)
		AppButtons.SETTINGS:
			parent.add_child(BasePopup.new(Settings, tr("DEFAULT_GUI_SETTINGS")))
		AppButtons.LOGS:
			parent.add_child(BasePopup.new(Logs, tr("DEFAULT_GUI_LOGS")))
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
			parent.add_child(BasePopup.new(DebugConsole, tr("DEFAULT_GUI_DEBUG_CONSOLE")))

func _handle_help_button(id: int) -> void:
	match id:
		HelpButtons.IN_APP_HELP:
			parent.add_child(BasePopup.new(InAppHelp, tr("DEFAULT_GUI_MENU_BAR_HELP_IN_APP_HELP")))
		HelpButtons.ABOUT:
			parent.add_child(BasePopup.new(About, tr("DEFAULT_GUI_MENU_BAR_HELP_ABOUT")))
		HelpButtons.GITHUB:
			OS.shell_open(Globals.PROJECT_GITHUB_REPO)
		HelpButtons.DISCORD:
			OS.shell_open(Globals.DISCORD_INVITE)
		HelpButtons.LICENSES:
			parent.add_child(BasePopup.new(Licenses, tr("DEFAULT_GUI_MENU_BAR_HELP_LICENSES")))

#-----------------------------------------------------------------------------#
# Public functions                                                            #
#-----------------------------------------------------------------------------#
