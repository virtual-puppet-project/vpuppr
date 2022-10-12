class_name NotificationManager
extends AbstractManager

const NOTIFICATION_NODE_NAME := "NotificationManagerToastNode"
const NOTIFICATION_NODE_LAYER: int = 100
const MIN_TIME_BETWEEN_DUPLICATE_TOAST: int = 5000 # In milliseconds

const NotificationPopup: PackedScene = preload("res://screens/gui/notification_popup.tscn")
const NotificationToast: PackedScene = preload("res://screens/gui/notification_toast.tscn")

class PopupData:
	var text := ""
	var window_title := ""
	var caller: Object = null
	var callback := ""

	func _init(p_text: String, p_window_title: String, p_caller: Object = null, p_callback: String = "") -> void:
		text = p_text
		window_title = p_window_title
		caller = p_caller
		callback = p_callback

# Array<PopupData>
var popup_queue: Array = []
var has_popup: bool = false

var toast_queue: Array = []
var has_toast: bool = false

var last_toast_message: String
var last_toast_timestamp: int

var notification_node: CanvasLayer

#-----------------------------------------------------------------------------#
# Builtin functions                                                           #
#-----------------------------------------------------------------------------#

func _init() -> void:
	pass

func _setup_logger() -> void:
	logger = Logger.new("NotificationManager")

func _setup_class() -> void:
	yield(AM, "ready")

	notification_node = CanvasLayer.new()
	notification_node.layer = NOTIFICATION_NODE_LAYER
	notification_node.name = NOTIFICATION_NODE_NAME
	AM.add_child(notification_node)

#-----------------------------------------------------------------------------#
# Connections                                                                 #
#-----------------------------------------------------------------------------#

func _on_popup_closed() -> void:
	if popup_queue.size() > 0:
		var data: PopupData = popup_queue.pop_front()
		_show_popup(data.text, data.window_title, data.caller, data.callback)
	else:
		has_popup = false

func _on_toast_closed() -> void:
	if toast_queue.size() > 0:
		_show_toast(toast_queue.pop_front())
	else:
		has_toast = false

#-----------------------------------------------------------------------------#
# Private functions                                                           #
#-----------------------------------------------------------------------------#

func _show_popup(text: String, window_title: String, caller: Object = null, callback: String = "") -> void:
	has_popup = true

	var popup: WindowDialog = _create_popup(text, window_title) if caller == null else _create_confirmation(
		text, window_title, caller, callback)
	notification_node.add_child(popup)
	popup.connect("tree_exited", self, "_on_popup_closed")

func _show_toast(text: String) -> void:
	has_toast = true

	var toast := _create_toast(text)
	toast.connect("tree_exited", self, "_on_toast_closed")
	notification_node.add_child(toast)

static func _create_popup(text: String, window_title: String) -> WindowDialog:
	var r: WindowDialog = NotificationPopup.instance()
	r.text = text
	r.window_title = window_title

	return r

static func _create_confirmation(
		text: String, window_title: String, caller: Object, callback: String) -> WindowDialog:
	var r: WindowDialog = NotificationPopup.instance()
	r.text = text
	r.window_title = window_title
	r.on_choice_selected(caller, callback)

	return r

static func _create_toast(text: String) -> Control:
	var r: Control = NotificationToast.instance()
	r.text = text

	return r

#-----------------------------------------------------------------------------#
# Public functions                                                            #
#-----------------------------------------------------------------------------#

func show_popup(text: String, window_title: String = "") -> void:
	if window_title.empty():
		window_title = tr("NOTIFICATION_POPUP_DEFAULT_NOTIFICATION")
	
	if has_popup:
		popup_queue.push_back(PopupData.new(text, window_title))
	else:
		_show_popup(text, window_title)

func show_confirmation(text: String, window_title: String, caller: Object, callback: String) -> void:
	if has_popup:
		popup_queue.push_back(PopupData.new(text, window_title, caller, callback))
	else:
		_show_popup(text, window_title, caller, callback)

func show_toast(text: String) -> void:
	var current_timestamp := OS.get_ticks_msec()

	if last_toast_message == text and current_timestamp - last_toast_timestamp < MIN_TIME_BETWEEN_DUPLICATE_TOAST:
		return
	
	last_toast_message = text
	last_toast_timestamp = current_timestamp

	if has_toast:
		toast_queue.push_back(text)
	else:
		_show_toast(text)
