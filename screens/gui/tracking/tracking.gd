extends VBoxContainer

class ActiveTracker extends HBoxContainer:
	signal stop_pressed(tracker: AbstractTracker.Trackers)
	
	var tracker_name := ""
	
	func _init(p_parent_logger: Logger, p_tracker_name: String, p_tracker: AbstractTracker.Trackers) -> void:
		size_flags_horizontal = Control.SIZE_EXPAND_FILL
		tracker_name = p_tracker_name
		
		var label := Label.new()
		label.size_flags_horizontal = Control.SIZE_EXPAND_FILL
		label.text = p_tracker_name
		
		var button := Button.new()
		button.size_flags_horizontal = Control.SIZE_EXPAND_FILL
		button.text = &"Stop"
		# TODO move this logic back to the context?
		button.pressed.connect(func() -> void:
			p_parent_logger.info("Stopping tracker {tracker}".format({tracker = tracker_name}))
			
			stop_pressed.emit(p_tracker)
		)
		
		add_child(label)
		add_child(button)

signal message_received(message: GUIMessage)

const TREE_COL: int = 0
const Trackers := AbstractTracker.Trackers

var _logger := Logger.create("Tracking")

@onready
var _active_trackers := %ActiveTrackers
@onready
var _pages := %Pages

#-----------------------------------------------------------------------------#
# Builtin functions
#-----------------------------------------------------------------------------#

func _ready() -> void:
	%StopAll.pressed.connect(func() -> void:
		message_received.emit(GUIMessage.new(self, GUIMessage.TRACKER_STOP_ALL))
	)
	
	for child in _get_tracker_pages():
		if not child.has_signal("started"):
			_logger.error(
				"Tracking GUI tried to process invalid GUI item, missing signal 'started'"
			)
			continue
		if not child.has_signal("property_changed"):
			_logger.error(
				"Tracking GUI tried to process invalid GUI item, missing signal 'property_changed'"
			)
			continue
		
		child.started.connect(func(tracker: Trackers) -> void:
			# TODO you-win (nov 19 2023): setting this field here is not good
			match child.start.text:
				"Start":
					message_received.emit(GUIMessage.new(self, GUIMessage.TRACKER_START, tracker))
					child.start.text = "Stop"
				"Stop":
					message_received.emit(GUIMessage.new(self, GUIMessage.TRACKER_STOP, tracker))
					child.start.text = "Start"
		)
		child.property_changed.connect(func(tracker: Trackers, key: String, value: Variant) -> void:
			var option_name := "common_options:{v}"
			match tracker:
				Trackers.MEDIA_PIPE:
					option_name = option_name.format({v = "mediapipe_options"})
				Trackers.I_FACIAL_MOCAP:
					option_name = option_name.format({v = "ifacial_mocap_options"})
				Trackers.VTUBE_STUDIO:
					option_name = option_name.format({v = "vtube_studio_options"})
				Trackers.MEOW_FACE:
					option_name = option_name.format({v = "meow_face_options"})
				_:
					_logger.error("Unhandled update for {tracker}".format({tracker = tracker}))
					return
			
			message_received.emit(GUIMessage.new(self, GUIMessage.DATA_UPDATE, option_name,
				{
					key = key,
					value = value
				}
			))
		)

#-----------------------------------------------------------------------------#
# Private functions
#-----------------------------------------------------------------------------#

func _get_tracker_pages() -> Array:
	var pages := _pages.get_children()
	# The info page is always first
	pages.pop_front()
	
	return pages

#-----------------------------------------------------------------------------#
# Public functions
#-----------------------------------------------------------------------------#

# TODO you-win (nov 19 2023): clearing all the children every time this is updated sucks
func update(context: Context) -> void:
	for child in _active_trackers.get_children():
		child.queue_free()
	
	var active_tracker_types: Array[AbstractTracker.Trackers] = []
	for tracker in context.active_trackers.values():
		var tracker_type: AbstractTracker.Trackers = tracker.get_type()
		active_tracker_types.push_back(tracker_type)
		
		var active_tracker := ActiveTracker.new(_logger, tracker.get_name(), tracker_type)
		active_tracker.stop_pressed.connect(func(tracker: AbstractTracker.Trackers) -> void:
			message_received.emit(GUIMessage.new(self, GUIMessage.TRACKER_STOP, tracker))
			active_tracker.queue_free()
		)
		
		_active_trackers.add_child(active_tracker)
	
	var opts := context.runner_data.common_options
	# TODO you-win (nov 19 2023): this is horrible
	for child in _get_tracker_pages():
		const Trackers := AbstractTracker.Trackers
		
		var tracker_type: Trackers = child.get_type()
		child.start.text = "Start" if not tracker_type in active_tracker_types else "Stop"
		
		match tracker_type:
			Trackers.I_FACIAL_MOCAP:
				child.port.text = str(opts.ifacial_mocap_options.port)
			Trackers.MEDIA_PIPE:
				pass
			Trackers.MEOW_FACE:
				child.address.text = opts.meow_face_options.address
				child.port.text = str(opts.meow_face_options.port)
			Trackers.VTUBE_STUDIO:
				child.address.text = opts.vtube_studio_options.address
				child.port.text = str(opts.vtube_studio_options.port)
			Trackers.OPEN_SEE_FACE:
				pass
			Trackers.CUSTOM:
				pass
