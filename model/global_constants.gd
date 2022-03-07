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

enum CustomTypes {
	NONE = 200,
	
	MAIN_LIGHT,
	MAIN_WORLD_ENVIRONMENT
}

const LANDING_SCREEN_PATH := "res://screens/landing_screen.tscn"
const DEFAULT_RUNNER_PATH := "res://screens/default_runner.gd"
