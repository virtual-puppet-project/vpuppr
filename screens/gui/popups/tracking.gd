extends BaseTreeLayout

const TrackingDisplay := preload("res://screens/gui/popups/tracking_display.gd")

const INFO_PAGE := "Info"

var info: ScrollContainer

#-----------------------------------------------------------------------------#
# Builtin functions                                                           #
#-----------------------------------------------------------------------------#

func _setup_logger() -> void:
	logger = Logger.new("Tracking")

func _setup() -> void:
	info = $Info
	tree = $Tree
	pages[INFO_PAGE] = info

	_initial_page = INFO_PAGE

	tree.hide_root = true
	var root: TreeItem = tree.create_item()

	var info_item: TreeItem = tree.create_item(root)
	info_item.set_text(TREE_COLUMN, INFO_PAGE)
	info_item.select(TREE_COLUMN)
	_toggle_page(INFO_PAGE)

	tree.connect("item_selected", self, "_on_item_selected")

	for er in AM.em.query_extensions_for_type(GlobalConstants.ExtensionTypes.TRACKER):
		er = er as ExtensionResource
		if not er.other.has(GlobalConstants.ExtensionOtherKeys.DATA):
			logger.error("Extension %s missing data descriptor, skipping" % er.resource_name)
			continue

		var context_res: Result = AM.em.get_context(er.extension_name)
		if not context_res or context_res.is_err():
			logger.err(context_res.unwrap_err().to_string() if context_res else
				"Unable to get ExtensionContext for %s" % er.resource_name)
			continue

		var entrypoint: String = er.other[GlobalConstants.ExtensionOtherKeys.DATA]

		var descriptor_res: Result = _from_descriptor(context_res.unwrap(), entrypoint)
		if not descriptor_res or descriptor_res.is_err():
			logger.error(descriptor_res.unwrap_err().to_string() if descriptor_res else
				"Unable to process descriptor for %s" % er.resource_name)
			continue

		var item: TreeItem = tree.create_item(root)
		item.set_text(TREE_COLUMN, er.resource_name)

		# var tracking_display := TrackingDisplay.new(er.resource_name, descriptor_res.unwrap(), logger)
		var display = descriptor_res.unwrap()
		pages[er.resource_name] = display
		display.hide()

		add_child(display)

#-----------------------------------------------------------------------------#
# Connections                                                                 #
#-----------------------------------------------------------------------------#

#-----------------------------------------------------------------------------#
# Private functions                                                           #
#-----------------------------------------------------------------------------#

## Finds all applicable handlers and returns them as a Dictionary
##
## @return: Dictionary<String, String> - The file extension -> func name mapping
func _find_handlers() -> Dictionary:
	var r := {}

	var object_methods := get_method_list()

	for method_desc in object_methods:
		var split_name: PoolStringArray = method_desc.name.rsplit("_", true, 1)
		if split_name.size() != 2:
			continue
		if split_name[0] != "_handle":
			continue

		r[split_name[1]] = method_desc.name

	return r

## @return: Result<Dictionary<String, Node>> - The UI parsed from the descriptor
func _from_descriptor(context: ExtensionContext, path_and_func: String) -> Result:
	var split := path_and_func.split(":", false, 1)
	var path: String = split[0]
	var entrypoint := split[1] if split.size() > 1 else ""
	
	var file := File.new()
	if file.open("%s/%s" % [context.context_path, path], File.READ) != OK:
		return Result.err(Error.Code.GUI_TRACKER_LOAD_FILE_FAILED,
			"Unable to open file: %s" % path)
	
	var file_text: String = file.get_as_text()
	if file_text.strip_edges().length() < 1:
		return Result.err(Error.Code.GUI_TRACKER_FILE_EMPTY,
			"File empty: %s" % path)

	var handlers := _find_handlers()

	if not handlers.has(path.get_extension().to_lower()):
		return Result.err(Error.Code.GUI_TRACKER_UNHANDLED_FILE_FORMAT,
			"No handler found: %s" % path)

	var args := [path, file_text]
	if path.get_extension().to_lower() == "gd":
		args.append(entrypoint)
	
	return callv(handlers[path.get_extension().to_lower()], args)

## Handles gdscript files.
##
## There are 2 types of gdscript files that are handled
## 1. Entrypoint - An entrypoint func is provided that, when called, will return a Node
## 2. No Entrypoint - The entire file describes the node that should be added to the scene
##
## @param: path: String - The file path of the gdscript file
## @param: text: String - The contents of the gdscript file
## @param: entrypoint: String - The entrypoint of the gdscript file, if it exists
## If no entrypoint is given, each property in the script will be parsed instead
##
## @return: Result<Node> - The Node constructed from the data in the file
func _handle_gd(path: String, text: String, entrypoint: String) -> Result:
	var gdscript := GDScript.new()
	gdscript.source_code = text

	if gdscript.reload() != OK:
		return Result.err(Error.Code.GUI_TRACKER_INVALID_GDSCRIPT)

	var instance: Object = gdscript.new()
	
	# e.g.
	# func run() -> Node:
	#	return {
	#		"my_control": my_func_to_generate_control()
	#	}
	if not entrypoint.empty():
		var data = instance.call(entrypoint)
		if typeof(data) == TYPE_NIL or not data is Node:
			return Result.err(Error.Code.GUI_TRACKER_INVALID_DESCRIPTOR,
				"Invalid data type received while handling GDScript: %s - %s" % [str(data), path])

		return Result.ok(data)
	# The file is the actual node
	else:
		if not instance.is_class("Node"):
			return Result.err(Error.Code.GUI_TRACKER_INVALID_GDSCRIPT,
				"Invalid data type received while handling GDScript: %s - %s" % [str(instance), path])

		return Result.ok(instance)

func _handle_json(path: String, text: String) -> Result:
	var json_parse_result := JSON.parse(text)
	if json_parse_result.error != OK:
		return Result.err(Error.Code.GUI_TRACKER_INVALID_JSON, "%s\n%s" %
			[path, json_parse_result.error_description()])

	var data = json_parse_result.result
	if typeof(data) != TYPE_DICTIONARY:
		return Result.err(Error.Code.GUI_TRACKER_INVALID_JSON,
			"%s must be a JSON object" % path)

	if not data.has("type") or not ClassDB.class_exists(data["type"]):
		return Result.err(Error.Code.GUI_TRACKER_INVALID_JSON, str(data))

	var node = ClassDB.instance(data["type"])
	if data.has("name"):
		node.name = data["name"]

	var additional_nodes = data.get("nodes", [])
	if typeof(additional_nodes) != TYPE_ARRAY:
		return Result.err(Error.Code.GUI_TRACKER_INVALID_JSON, str(data))

	for i in additional_nodes:
		if typeof(i) != TYPE_DICTIONARY:
			return Result.err(Error.Code.GUI_TRACKER_INVALID_JSON, str(i))

		var res := _handle_json(path, str(i))
		if res.is_err():
			return res

		node.add_child(res.unwrap())
	
	return Result.ok(node)

#-----------------------------------------------------------------------------#
# Public functions                                                            #
#-----------------------------------------------------------------------------#
