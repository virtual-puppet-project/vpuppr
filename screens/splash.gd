extends CanvasLayer

## Splash screen for preloading resources.
##
## Screen for preloading resources to prevent any stuttering when opening the app.
## [br][br]
## [b]Do not access any autoloads here![/b]

## Path to the main theme used for the app.
const THEME_PATH := "res://assets/main.theme"
## Path to the home screen.
const HOME_PATH := "res://screens/home/home.tscn"

## Spin animation name.
const SPIN_ANIM := "spin"

@onready
var _icon := %Icon
@onready
var _status_label := %StatusLabel
@onready
var _loading_bar := %LoadingBar
@onready
var _anim_player := $AnimationPlayer

## The things that are being loaded.
var _loadables := [
	THEME_PATH,
	HOME_PATH
]
## The loadables that are still being loaded. This is modified in a separate step to
## avoid unexpected iteration behavior.
var _loadables_in_progress := []
## Precalculated size of all things to be loaded.
var _loadables_size: int = 0
## Count of successfully loaded resources.
var _load_successes: int = 0
## Count of unsuccessfully loaded resources.
var _load_failures: int = 0
## Preallocated array for storing the load percentage.
var _status := []

#-----------------------------------------------------------------------------#
# Builtin functions
#-----------------------------------------------------------------------------#

func _ready() -> void:
	var current_screen := DisplayServer.window_get_current_screen()
	var current_screen_size := DisplayServer.screen_get_size(current_screen)
	var new_window_size := current_screen_size * 0.75
	
	DisplayServer.window_set_size(new_window_size)
	DisplayServer.window_set_position((current_screen_size * 0.5) - (new_window_size * 0.5))
	# TODO August 1, 2023 Godot still moves the window to screen 1 instead of screen 0
	DisplayServer.window_set_current_screen(current_screen)
	
	_icon.pivot_offset = _icon.size / 2
	
	_loadables_size = _loadables.size()
	for i in _loadables:
		ResourceLoader.load_threaded_request(i)
	_loadables_in_progress = _loadables.duplicate(true)
	
	_anim_player.play(SPIN_ANIM)

func _process(delta: float) -> void:
	var load_progress: float = float(_load_successes + _load_failures) / _loadables_size
	var loadables_completed := []
	_status.clear()
	
	for i in _loadables_in_progress:
		match ResourceLoader.load_threaded_get_status(i, _status):
			ResourceLoader.THREAD_LOAD_LOADED:
				_load_successes += 1
				loadables_completed.append(i)
			ResourceLoader.THREAD_LOAD_IN_PROGRESS:
				load_progress += _status[0] / _loadables_size
			_:
				_load_failures += 1
				loadables_completed.append(i)
				printerr("Unable to preload resource %s" % i)
	
	for i in loadables_completed:
		_loadables_in_progress.erase(i)
	
	if _load_successes + _load_failures == _loadables_size:
		var home_scene: PackedScene = ResourceLoader.load_threaded_get(HOME_PATH)
		var home: Node = home_scene.instantiate()
		
		var scene_tree := get_tree()
		scene_tree.root.add_child(home)
		scene_tree.current_scene = home
		self.queue_free()
	else:
		_loading_bar.value = load_progress * 100.0

#-----------------------------------------------------------------------------#
# Private functions
#-----------------------------------------------------------------------------#

#-----------------------------------------------------------------------------#
# Public functions
#-----------------------------------------------------------------------------#

