class_name NotificationManager
extends AbstractManager

const MIN_TIME_BETWEEN_DUPLICATE_TOAST: int = 5000 # In milliseconds

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

func _init() -> void:
	pass

func _setup_logger() -> void:
	logger = Logger.new("NotificationManager")

###############################################################################
# Connections                                                                 #
###############################################################################

func _on_popup_closed() -> void:
	# TODO stub
	pass

func _on_toast_closed() -> void:
	# TODO stub
	pass

###############################################################################
# Private functions                                                           #
###############################################################################

###############################################################################
# Public functions                                                            #
###############################################################################

func show_popup(text: String) -> void:
	# TODO stub
	pass

func show_toast(text: String) -> void:
	# TODO stub
	pass
