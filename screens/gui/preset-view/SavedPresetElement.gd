extends MarginContainer

const PRESET_VIEW_NAME: String = "PresetView"

onready var screenshot_display: TextureRect = $MarginContainer/HBoxContainer/HBoxContainer/ScreenshotDisplay
onready var upper: Label = $MarginContainer/HBoxContainer/HBoxContainer/VBoxContainer/Upper
onready var lower: Label = $MarginContainer/HBoxContainer/HBoxContainer/VBoxContainer/Lower

onready var toggle_button: CheckButton = $MarginContainer/HBoxContainer/ToggleButton

var screenshot_buffer_data: PoolByteArray
var upper_text: String
var lower_text: String

###############################################################################
# Builtin functions                                                           #
###############################################################################

func _ready() -> void:
	# Courtesy null checks
	if screenshot_buffer_data:
		var image: Image = Image.new()
		image.load_png_from_buffer(screenshot_buffer_data)
		var texture: ImageTexture = ImageTexture.new()
		texture.create_from_image(image)
		screenshot_display.texture = texture
	if upper_text:
		upper.text = upper_text
	if lower_text:
		lower.text = lower_text

	toggle_button.connect("pressed", self, "_on_toggle_pressed")

###############################################################################
# Connections                                                                 #
###############################################################################

func _on_toggle_pressed() -> void:
	AppManager.gui_toggle_set(self.name, PRESET_VIEW_NAME)

###############################################################################
# Private functions                                                           #
###############################################################################

###############################################################################
# Public functions                                                            #
###############################################################################


