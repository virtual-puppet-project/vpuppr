class_name Globals
extends Reference

const IGNORED_REFERENCE_PROPERTIES := [
	"Reference",
	"script",
	"Script Variables",
]

const IGNORED_RESOURCE_PROPERTIES := [
	"Reference",
	"Resource",
	"script",
	"Script Variables",
	"resource_local_to_scene",
	"resource_path",
	"resource_name"
]

const IGNORED_SPATIAL_PROPERTIES := [
	"Node",
	"Spatial",
	"editor_description",
	"_import_path",
	"pause_mode",
	"name",
	"filename",
	"owner",
	"multiplayer",
	"custom_multiplayer",
	"process_priority",
	"Transform",
	"Matrix",
	"Visibility",
	"gizmo",
	"script",
	"Script Variables"
]

#region Extensions

const ExtensionTypes := {
	"RUNNER": "runner",
	"PUPPET": "puppet",
	"TRACKER": "tracker",
	"GUI": "gui",
	"PLUGIN": "plugin"
}

const ExtensionOtherKeys := {
	# Whether to show this as a selectable GUI when starting a runner
	# Defaults to false
	"SELECTABLE_GUI": "selectable_gui",
	# Whether to show this as a popup in the default GUI
	# Defaults to false
	"ADD_GUI_AS_DEFAULT": "add_gui_as_default",
	# Arbitrary data associated with the extension resource. Must be a relative path
	# Can optionally define an entrypoint func if the data is a GDScript file delimited by a ":"
	# e.g. "my_data.gd:my_entrypoint"
	"DATA": "data"
}

#endregion

#region Signals

const EVENT_PUBLISHED := "event_published"

const MESSAGE_LOGGED := "message_logged"

const TRACKER_TOGGLED := "tracker_toggled"
const TRACKER_INFO_REORDERED := "tracker_info_reordered"
const TRACKER_USE_AS_MAIN_TRACKER := "tracker_use_as_main"

const MODEL_LOADED := "model_loaded"

const POSE_BONE := "pose_bone"
const BONE_TRANSFORMS := "bone_transforms"

const RELOAD_RUNNER := "reload_runner"

#endregion

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
const DEFAULT_GUI_PATH := "res://screens/gui/default_gui.tscn"
const DEFAULT_MODEL_PATH := "res://entities/duck/duck.tscn"

const TRANSLATIONS_PATH := "/resources/translations"
const EXTENSION_TRANSLATION_PATH := "/translations"

const PROJECT_GITHUB_REPO := "https://github.com/virtual-puppet-project/vpuppr"
const DISCORD_INVITE := "https://discord.com/invite/6mcdWWBkrr"

const RUNNER_PREVIEW_DIR_PATH := "user://runner-previews/"
const RUNNER_PREVIEW_FILE_EXT := "png"

const CHROMAKEY_GREEN_HEX := "00b140"
