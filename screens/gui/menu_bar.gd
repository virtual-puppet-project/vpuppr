class_name MenuBar
extends PanelContainer

enum ButtonGrouping {
	NONE = 0,

	APPLICATION,
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

onready var app = $HBoxContainer/App as MenuButton
onready var debug = $HBoxContainer/Debug as MenuButton
onready var help = $HBoxContainer/Help as MenuButton

###############################################################################
# Builtin functions                                                           #
###############################################################################

func _ready() -> void:
	#region Application setup
	
	var popup: PopupMenu = app.get_popup()
	popup.connect("id_pressed", self, "_on_popup_item_pressed", [ButtonGrouping.APPLICATION])
	
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
	
	popup.add_check_item("Show Raw Mesh", DebugButtons.SHOW_RAW_MESH)
	
	popup.add_separator()
	
	popup.add_item("Debug Console", DebugButtons.DEBUG_CONSOLE)
	
	#endregion
	
	#region Help setup
	
	popup = help.get_popup()
	popup.connect("id_pressed", self, "_on_popup_item_pressed", [ButtonGrouping.HELP])
	
	popup.add_item("In-app Help", HelpButtons.IN_APP_HELP)
	popup.add_item("About", HelpButtons.ABOUT)
	
	popup.add_separator()
	
	popup.add_item("GitHub", HelpButtons.GITHUB)
	popup.add_item("Discord", HelpButtons.DISCORD)

	popup.add_separator()

	popup.add_item("Licenses", HelpButtons.LICENSES)
	
	#endregion

###############################################################################
# Connections                                                                 #
###############################################################################

func _on_popup_item_pressed(id: int, group: int) -> void:
	match group:
		ButtonGrouping.APPLICATION:
			_handle_app_button(id)
		ButtonGrouping.DEBUG:
			_handle_debug_button(id)
		ButtonGrouping.HELP:
			_handle_help_button(id)

###############################################################################
# Private functions                                                           #
###############################################################################

func _handle_app_button(id: int) -> void:
	match id:
		AppButtons.MAIN_MENU:
			get_tree().change_scene(GlobalConstants.LANDING_SCREEN_PATH)
		AppButtons.SETTINGS:
			# var popup := BasePopup.new("Test", load("res://screens/gui/test.tscn"))

			# get_parent().add_child(popup)
			pass
		AppButtons.LOGS:
			pass
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
			pass

func _handle_help_button(id: int) -> void:
	match id:
		HelpButtons.IN_APP_HELP:
			pass
		HelpButtons.ABOUT:
			pass
		HelpButtons.GITHUB:
			OS.shell_open(GlobalConstants.PROJECT_GITHUB_REPO)
		HelpButtons.DISCORD:
			OS.shell_open(GlobalConstants.DISCORD_INVITE)
		HelpButtons.LICENSES:
			pass

func _create_popup(popup_resource: PackedScene) -> void:
	var popup: Popup = popup_resource.instance()

	add_child(popup)

	popup.popup_centered_ratio()

###############################################################################
# Public functions                                                            #
###############################################################################
