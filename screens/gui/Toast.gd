extends CanvasLayer

signal closed

const TOAST_INITIAL_POSITION: float = 1.0
const TOAST_FINAL_POSITION: float = 0.8

const TWEEN_DURATION: float = 1.0

onready var progress_bar: ProgressBar = $Control/PanelContainer/VBoxContainer/ProgressBar
onready var toast: PanelContainer = $Control/PanelContainer
onready var label: Label = $Control/PanelContainer/VBoxContainer/HBoxContainer/PanelContainer/Label
onready var close_button: Button = $Control/PanelContainer/VBoxContainer/HBoxContainer/Close
onready var tween: Tween = $Tween

var label_text: String = ""
var is_closing: bool = false

###############################################################################
# Builtin functions                                                           #
###############################################################################

func _ready() -> void:
	label.text = label_text
	
	close_button.connect("pressed", self, "_on_close")
	
	tween.interpolate_property(toast, "anchor_top", TOAST_INITIAL_POSITION,
			TOAST_FINAL_POSITION, TWEEN_DURATION, Tween.TRANS_CUBIC, Tween.EASE_IN)
	
	tween.start()

func _process(delta: float) -> void:
	if progress_bar.value < progress_bar.max_value:
		progress_bar.value += delta
	elif not is_closing:
		_on_close()
		is_closing = true

###############################################################################
# Connections                                                                 #
###############################################################################

func _on_close() -> void:
	if is_closing:
		return
	is_closing = true
	tween.connect("tween_all_completed", self, "_on_tween_completed")
	tween.interpolate_property(toast, "anchor_top", toast.anchor_top,
			TOAST_INITIAL_POSITION, TWEEN_DURATION, Tween.TRANS_CUBIC, Tween.EASE_IN)
	
	tween.start()

func _on_tween_completed() -> void:
	emit_signal("closed")
	queue_free()

###############################################################################
# Private functions                                                           #
###############################################################################

###############################################################################
# Public functions                                                            #
###############################################################################
