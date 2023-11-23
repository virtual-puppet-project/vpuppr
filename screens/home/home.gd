extends CanvasLayer

const RunnerItem: PackedScene = preload("res://screens/home/runner_item.tscn")
const NewRunner: PackedScene = preload("res://screens/home/new_runner.tscn")

const LOGO_TWEEN_TIME: float = 1.5
const START_RUNNER_TWEEN_TIME: float = 0.5
const CLEAR_COLOR := Color("00000000")

const SortDirection := {
	"ASCENDING": "Ascending",
	"DESCENDING": "Descending"
}

var _logger := Logger.create("Home")

var _max_parallax_offset := Vector2(32.0, 18.0)

@onready
var _viewport: Viewport = get_viewport()
@onready
var _screen_center: Vector2 = _viewport.size / 2.0

@onready
var _fade: ColorRect = %Fade
@onready
var _ducks_background: TextureRect = %DucksBackground
@onready
var _duck: TextureRect = %Duck
@onready
var _logo: TextureRect = %Logo
@onready
var _sub_logo: TextureRect = %SubLogo

@onready
var _parallax_elements: Array[TextureRect] = [
	_ducks_background,
	_duck,
	_logo,
	_sub_logo
]
## Initial positions for all parallax elements.
## [br][br]
## TextureRect -> Vector2
var _parallax_initial_positions := {}

@onready
var _runner_container: PanelContainer = %RunnerContainer
@onready
var _runners: VBoxContainer = %Runners

var _last_sort_type: int = 0
## Needed so sorted can be un-reversed. Starts at 0 so everything is sorted as ascending to start.
var _last_last_sort_type: int = 0

var _settings_popup: Window = null

#-----------------------------------------------------------------------------#
# Builtin functions
#-----------------------------------------------------------------------------#

func _ready() -> void:
	_logger.debug("starting ready!")
	
	_adapt_screen_size()
	
	var handle_popup_hide := func(node: Node) -> void:
		node.queue_free()
	
	%NewRunner.pressed.connect(func() -> void:
		var popup := PopupWindow.new("New Runner", NewRunner.instantiate())

		add_child(popup)
		popup.popup_centered_ratio(0.5)
		
		var data: Variant = await popup.close_requested
		if data == null:
			return
		if not data is RunnerData:
			_logger.error(
				"New runner popup returned someting that wasn't a RunnerData {0}".format([data]))
			return
		
		if data.try_save() != OK:
			_logger.error("Unable to save RunnerData, this is a major bug!")
		
		_run_from_data(data)
	)
#	%Settings.pressed.connect(func() -> void:
#		# Reuse the old settings popup
#		if _settings_popup != null:
#			_settings_popup.move_to_foreground()
#			return
#
#		_settings_popup = Window.new()
#		_settings_popup.title = "VPupPr Settings"
#
#		var settings := Settings.instantiate()
#		_settings_popup.add_child(settings)
#
#		add_child(_settings_popup)
#		_settings_popup.popup_centered_ratio(0.5)
#
#		var settings_hide := handle_popup_hide.bind(_settings_popup)
#		_settings_popup.visibility_changed.connect(settings_hide)
#		_settings_popup.close_requested.connect(settings_hide)
#	)
	var sort_direction: Button = %SortDirection
	var sort_runners_popup: PopupMenu = %SortRunners.get_popup()
	sort_runners_popup.index_pressed.connect(func(idx: int) -> void:
		var reversed := idx == _last_sort_type
		if _last_sort_type == _last_last_sort_type:
			_last_last_sort_type = -1
			reversed = false
		else:
			_last_last_sort_type = _last_sort_type
		_last_sort_type = idx

		var children := _runners.get_children()
		for c in children:
			_runners.remove_child(c)

		match idx:
			0: # Last used
				children.sort_custom(func(a: Control, b: Control) -> bool:
					var dt_a: Dictionary = a.runner_data.last_used_datetime
					var dt_b: Dictionary = b.runner_data.last_used_datetime

					return (
						dt_a.year < dt_b.year or
						dt_a.month < dt_b.month or
						dt_a.day < dt_b.day or
						dt_a.hour < dt_b.hour or
						dt_a.minute < dt_b.minute or
						dt_a.second < dt_b.second
					)
				)
			1: # Name
				var titles: Array[String] = []
				children.sort_custom(func(a: Control, b: Control) -> bool:
					titles.clear()
					
					var a_title: String = a.title.text
					var b_title: String = b.title.text
					
					# Empty values displayed first
					if a_title.is_empty() or b_title.is_empty() or a_title == b_title:
						return false

					titles = [a.title.text, b.title.text]
					titles.sort()

					return titles.back() == b.title.text
				)

		if reversed:
			children.reverse()
			sort_direction.text = SortDirection.DESCENDING
		else:
			sort_direction.text = SortDirection.ASCENDING

		for c in children:
			_runners.add_child(c)
	)
	sort_direction.pressed.connect(func() -> void:
		# Basically virtually press the last option again, resulting in it being reversed
		_last_last_sort_type = -1 if _last_last_sort_type != _last_sort_type else _last_sort_type
		sort_runners_popup.index_pressed.emit(_last_sort_type)
	)
	
	var init_runners_thread := Thread.new()
	init_runners_thread.start(func() -> void:
		var dir := DirAccess.open("user://")
		if dir == null:
			_logger.error("Unable to open user directory, save data won't be loaded")
			return
		
		dir.list_dir_begin()
		
		var file_name := dir.get_next()
		while not file_name.is_empty():
			if dir.current_is_dir():
				_logger.debug("Skipping directory {file_name}".format({file_name = file_name}))
				
				file_name = dir.get_next()
				continue
			if not file_name.ends_with("tres"):
				_logger.debug("Skipping file {file_name}".format({file_name = file_name}))
				
				file_name = dir.get_next()
				continue
			
			var file_path := "user://{file_name}".format({file_name = file_name})
			
			_logger.debug("Trying to load {file_path}".format({file_path = file_path}))
			
			var runner_data: Resource = load(file_path)
			if runner_data == null or not runner_data is RunnerData:
				_logger.debug("Unable to load {file_path}, skipping".format({file_path = file_path}))
				
				file_name = dir.get_next()
				continue
			
			_logger.debug("Loaded RunnerData from {file_path}".format({file_path = file_path}))
			
			_logger.debug("Creating runner item {data}".format({data = runner_data}))
			call_deferred(&"_create_runner_item", runner_data)
			
			file_name = dir.get_next()
	)
	
	_runner_container.hide()
	
	var logo_anchor: Control = %LogoAnchor
	var sub_logo_anchor: Control = %SubLogoAnchor
	
	var logo_anchor_to_anchor := logo_anchor.anchor_top - 0.2
	var sub_logo_to_anchor := sub_logo_anchor.anchor_top - 0.2
	
	# Needs to be declared early so the various closures can capture it
	var fade_tween := create_tween()
	fade_tween.tween_property(_fade, "color", CLEAR_COLOR, LOGO_TWEEN_TIME)
	
	var movement_tween := create_tween()
	movement_tween.stop()
	movement_tween.set_parallel(true).set_ease(Tween.EASE_IN_OUT).set_trans(Tween.TRANS_QUAD)
	movement_tween.tween_property(logo_anchor, "anchor_top", logo_anchor_to_anchor, LOGO_TWEEN_TIME)
	movement_tween.tween_property(sub_logo_anchor, "anchor_top", sub_logo_to_anchor, LOGO_TWEEN_TIME)
	
	var cancel_intro_fade := func(event: InputEvent) -> void:
		if not event is InputEventMouseButton:
			return
		if not event.pressed:
			return
		
		_fade.color = CLEAR_COLOR
		fade_tween.finished.emit()
		fade_tween.kill()
	
	var cancel_intro_movement := func(event: InputEvent) -> void:
		if not event is InputEventMouseButton:
			return
		if not event.pressed:
			return
		
		logo_anchor.anchor_top = logo_anchor_to_anchor
		sub_logo_anchor.anchor_top = sub_logo_to_anchor
		# Pretend like the tween finished naturally
		movement_tween.finished.emit()
		movement_tween.kill()
	
	_fade.gui_input.connect(cancel_intro_fade)
	
	fade_tween.finished.connect(func() -> void:
		_fade.gui_input.disconnect(cancel_intro_fade)
		_fade.gui_input.connect(cancel_intro_movement)
		movement_tween.play()
	)
	
	movement_tween.finished.connect(func() -> void:
		_runner_container.show()
		_fade.mouse_filter = Control.MOUSE_FILTER_IGNORE
		
		var runner_tween := create_tween()
		runner_tween.tween_property(_runner_container, "modulate", Color.WHITE, LOGO_TWEEN_TIME / 2.0)
		
		_fade.gui_input.disconnect(cancel_intro_movement)
	)
	
	# Initially hidden because otherwise, the entire scene cannot be seen
	_fade.show()
	
	self.ready.connect(func() -> void:
		while init_runners_thread.is_alive():
			await get_tree().process_frame
		init_runners_thread.wait_to_finish()
		init_runners_thread = null
		
		if _runners.get_child_count() < 1:
			var import_model_placeholder := Button.new()
			import_model_placeholder.text = "Import your first model!"
			import_model_placeholder.focus_mode = Control.FOCUS_NONE
			import_model_placeholder.pressed.connect(func() -> void:
				%NewRunner.pressed.emit()
			)
			
			_runners.add_child(import_model_placeholder)

		# TODO reenable
#		sort_runners_popup.index_pressed.emit(0)
	)

func _notification(what: int) -> void:
	match what:
		NOTIFICATION_WM_SIZE_CHANGED:
			_adapt_screen_size()

func _process(_delta: float) -> void:
	var mouse_diff: Vector2 = _screen_center - _viewport.get_mouse_position()
	mouse_diff.x = max(-_max_parallax_offset.x, min(_max_parallax_offset.x, mouse_diff.x))
	mouse_diff.y = max(-_max_parallax_offset.y, min(_max_parallax_offset.y, mouse_diff.y))

	_ducks_background.position = _ducks_background.position.lerp(
		_parallax_initial_positions[_ducks_background] - mouse_diff, 0.0025)

	_duck.position = _duck.position.lerp(_parallax_initial_positions[_duck] + mouse_diff, 0.005)
	_logo.position = _logo.position.lerp(_parallax_initial_positions[_logo] + mouse_diff, 0.005)
	_sub_logo.position = _sub_logo.position.lerp(
		_parallax_initial_positions[_sub_logo] + mouse_diff, 0.005)

#-----------------------------------------------------------------------------#
# Private functions
#-----------------------------------------------------------------------------#

func _adapt_screen_size() -> void:
	var current_screen_size := DisplayServer.screen_get_size(
		DisplayServer.window_get_current_screen())
	var scale_factor := Vector2(abs(current_screen_size / AM.DEFAULT_SCREEN_SIZE))
	
#	_logger.debug("Using scale factor %s" % str(scale_factor))
	
	_max_parallax_offset *= scale_factor
	
	for i in _parallax_elements:
		i.size *= scale_factor
		i.pivot_offset = i.size * 0.5
		i.position = -i.pivot_offset
		
		_parallax_initial_positions[i] = i.position

func _create_runner_item(data: RunnerData) -> void:
	var item := RunnerItem.instantiate()
	item.data = data
	item.clicked.connect(_run_from_data.bind(data, item))

	_runners.add_child(item)

# TODO should this return an [Error]?
## Start a runner from a [RunnerData].
func _run_from_data(data: RunnerData, runner_item: Control = null) -> void:
	if runner_item != null:
		runner_item.clicked.disconnect(_run_from_data)
	
	var context := await Context.new(data)
	var success: Variant = await context.loading_completed
	if runner_item != null and (not success is bool or success != true):
		if context != null:
			context.queue_free()
		runner_item.clicked.connect(_run_from_data.bind(data, runner_item))
		return
	
	var st := get_tree()
	
	var tween := st.create_tween()
	tween.tween_property(_fade, "color", Color.BLACK, START_RUNNER_TWEEN_TIME)
	
	await tween.finished
	
	st.root.add_child(context)
	st.current_scene = context
	
	# TODO (Tim Yuen) weird hack to force the fade effect to continue when the
	# current_scene has changed
	remove_child(_fade)
	var canvas_layer := CanvasLayer.new()
	canvas_layer.add_child(_fade)
	st.root.add_child(canvas_layer)
	
	self.visible = false
	
	tween = st.create_tween()
	tween.tween_property(_fade, "color", CLEAR_COLOR, START_RUNNER_TWEEN_TIME)
	
	await tween.finished
	
	canvas_layer.queue_free()
	
	self.queue_free()

#-----------------------------------------------------------------------------#
# Public functions
#-----------------------------------------------------------------------------#

