extends VBoxContainer

class ActiveTracker extends HBoxContainer:
	func _init(context: Context, parent_logger: Logger, tracker: AbstractTracker) -> void:
		size_flags_horizontal = Control.SIZE_EXPAND_FILL
		
		var label := Label.new()
		label.size_flags_horizontal = Control.SIZE_EXPAND_FILL
		label.text = tracker.get_name()
		
		var button := Button.new()
		button.size_flags_horizontal = Control.SIZE_EXPAND_FILL
		button.text = &"Stop"
		# TODO move this logic back to the context?
		button.pressed.connect(func() -> void:
			if tracker.stop() != OK:
				parent_logger.error("Unable to stop tracker {0}".format([tracker.get_name()]))
				return
			
			context.active_trackers.erase(tracker)
			queue_free()
		)
		
		add_child(label)
		add_child(button)

const TREE_COL: int = 0

const Trackers := AbstractTracker.Trackers

var context: Context = null

var _logger := Logger.create("Tracking")

var _trackers := {}
@onready
var _active_trackers := %ActiveTrackers

#-----------------------------------------------------------------------------#
# Builtin functions
#-----------------------------------------------------------------------------#

func _ready() -> void:
	if context == null:
		_logger.error("Context was not set, bailing out")
		return
	
	for t in context.active_trackers:
		_active_trackers.add_child(ActiveTracker.new(context, _logger, t))
	
	ready.connect(func() -> void:
		await get_tree().process_frame
		await get_tree().process_frame
		$HSplitContainer.split_offset = get_window().size.x * 0.15
	)
	
	%StopAll.pressed.connect(func() -> void:
		var stopped_trackers := []
		for tracker in context.active_trackers:
			if tracker.stop() != OK:
				_logger.error("Unable to stop tracker {0}".format([tracker.get_name()]))
				continue
			stopped_trackers.push_back(tracker)
		
		for tracker in stopped_trackers:
			context.active_trackers.erase(tracker)
		
		if not context.active_trackers.is_empty():
			_logger.error("Unable to stop all trackers")
	)
	
	var tree := %Tree as Tree
	var root: TreeItem = tree.create_item()
	
	var info_ti := tree.create_item(root)
	info_ti.set_text(TREE_COL, &"Info")
	_trackers[&"Info"] = %Info
	
	for child in %Trackers.get_children():
		if child.name == &"Info":
			continue
		if not child is TrackingGui:
			_logger.error("Tracking GUI tried to process invalid GUI item")
			continue
		
		var ti := tree.create_item(root)
		ti.set_text(TREE_COL, child.name)
		
		_trackers[child.name] = child
		
		# TODO move more logic back to the context
		child.started.connect(func(tracker: Trackers, data: Dictionary) -> void:
			var tracker_ref = context.start_tracker(tracker, data)
			if tracker_ref == null:
				_logger.error("Unable to start tracker")
				return
			
			_active_trackers.add_child(ActiveTracker.new(context, _logger, tracker_ref))
		)
	
	tree.item_selected.connect(func() -> void:
		for i in _trackers.values():
			i.hide()
		
		_trackers[tree.get_selected().get_text(TREE_COL)].show()
	)
	tree.set_selected(info_ti, TREE_COL)

#-----------------------------------------------------------------------------#
# Private functions
#-----------------------------------------------------------------------------#

#-----------------------------------------------------------------------------#
# Public functions
#-----------------------------------------------------------------------------#

