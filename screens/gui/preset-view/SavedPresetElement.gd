extends MarginContainer

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
	AppManager.connect("gui_toggle_set", self, "_on_gui_toggle_set")

###############################################################################
# Connections                                                                 #
###############################################################################

func _on_toggle_pressed() -> void:
	AppManager.gui_toggle_set(self.name)

func _on_gui_toggle_set(toggle_name: String) -> void:
	if self.name != toggle_name:
		toggle_button.pressed = false

###############################################################################
# Private functions                                                           #
###############################################################################

###############################################################################
# Public functions                                                            #
###############################################################################


