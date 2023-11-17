extends PanelContainer

signal clicked()

const HOVER_COLOR := Color(0.08, 0.08, 0.08, 1.0)
const NOT_HOVER_COLOR := Color(0.08, 0.08, 0.08, 0.47)

const FAVORITE_COLOR := Color(1.0, 1.0, 1.0, 1.0)
const NOT_FAVORITE_COLOR := Color(0.5, 0.5, 0.5, 1.0)

## The data this UI element represents.
var data: RunnerData = null

@onready
var _preview: TextureRect = %Preview
@onready
var _favorite: Button = %Favorite
@onready
var _title: Label = %Title
@onready
var _model: Label = %Model
@onready
var _last_used: Label = %LastUsed

#var last_used_datetime: Datetime = null

var _panel: StyleBoxFlat = self.get_indexed("theme_override_styles/panel").duplicate()

#-----------------------------------------------------------------------------#
# Builtin functions
#-----------------------------------------------------------------------------#

func _ready() -> void:
	var logger := Logger.create("RunnerItem:_ready:{0}".format([data.name]))
	if data == null:
		logger.error("Data was null for RunnerItem {0}, aborting ready!".format([self]))
		return
	
	_title.text = data.name
	_model.text = data.model_path.get_file()
	_last_used.text = "{year}/{month}/{day} {hour}:{minute}:{second}".format({
		year = data.last_used.get("year", "unknown"),
		month = data.last_used.get("month","unknown"),
		day = data.last_used.get("day", "unknown"),
		
		hour = data.last_used.get("hour", "unknown"),
		minute = data.last_used.get("minute", "unknown"),
		second = data.last_used.get("second", "unknown")
	})

	self.set_indexed("theme_override_styles/panel", _panel)
	_favorite.toggled.connect(func(state: bool) -> void:
		# TODO add logic for adding favorites to metadata
		if state:
			_favorite.modulate = FAVORITE_COLOR
		else:
			_favorite.modulate = NOT_FAVORITE_COLOR
	)
	
	mouse_entered.connect(func() -> void:
		_panel.bg_color = HOVER_COLOR
	)
	mouse_exited.connect(func() -> void:
		_panel.bg_color = NOT_HOVER_COLOR
	)

func _to_string() -> String:
	return JSON.stringify({
		"favorite": _favorite.button_pressed,
		"title": _title.text,
		"model": _model.text,
		"last_used": _last_used.text
	}, "\t")

func _gui_input(event: InputEvent) -> void:
	if not event is InputEventMouseButton:
		return
	if not event.double_click:
		return
	
	clicked.emit()

#-----------------------------------------------------------------------------#
# Private functions
#-----------------------------------------------------------------------------#

#-----------------------------------------------------------------------------#
# Public functions
#-----------------------------------------------------------------------------#

func init_favorite(is_favorite: bool) -> void:
	_favorite.modulate = FAVORITE_COLOR if is_favorite else NOT_FAVORITE_COLOR
	_favorite.set_pressed_no_signal(is_favorite)

func init_preview(path: String) -> void:
	# var logger_id := "RunnerItem[%s]" % _title.text
	match path.get_extension().to_lower():
		"png", "jpg", "jpeg", "tga", "webp":
			# TODO (Tim Yuen) check if this returns null if loading fails
			var image := Image.load_from_file(path)
			if image == null:
#				Logger.global(logger_id, "File not found %s" % path)
				return
			
			_preview.texture = ImageTexture.create_from_image(image)
		_:
#			Logger.global(logger_id, "Unhandled file type %s" % path)
			
			var image := Image.create(64, 64, false, Image.FORMAT_RGB8)
			_preview.texture = ImageTexture.create_from_image(image)
