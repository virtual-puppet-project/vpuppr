extends BaseTreeLayout

const INFO_PAGE := "DEFAULT_GUI_TRACKING_INFO_PAGE"

var running_trackers: VBoxContainer
var running_trackers_button_group := ButtonGroup.new()

#-----------------------------------------------------------------------------#
# Builtin functions                                                           #
#-----------------------------------------------------------------------------#

func _setup_logger() -> void:
	logger = Logger.new("Tracking")

func _setup() -> Result:
	AM.ps.subscribe(self, Globals.EVENT_PUBLISHED)

	var info := get_node(INFO_PAGE) as ScrollContainer
	_set_tree($Tree)
	
	running_trackers = info.get_node("VBoxContainer/RunningTrackers")
	
	_initial_page = tr(INFO_PAGE)

	tree.hide_root = true
	var root: TreeItem = tree.create_item()

	var info_item: TreeItem = tree.create_item(root)
	info_item.set_text(TREE_COLUMN, _initial_page)
	info_item.select(TREE_COLUMN)

	pages[_initial_page] = Page.new(info, info_item)
	
	_toggle_page(_initial_page)

	tree.connect("item_selected", self, "_on_item_selected")

	for er in AM.em.query_extensions_for_tag(Globals.ExtensionTypes.TRACKER):
		er = er as Extension.ExtensionResource
		if not er.extra.has(ExtensionManager.ResourceKeys.Extra.GUI):
			logger.error("Extension %s missing gui, skipping" % er.resource_name)
			continue

#		var res: Result = Safely.wrap(AM.em.get_context(er.extension_name))
		# # TODO just grab the extension directly?
		var res: Result = Safely.wrap(AM.em.get_extension(er.extension_name))
		if res.is_err():
			logger.err(res)
			continue

		var entrypoint: String = er.extra[ExtensionManager.ResourceKeys.Extra.GUI]

		res = Safely.wrap(_from_descriptor(res.unwrap().context, entrypoint))
		if res.is_err():
			logger.error(res)
			continue

		var item: TreeItem = tree.create_item(root)
		item.set_text(TREE_COLUMN, tr(er.translation_key))

		var display = res.unwrap()
		pages[tr(er.translation_key)] = Page.new(display, item)
		display.hide()

		add_child(display)
	
	return Safely.ok()

#-----------------------------------------------------------------------------#
# Connections                                                                 #
#-----------------------------------------------------------------------------#

func _on_event_published(payload: SignalPayload) -> void:
	match payload.signal_name:
		Globals.TRACKER_TOGGLED:
			if payload.data == true:
				var tracker_info := _create_tracker_info(payload.id, running_trackers.get_child_count() < 1)

				running_trackers.add_child(tracker_info)
			else:
				for child in running_trackers.get_children():
					if child.name == payload.id:
						child.queue_free()

#region Tracker info

func _on_tracker_info_main_tracker_toggled(state: bool, tracker_name: String) -> void:
	if state == false:
		return
	AM.ps.publish(Globals.TRACKER_USE_AS_MAIN_TRACKER, tracker_name)

func _on_tracker_info_reordered(tracker_name: String, is_up: bool) -> void:
	var child_count := running_trackers.get_child_count()

	var node: Node
	var current_position: int = -1
	for idx in child_count:
		var child: Node = running_trackers.get_child(idx)
		if child.name == tracker_name:
			node = child
			current_position = idx
			break

	if current_position < 0:
		logger.error("Unable to find tracker %s to reorder" % tracker_name)
		return

	var new_position: int = current_position - 1 if is_up else current_position + 1
	if new_position < 0 or new_position >= child_count:
		logger.info("Cannot move tracker to position %d" % new_position)
		return

	running_trackers.move_child(node, new_position)
	AM.ps.publish(Globals.TRACKER_INFO_REORDERED, new_position, tracker_name)

#endregion

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
func _from_descriptor(context: String, path_and_func: String) -> Result:
	var split := path_and_func.split(":", false, 1)
	var path: String = split[0]
	var entrypoint := split[1] if split.size() > 1 else ""
	
	var file := File.new()
	if file.open("%s/%s" % [context, path], File.READ) != OK:
		return Safely.err(Error.Code.GUI_TRACKER_LOAD_FILE_FAILED,
			"Unable to open file: %s" % path)
	
	var file_text: String = file.get_as_text()
	if file_text.strip_edges().length() < 1:
		return Safely.err(Error.Code.GUI_TRACKER_FILE_EMPTY,
			"File empty: %s" % path)

	var handlers := _find_handlers()

	if not handlers.has(path.get_extension().to_lower()):
		return Safely.err(Error.Code.GUI_TRACKER_UNHANDLED_FILE_FORMAT,
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
		return Safely.err(Error.Code.GUI_TRACKER_INVALID_GDSCRIPT)

	var instance: Object = gdscript.new()
	
	# e.g.
	# func run() -> Node:
	#	return {
	#		"my_control": my_func_to_generate_control()
	#	}
	if not entrypoint.empty():
		var data = instance.call(entrypoint)
		if typeof(data) == TYPE_NIL or not data is Node:
			return Safely.err(Error.Code.GUI_TRACKER_INVALID_DESCRIPTOR,
				"Invalid data type received while handling GDScript: %s - %s" % [str(data), path])

		return Safely.ok(data)
	# The file is the actual node
	else:
		if not instance.is_class("Node"):
			return Safely.err(Error.Code.GUI_TRACKER_INVALID_GDSCRIPT,
				"Invalid data type received while handling GDScript: %s - %s" % [str(instance), path])

		return Safely.ok(instance)

func _handle_json(path: String, text: String) -> Result:
	var json_parse_result := JSON.parse(text)
	if json_parse_result.error != OK:
		return Safely.err(Error.Code.GUI_TRACKER_INVALID_JSON, "%s\n%s" %
			[path, json_parse_result.error_description()])

	var data = json_parse_result.result
	if typeof(data) != TYPE_DICTIONARY:
		return Safely.err(Error.Code.GUI_TRACKER_INVALID_JSON,
			"%s must be a JSON object" % path)

	if not data.has("type") or not ClassDB.class_exists(data["type"]):
		return Safely.err(Error.Code.GUI_TRACKER_INVALID_JSON, str(data))

	var node = ClassDB.instance(data["type"])
	if data.has("name"):
		node.name = data["name"]

	var additional_nodes = data.get("nodes", [])
	if typeof(additional_nodes) != TYPE_ARRAY:
		return Safely.err(Error.Code.GUI_TRACKER_INVALID_JSON, str(data))

	for i in additional_nodes:
		if typeof(i) != TYPE_DICTIONARY:
			return Safely.err(Error.Code.GUI_TRACKER_INVALID_JSON, str(i))

		var res := _handle_json(path, str(i))
		if res.is_err():
			return res

		node.add_child(res.unwrap())
	
	return Safely.ok(node)

func _create_tracker_info(tracker_name: String, use_for_offsets: bool) -> HBoxContainer:
	var hbox := HBoxContainer.new()
	hbox.name = tracker_name

	var label := Label.new()
	label.text = tracker_name
	label.size_flags_horizontal = Control.SIZE_EXPAND_FILL

	hbox.add_child(label)

	var toggle_button := CheckButton.new()
	toggle_button.text = tr("DEFAULT_GUI_TRACKING_MAIN_TRACKER")
	toggle_button.group = running_trackers_button_group
	toggle_button.connect("toggled", self, "_on_tracker_info_main_tracker_toggled", [tracker_name])
	toggle_button.pressed = use_for_offsets

	hbox.add_child(toggle_button)

	var vbox := VBoxContainer.new()

	hbox.add_child(vbox)

	var up_button := Button.new()
	up_button.text = "^"
	up_button.connect("pressed", self, "_on_tracker_info_reordered", [tracker_name, true])

	vbox.add_child(up_button)

	var down_button := Button.new()
	down_button.text = "v"
	down_button.connect("pressed", self, "_on_tracker_info_reordered", [tracker_name, false])

	vbox.add_child(down_button)

	return hbox

#-----------------------------------------------------------------------------#
# Public functions                                                            #
#-----------------------------------------------------------------------------#
