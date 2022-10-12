extends PanelContainer

const TWEEN_TIME: float = 1.0
const PAUSE_TIME: float = 3.0

onready var tween: Tween = $Tween
var timer: SceneTreeTimer
var text := ""

#-----------------------------------------------------------------------------#
# Builtin functions                                                           #
#-----------------------------------------------------------------------------#

func _ready() -> void:
	$Label.text = text
	
	connect("gui_input", self, "_on_gui_input")
	
	var window_size := OS.window_size
	rect_global_position.y = window_size.y + rect_size.y
	
	tween.connect("tween_all_completed", self, "_on_toast_visible", [], CONNECT_ONESHOT)
	tween.interpolate_property(
		self,
		"rect_global_position:y",
		rect_global_position.y,
		window_size.y - rect_size.y,
		TWEEN_TIME,
		Tween.TRANS_LINEAR,
		Tween.EASE_IN
	)
	tween.start()

#-----------------------------------------------------------------------------#
# Connections                                                                 #
#-----------------------------------------------------------------------------#

func _on_gui_input(event: InputEvent) -> void:
	if not event is InputEventMouseButton:
		return
	
	if tween.is_connected("tween_all_completed", self, "_on_toast_visible"):
		tween.disconnect("tween_all_completed", self, "_on_toast_visible")
	if timer != null:
		timer.disconnect("timeout", self, "_on_tween_in")
	
	tween.remove_all()
	_on_tween_in()
	
	disconnect("gui_input", self, "_on_gui_input")

func _on_toast_visible() -> void:
	timer = get_tree().create_timer(PAUSE_TIME)
	timer.connect("timeout", self, "_on_tween_in")

func _on_tween_in() -> void:
	tween.connect("tween_all_completed", self, "_on_tween_out", [], CONNECT_ONESHOT)
	tween.interpolate_property(
		self,
		"rect_global_position:y",
		rect_global_position.y,
		OS.window_size.y + rect_size.y,
		TWEEN_TIME,
		Tween.TRANS_LINEAR,
		Tween.EASE_IN
	)
	tween.start()

func _on_tween_out() -> void:
	queue_free()

#-----------------------------------------------------------------------------#
# Private functions                                                           #
#-----------------------------------------------------------------------------#

#-----------------------------------------------------------------------------#
# Public functions                                                            #
#-----------------------------------------------------------------------------#
