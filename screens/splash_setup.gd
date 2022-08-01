extends CanvasLayer

var viewport: Viewport
var screen_center := Vector2.ZERO
var max_parallax_offset := Vector2.ZERO

var background: TextureRect
var foreground: TextureRect

#-----------------------------------------------------------------------------#
# Builtin functions                                                           #
#-----------------------------------------------------------------------------#

func _ready() -> void:
	OS.window_size = OS.get_screen_size() * 0.75
	OS.center_window()
	
	viewport = get_viewport()
	
	background = $DucksBackground
	foreground = $Foreground
	
	get_tree().connect("screen_resized", self, "_on_screen_resized")
	_on_screen_resized()
	
	$MarginContainer/GitHubButton.connect("pressed", self, "_on_github_button_pressed")
	
	var fade: ColorRect = $Fade
	var fade_tween: Tween = $FadeTween
	fade_tween.connect("tween_all_completed", self, "_on_fade_in_completed", [fade_tween, fade])
	
	fade_tween.interpolate_property(fade, "color", fade.color, Color(0.0, 0.0, 0.0, 0.0), 1.0, Tween.TRANS_LINEAR, Tween.EASE_OUT)
	fade_tween.start()

func _unhandled_input(event: InputEvent) -> void:
	if event is InputEventMouseButton or event is InputEventKey:
		_switch_to_landing_screen()

func _process(delta: float) -> void:
	var mouse_diff: Vector2 = screen_center - viewport.get_mouse_position()
	
	mouse_diff.x = max(-max_parallax_offset.x, min(max_parallax_offset.x, mouse_diff.x))
	mouse_diff.y = max(-max_parallax_offset.y, min(max_parallax_offset.y, mouse_diff.y))
	
	background.rect_position = background.rect_position.linear_interpolate(-mouse_diff, 0.002)
	
	foreground.rect_position = foreground.rect_position.linear_interpolate(mouse_diff, 0.01)

#-----------------------------------------------------------------------------#
# Connections                                                                 #
#-----------------------------------------------------------------------------#

func _on_screen_resized() -> void:
	var screen_size: Vector2 = viewport.size
	
	screen_center = screen_size / 2
	max_parallax_offset = screen_center / 2
	
	background.rect_pivot_offset = background.rect_size / 2
	foreground.rect_pivot_offset = foreground.rect_size / 2

func _on_github_button_pressed() -> void:
	OS.shell_open(Globals.PROJECT_GITHUB_REPO)

func _on_fade_in_completed(fade_tween: Tween, fade: ColorRect) -> void:
	fade_tween.disconnect("tween_all_completed", self, "_on_fade_in_completed")
	fade_tween.connect("tween_all_completed", self, "_on_fade_out_completed")
	
	yield(get_tree().create_timer(2.0), "timeout")
	
	fade_tween.interpolate_property(fade, "color", fade.color, Color.black, 1.0, Tween.TRANS_LINEAR, Tween.EASE_IN)
	fade_tween.start()

func _on_fade_out_completed() -> void:
	_switch_to_landing_screen()

#-----------------------------------------------------------------------------#
# Private functions                                                           #
#-----------------------------------------------------------------------------#

func _switch_to_landing_screen() -> void:
	get_tree().change_scene(Globals.LANDING_SCREEN_PATH)

#-----------------------------------------------------------------------------#
# Public functions                                                            #
#-----------------------------------------------------------------------------#
