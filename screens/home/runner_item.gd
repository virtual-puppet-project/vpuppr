extends PanelContainer

signal clicked()

const HOVER_COLOR := Color(0.08, 0.08, 0.08, 1.0)
const NOT_HOVER_COLOR := Color(0.08, 0.08, 0.08, 0.47)

const FAVORITE_COLOR := Color(1.0, 1.0, 1.0, 1.0)
const NOT_FAVORITE_COLOR := Color(0.5, 0.5, 0.5, 1.0)

@onready
var preview: TextureRect = %Preview
@onready
var favorite: Button = %Favorite
@onready
var title: Label = %Title
@onready
var model: Label = %Model
@onready
var last_used: Label = %LastUsed

var last_used_datetime: Datetime = null

var _panel: StyleBoxFlat = self.get_indexed("theme_override_styles/panel").duplicate()

#-----------------------------------------------------------------------------#
# Builtin functions
#-----------------------------------------------------------------------------#

func _ready() -> void:
	self.set_indexed("theme_override_styles/panel", _panel)
	favorite.toggled.connect(func(state: bool) -> void:
		# TODO add logic for adding favorites to metadata
		if state:
			favorite.modulate = FAVORITE_COLOR
		else:
			favorite.modulate = NOT_FAVORITE_COLOR
	)
	
	mouse_entered.connect(func() -> void:
		_panel.bg_color = HOVER_COLOR
	)
	mouse_exited.connect(func() -> void:
		_panel.bg_color = NOT_HOVER_COLOR
	)

func _to_string() -> String:
	return JSON.stringify({
		"favorite": favorite.button_pressed,
		"title": title.text,
		"model": model.text,
		"last_used": last_used.text
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
	favorite.modulate = FAVORITE_COLOR if is_favorite else NOT_FAVORITE_COLOR
	favorite.set_pressed_no_signal(is_favorite)

func init_preview(path: String) -> void:
	var logger_id := "RunnerItem[%s]" % title.text
	match path.get_extension().to_lower():
		"png", "jpg", "jpeg", "tga", "webp":
			# TODO (Tim Yuen) check if this returns null if loading fails
			var image := Image.load_from_file(path)
			if image == null:
				Logger.global(logger_id, "File not found %s" % path)
				return
			
			preview.texture = ImageTexture.create_from_image(image)
		_:
			Logger.global(logger_id, "Unhandled file type %s" % path)
			
			var image := Image.create(64, 64, false, Image.FORMAT_RGB8)
			preview.texture = ImageTexture.create_from_image(image)
