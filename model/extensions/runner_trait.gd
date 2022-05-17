class_name RunnerTrait
extends Node

const DEFAULT_MODEL := "res://entities/duck/duck.tscn"
const PUPPET_TRAIT_SCRIPT_PATH := "res://model/extensions/puppet_trait.gd"

var logger: Logger

var current_model_path := ""

#-----------------------------------------------------------------------------#
# Builtin functions                                                           #
#-----------------------------------------------------------------------------#

## DON'T OVERRIDE THIS
func _ready() -> void:
	_setup_logger()
	_setup_config()
	_setup_scene()

## DON'T OVERRIDE THIS
func _process(delta: float) -> void:
	_process_step(delta)

## DONT'T OVERRIDE THIS
func _physics_process(delta: float) -> void:
	_physics_step(delta)

## Virtual function that sets up the local logger
func _setup_logger() -> void:
	logger = Logger.new("RunnerTrait")
	logger.info("Using base logger, this is not recommended")

## Virtual function that sets up commonly used config connections
func _setup_config() -> void:
	pass

## Virtual function that sets up the scene
func _setup_scene() -> void:
	pass

## Virtual function that should be overridden instead of `_process`
func _process_step(_delta: float) -> void:
	pass

## Virtual function that should be overridden instead of `_physics_process`
func _physics_step(_delta: float) -> void:
	pass

#-----------------------------------------------------------------------------#
# Connections                                                                 #
#-----------------------------------------------------------------------------#

## Virtual callback, will not do anything until overridden
##
## @param: value: Variant - The changed value
## @param: signal_name: String - The signal the `value` is associated with
func _on_config_changed(value, signal_name: String) -> void:
	logger.error("Signal %s received with value %s\n_on_config_changed not yet implemented" %
			[signal_name, str(value)])

#-----------------------------------------------------------------------------#
# Private functions                                                           #
#-----------------------------------------------------------------------------#

## Finds all loaders implemented on the Runner along with loaders from plugins
##
## A loader must be in format load_<file_type>(path: String) -> Result. If not,
## things might break.
##
## Implementation note: `get_method_list` returns an array of dicts in format
## ```
## [
##	{
##		"name": String,
##		"args: [
##			{
##				"name": String,
##				"class_name": String,
##				"type": int,
##				"hint": int,
##				"hint_string": String,
##				"usage": int
##			}
##		],
##		"default_args": [
##			"args"
##		],
##		"flags": int,
##		"id": int,
##		"return": {
##			"name": String,
##			"class_name": String,
##			"type": int,
##			"hint_string": String,
##			"usage": int
##		}
##	},
##	...
## ```
func _find_loaders() -> Dictionary:
	var r := {} # File type: String -> Loader method: String

	# Start with Loaders implemented in the current/sub scope
	var object_methods := get_method_list()

	for method_desc in object_methods:
		var split_name: PoolStringArray = method_desc.name.split("_")
		if split_name.size() != 2:
			continue
		if split_name[0] != "load":
			continue
		
		r[split_name[1]] = method_desc.name
	
	return r

## Tries to load a mode from a given path
##
## Will try and match the model's file extension to all registered loaders
##
## @param: path: String - The absolute path to a model
##
## @return: Result<Variant> - The loaded model
func _try_load_model(path: String) -> Result:
	var file := File.new()
	if not file.file_exists(path):
		return Result.err(Error.Code.RUNNER_FILE_NOT_FOUND, path)

	var loaders := _find_loaders()
	if loaders.empty():
		return Result.err(Error.Code.RUNNER_NO_LOADERS_FOUND)

	var file_ext := path.get_extension().to_lower()

	if not loaders.has(file_ext):
		return Result.err(Error.Code.RUNNER_UNHANDLED_FILE_FORMAT, file_ext)

	var method_name: String = loaders[file_ext]

	logger.info("Loading %s using %s" % [path, method_name])
	
	return(call(method_name, path))

#-----------------------------------------------------------------------------#
# Public functions                                                            #
#-----------------------------------------------------------------------------#

## Virtual function for loading a model
##
## @param: path: String - The absolute path to a model
func load_model(_path: String) -> void:
	pass

## Uses the built-in gltf loader to load a `glb` model
##
## @param: path: String - The absolute path to a model
##
## @return: Result<Spatial> - The loaded model
func load_glb(path: String) -> Result:
	var gltf_loader := PackedSceneGLTF.new()

	var model = gltf_loader.import_gltf_scene(path)
	if model == null:
		return Result.err(Error.Code.RUNNER_LOAD_FILE_FAILED)

	var script: GDScript = load(PUPPET_TRAIT_SCRIPT_PATH)
	if script == null:
		return Result.err(Error.Code.RUNNER_LOAD_FILE_FAILED)

	model.set_script(script)
	
	return Result.ok(model)

## Uses the built-in scene loader to load a PackedScene
##
## @param: path: String - The absolute path to a PackedScene
##
## @return: Result<Variant> - The loaded scene
func load_scn(path: String) -> Result:
	var model = load(path)
	if model == null:
		return Result.err(Error.Code.RUNNER_LOAD_FILE_FAILED)

	var model_instance: Node = model.instance()
	if model_instance == null:
		return Result.err(Error.Code.RUNNER_LOAD_FILE_FAILED)

	return Result.ok(model_instance)

## Uses the built-in scene loader to load a PackedScene
##
## @see: `load_scn`
func load_tscn(path: String) -> Result:
	return load_scn(path)
