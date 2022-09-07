class_name FileUtil
extends Reference

#-----------------------------------------------------------------------------#
# Builtin functions                                                           #
#-----------------------------------------------------------------------------#

#-----------------------------------------------------------------------------#
# Connections                                                                 #
#-----------------------------------------------------------------------------#

#-----------------------------------------------------------------------------#
# Private functions                                                           #
#-----------------------------------------------------------------------------#

#-----------------------------------------------------------------------------#
# Public functions                                                            #
#-----------------------------------------------------------------------------#

## Takes an absolute or relative path and returns the filename without an extension
##
## @param: path: String - The path to strip
##
## @return: String - The stripped name
static func path_to_stripped_name(path: String) -> String:
	return path.get_basename().get_file().validate_node_name()

## Loads a Godot resource at the given path
##
## @param: path: String - The path to load a Godot resource from
##
## @return: Result<Object> - The loaded resource
static func load_godot_resource_from_path(path: String) -> Result:
	if not path.begins_with("res"):
		var file := File.new()
		if not file.file_exists(path):
			return Safely.err(Error.Code.FILE_NOT_FOUND, path)

	var resource = load(path)
	if resource == null:
		return Safely.err(Error.Code.FILE_NOT_FOUND, path)

	var object = resource.instance() if resource is PackedScene else resource.new()

	return Safely.ok(object)

## Loads a runner and a gui
##
## @param: runner_path: String - The path to load a runner from
## @param: gui_path: String - The path to load a gui from
##
## @return: Result<RunnerTrait> - The runner with the gui already added as a child
static func load_runner(runner_path: String, gui_path: String) -> Result:
	var res: Result = Safely.wrap(load_godot_resource_from_path(runner_path))
	if res.is_err():
		return res

	var runner = res.unwrap()

	res = Safely.wrap(load_godot_resource_from_path(gui_path))
	if res.is_err():
		return res

	var gui = res.unwrap()

	runner.add_child(gui)

	var tcm: TempCacheManager = AM.tcm
	tcm.push("runner_path", runner_path).cleanup_on_pull()
	tcm.push("gui_path", gui_path).cleanup_on_pull()

	return Safely.ok(runner)

## Loads a runner and a gui. The current scene is then switched to the new runner
##
## @param: runner_path: String - The path to load a runner from
## @param: gui_path: String j The path to load a gui from
##
## @return: Result<Error> - The error code
static func switch_to_runner(runner_path: String, gui_path: String) -> Result:
	var res: Result = Safely.wrap(load_runner(runner_path, gui_path))
	if res.is_err():
		return res

	var runner = res.unwrap()

	var scene_tree: SceneTree = Engine.get_main_loop()
	var root := scene_tree.root
	var current_scene: Node = scene_tree.current_scene

	root.remove_child(current_scene)
	current_scene.queue_free()
	
	root.add_child(runner)
	scene_tree.current_scene = runner

	return Safely.ok()

## Save text at a given path
##
## @param: path: String - The path to save a file at
## @param: file_text: String - The data to store in the file
##
## @return: Result<String> - The path the file was saved at
static func save_file_at_path(path: String, file_text: String) -> Result:
	var file := File.new()
	if file.open(path, File.WRITE) != OK:
		return Safely.err(Error.Code.FILE_WRITE_FAILURE, path)

	file.store_string(file_text)

	file.close()

	return Safely.ok(path)

## Removes a file at a given path
##
## @param: path: String - The path to remove a file at
##
## @return: Result<String> - The path the file was removed at
static func remove_file_at_path(path: String) -> Result:
	var dir := Directory.new()
	if not dir.file_exists(path):
		return Safely.err(Error.Code.FILE_NOT_FOUND, path)

	if dir.remove(path) != OK:
		return Safely.err(Error.Code.FILE_DELETE_FAILED, path)

	return Safely.ok(path)

static func inject_env_vars(text: String) -> String:
	text = text.replace("$EXE_DIR", OS.get_executable_path().get_base_dir())
	
	return text \
		.replace("$EXE_DIR", OS.get_executable_path().get_base_dir()) \
		.replace("$PROJECT", ProjectSettings.globalize_path("res://")) \
		.replace("$USER", ProjectSettings.globalize_path("user://")) \
		.replace("$HOME", OS.get_environment("HOME"))
