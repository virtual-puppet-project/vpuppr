extends BasePopupTreeLayout

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
	pages[INFO_PAGE] = info

	_initial_page = INFO_PAGE

	tree.hide_root = true
	var root: TreeItem = tree.create_item()

	var info_item: TreeItem = tree.create_item(root)
	info_item.set_text(TREE_COLUMN, INFO_PAGE)
	info_item.select(TREE_COLUMN)
	_toggle_page(INFO_PAGE)

	tree.connect("item_selected", self, "_on_item_selected")

	# All running trackers are managed by the current runner
	var runner: RunnerTrait = get_tree().current_scene

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

		var descriptor_res: Result = _handle_descriptor(context_res.unwrap(), entrypoint)
		if not descriptor_res or descriptor_res.is_err():
			logger.err(context_res.unwrap_err().to_string() if descriptor_res else
				"Unable to process descriptor for %s" % er.resource_name)
			continue

		var item: TreeItem = tree.create_item(root)
		item.set_text(TREE_COLUMN, er.resource_name)

		var tracking_display := TrackingDisplay.new(er.resource_name, descriptor_res.unwrap(), logger)
		pages[er.resource_name] = tracking_display

		add_child(tracking_display)

#-----------------------------------------------------------------------------#
# Connections                                                                 #
#-----------------------------------------------------------------------------#

#-----------------------------------------------------------------------------#
# Private functions                                                           #
#-----------------------------------------------------------------------------#

# TODO this needs to change for gdscript files to return a node instead of a dictionary
## @return: Result<Dictionary<String, Node>> - The UI parsed from the descriptor
static func _handle_descriptor(context: ExtensionContext, path_and_func: String) -> Result:
	var r := {}

	var split := path_and_func.split(":", false, 1)
	var path: String = split[0]
	var entrypoint := split[1] if split.size() > 1 else ""
	
	var file := File.new()
	if file.open("%s/%s" % [context.context_path, path], File.READ) != OK:
		return Result.err(Error.Code.GUI_TRACKER_LOAD_FILE_FAILED, path)
	
	var file_text: String = file.get_as_text()
	if file_text.strip_edges().length() < 1:
		return Result.err(Error.Code.GUI_TRACKER_FILE_EMPTY, path)

	match path.get_extension().to_lower():
		"gd":
			var gdscript := GDScript.new()
			gdscript.source_code = file_text
			
			if gdscript.reload() != OK:
				return Result.err(Error.Code.GUI_TRACKER_INVALID_GDSCRIPT, path)

			var instance: Object = gdscript.new()

			r["name"] = instance.get("name")
			if r["name"].empty():
				r["name"] = path.get_basename().get_file()

			# e.g.
			# func run() -> Dictionary:
			#	return {
			#		"my_control": my_func_to_generate_control()
			#	}
			if not entrypoint.empty():
				var data = instance.call(entrypoint)
				if typeof(data) != TYPE_DICTIONARY:
					return Result.err(Error.Code.GUI_TRACKER_INVALID_DESCRIPTOR, path)

				r = data
			# e.g.
			# var my_control = my_func_to_generate_control()
			else:
				if not instance.is_class("Reference") or instance.is_class("Node"):
					return Result.err(Error.Code.GUI_TRACKER_INVALID_DESCRIPTOR, path)
				
				for prop in instance.get_property_list():
					if prop.name in GlobalConstants.IGNORED_PROPERTIES_REFERENCE:
						continue

					# This MUST inherit from Node
					var val = instance.get(prop.name)
					if not val.is_class("Node"):
						# Cleanup files first
						for key in r.keys():
							r[key].free()
						r.clear()

						return Result.err(Error.Code.GUI_TRACKER_INVALID_DESCRIPTOR, "%s - %s" %
							[path, prop.name])

					r[prop.name] = val
		"json":
			var json_parse_result := JSON.parse(file_text)
			if json_parse_result.error != OK:
				return Result.err(Error.Code.GUI_TRACKER_INVALID_JSON, "%s\n%s" %
					[path, json_parse_result.error_description()])
			
			var json_data = json_parse_result.result
			if typeof(json_data) != TYPE_DICTIONARY:
				return Result.err(Error.Code.GUI_TRACKER_INVALID_JSON, "%s must be a JSON object" % path)

			var res := _handle_json(json_data)
		"toml":
			# TODO stub
			pass
		_:
			return Result.err(Error.Code.GUI_TRACKER_UNHANDLED_FILE_FORMAT, path)
	
	return Result.ok(r)

static func _handle_json(data: Dictionary) -> Result:
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

		var res := _handle_json(i)
		if res.is_err():
			return res

		node.add_child(res.unwrap())
	
	return Result.ok(node)

#-----------------------------------------------------------------------------#
# Public functions                                                            #
#-----------------------------------------------------------------------------#
