class_name GlobalConstants
extends Reference

const IGNORED_PROPERTIES_REFERENCE := [
	"Reference",
	"script",
	"Script Variables"
]

const ExtensionTypes := {
	"RUNNER": "runner",
	"PUPPET": "puppet",
	"TRACKER": "tracker",
	"GUI": "gui",
	"PLUGIN": "plugin"
}

const ExtensionOtherKeys := {
	"SELECTABLE_GUI": "selectable_gui",
	"ADD_GUI_AS_DEFAULT": "add_gui_as_default"
}

enum CustomTypes {
	NONE = 200,
	
	MAIN_LIGHT,
	MAIN_WORLD_ENVIRONMENT
}

const SceneSignals := {
	"MOVE_MODEL": "move_model",
	"ROTATE_MODEL": "rotate_model",
	"ZOOM_MODEL": "zoom_model",

	"POSE_MODEL": "pose_model"
}

const LANDING_SCREEN_PATH := "res://screens/landing_screen.tscn"
const DEFAULT_RUNNER_PATH := "res://screens/default_runner.gd"

const SELECTABLE_GUI := "selectable_gui"
const DEFAULT_GUI_PATH := "res://screens/gui/default_gui.tscn"

const PROJECT_GITHUB_REPO := "https://github.com/you-win/openseeface-gd"
const DISCORD_INVITE := "https://discord.com/invite/6mcdWWBkrr"
