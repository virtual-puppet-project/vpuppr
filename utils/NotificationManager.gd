extends Node

const MIN_TIME_BETWEEN_DUPLICATE_TOAST: int = 5000 # In milliseconds

const EPHEMERAL_POPUP: PackedScene = preload("res://screens/gui/EphemeralPopup.tscn")
const TOAST: PackedScene = preload("res://screens/gui/Toast.tscn")

var popup_queue: Array = []
var current_popup: CanvasLayer
var has_popup: bool = false

var toast_queue: Array = []
var current_toast: CanvasLayer
var has_toast: bool = false

var last_toast_message: String
var last_toast_timestamp: int

###############################################################################
# Builtin functions                                                           #
###############################################################################

###############################################################################
# Connections                                                                 #
###############################################################################

func _on_popup_closed() -> void:
	has_popup = false
	if not popup_queue.empty():
		_show_popup(popup_queue.pop_front())

func _on_toast_closed() -> void:
	has_toast = false
	if not toast_queue.empty():
		_show_toast(toast_queue.pop_front())

###############################################################################
# Private functions                                                           #
###############################################################################

func _show_popup(text: String) -> void:
	current_popup = EPHEMERAL_POPUP.instance()
	current_popup.popup_text = text
	current_popup.connect("closed", self, "_on_popup_closed")
	
	add_child(current_popup)
	has_popup = true

func _show_toast(text: String) -> void:
	current_toast = TOAST.instance()
	current_toast.label_text = text
	current_toast.connect("closed", self, "_on_toast_closed")
	
	add_child(current_toast)
	has_toast = true

###############################################################################
# Public functions                                                            #
###############################################################################

func show_popup(text: String) -> void:
	if has_popup:
		popup_queue.append(text)
		return
	
	_show_popup(text)

func show_toast(text: String) -> void:
	# Periodically clear the last_toast_message
	var timestamp: int = OS.get_ticks_msec()
	if abs(timestamp - last_toast_timestamp) > MIN_TIME_BETWEEN_DUPLICATE_TOAST:
		last_toast_message = ""
		last_toast_timestamp = timestamp
	
	if text == last_toast_message:
		return
	
	last_toast_message = text
	
	if has_toast:
		toast_queue.append(text)
		return
	
	_show_toast(text)
