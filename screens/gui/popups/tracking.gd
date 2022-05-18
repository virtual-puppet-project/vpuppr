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

func _handle_descriptor(context: ExtensionContext, path_and_func: String) -> Result:
	var r := {}

	var split := path_and_func.split(":", false, 1)
	var path: String = split[0]
	var entrypoint := split[1] if split.size() > 1 else ""

	match path.get_extension().to_lower():
		"gd":
			var res: Result = context.load_resource(path)
			if not res or res.is_err():
				return res if res else Result.err(Error.Code.RUNNER_LOAD_FILE_FAILED, path)

			# TODO stub
		"json":
			var file := File.new()
			if file.open("%s/%s" % [context.context_path, path], File.OPEN) != OK:
				return Result.err(Error.Code.RUNNER_LOAD_FILE_FAILED, path)

			# TODO stub
		"toml":
			var file := File.new()
			if file.open("%s/%s" % [context.context_path, path], File.OPEN) != OK:
				return Result.err(Error.Code.RUNNER_LOAD_FILE_FAILED, path)

			# TODO stub
		_:
			return Result.err(Error.Code.RUNNER_UNHANDLED_FILE_FORMAT, path)
	
	return Result.ok(r)

#-----------------------------------------------------------------------------#
# Public functions                                                            #
#-----------------------------------------------------------------------------#
