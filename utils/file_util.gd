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

## Loads a Godot resource at the given path
##
## @param: path: String - The path to load a Godot resource from
##
## @return: Result<Object> - The loaded resource
static func load_godot_resource_from_path(path: String) -> Result:
	var file := File.new()
	if not file.file_exists(path):
		return Result.err(Error.Code.FILE_NOT_FOUND, path)

	var resource = load(path)
	var object = resource.instance() if resource is PackedScene else resource.new()
	object.set("name", path.get_basename().get_file())

	return Result.ok(object)

## Loads a runner and a gui
##
## @param: runner_path: String - The path to load a runner from
## @param: gui_path: String - The path to load a gui from
##
## @return: Result<RunnerTrait> - The runner with the gui already added as a child
static func load_runner(runner_path: String, gui_path: String) -> Result:
	var res: Result = load_godot_resource_from_path(runner_path)
	if Result.failed(res):
		return res

	var runner = res.unwrap()

	res = load_godot_resource_from_path(gui_path)
	if Result.failed(res):
		return res

	var gui = res.unwrap()

	runner.add_child(gui)

	var tcm: TempCacheManager = AM.tcm
	tcm.push("runner_path", runner_path)
	tcm.push("gui_path", gui_path)

	return Result.ok(runner)

## Loads a runner and a gui. The current scene is then switched to the new runner
##
## @param: runner_path: String - The path to load a runner from
## @param: gui_path: String j The path to load a gui from
##
## @return: Result<Error> - The error code
static func switch_to_runner(runner_path: String, gui_path: String) -> Result:
	var res: Result = load_runner(runner_path, gui_path)
	if Result.failed(res):
		return res

	var runner = res.unwrap()

	var scene_tree: SceneTree = Engine.get_main_loop()
	var root := scene_tree.root
	var current_scene: Node = scene_tree.current_scene

	root.add_child(runner)
	scene_tree.current_scene = runner
	root.remove_child(current_scene)
	current_scene.queue_free()

	return Result.ok()

## Save text at a given path
##
## @param: path: String - The path to save a file at
## @param: file_text: String - The data to store in the file
##
## @return: Result<String> - The path the file was saved at
static func save_file_at_path(path: String, file_text: String) -> Result:
	var file := File.new()
	if file.open(path, File.WRITE) != OK:
		return Result.err(Error.Code.FILE_WRITE_FAILURE, path)

	file.store_string(file_text)

	file.close()

	return Result.ok(path)

## Removes a file at a given path
##
## @param: path: String - The path to remove a file at
##
## @return: Result<String> - The path the file was removed at
static func remove_file_at_path(path: String) -> Result:
	var dir := Directory.new()
	if not dir.file_exists(path):
		return Result.err(Error.Code.FILE_NOT_FOUND, path)

	if dir.remove(path) != OK:
		return Result.err(Error.Code.FILE_DELETE_FAILED, path)

	return Result.ok(path)
