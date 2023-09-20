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
	
	var pages := %Pages.get_children()
	# The info page is always first
	pages.pop_front()
	for child in pages:
		if not child.has_signal("started"):
			_logger.error(
				"Tracking GUI tried to process invalid GUI item, missing signal 'started'")
			continue
		
		# TODO move more logic back to the context
		child.started.connect(func(tracker: Trackers, data: Dictionary) -> void:
			var tracker_ref = context.start_tracker(tracker, data)
			if tracker_ref == null:
				_logger.error("Unable to start tracker")
				return
			
			_active_trackers.add_child(ActiveTracker.new(context, _logger, tracker_ref))
		)

#-----------------------------------------------------------------------------#
# Private functions
#-----------------------------------------------------------------------------#

#-----------------------------------------------------------------------------#
# Public functions
#-----------------------------------------------------------------------------#

