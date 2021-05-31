class_name PresetView
extends BaseView

const INPUT_BUTTON: Resource = preload("res://screens/gui/preset-view/InputButton.tscn")
const SAVED_PRESET_ELEMENT: Resource = preload("res://screens/gui/preset-view/SavedPresetElement.tscn")
const PRESET_INFO_DISPLAY: Resource = preload("res://screens/gui/preset-view/PresetInfoDisplay.tscn")

const LAST_MODIFIED_TIME: String = "last_modified_time"

var presets: Dictionary = {}

var input_button: MarginContainer

###############################################################################
# Builtin functions                                                           #
###############################################################################

func _ready() -> void:
	_setup()

###############################################################################
# Connections                                                                 #
###############################################################################

func _on_apply_button_pressed() -> void:
	pass

func _on_reset_button_pressed() -> void:
	pass

func _on_save_button_pressed() -> void:
	if input_button.line_edit.text.empty():
		AppManager.log_message("Preset name cannot be empty")
		return

	var current_config: Dictionary = {}

	var gui_layer = get_parent()
	current_config[gui_layer.model_view.name] = gui_layer.model_view.save()
	current_config[gui_layer.pose_view.name] = gui_layer.pose_view.save()
	current_config[gui_layer.feature_view.name] = gui_layer.feature_view.save()
	current_config[LAST_MODIFIED_TIME] = OS.get_datetime()
	
	presets[input_button.line_edit.text] = current_config

	AppManager.update_config(self.name, presets)
	AppManager.save_config()
	
	yield(get_tree(), "idle_frame")

	_setup_left(presets)

func _on_load_button_pressed() -> void:
	pass

func _on_gui_toggle_set(toggle_name: String) -> void:
	# Courtesy null check
	if presets.has(toggle_name):
		_create_preset_info_display(toggle_name, presets[toggle_name])
	else:
		AppManager.log_message("ToggleLabel %s not found in %s" % [toggle_name, self.name])

###############################################################################
# Private functions                                                           #
###############################################################################

func _setup_left(config: Dictionary) -> void:
	left_container.clear_children()

	if not AppManager.is_connected("gui_toggle_set", self, "_on_gui_toggle_set"):
		AppManager.connect("gui_toggle_set", self, "_on_gui_toggle_set")
	
	if not config.empty():
		presets = config.duplicate(true)
		
		for preset_name in presets.keys():
			var preset_element: MarginContainer = SAVED_PRESET_ELEMENT.instance()
			preset_element.name = preset_name
			preset_element.upper_text = preset_name
			var lmt: Dictionary = presets[preset_name][LAST_MODIFIED_TIME]
			preset_element.lower_text = "%s-%s-%s_%s:%s:%s" % [
				lmt["year"], lmt["month"], lmt["day"],
				lmt["hour"], lmt["minute"], lmt["second"]
			]
			left_container.call_deferred("add_to_inner", preset_element)

	if not left_container.outer.get_node_or_null("saved_presets"):
		left_container.add_to_outer(_create_element(ElementType.LABEL, "saved_presets",
				"Saved Presets"), 0)
		
		input_button = INPUT_BUTTON.instance()
		left_container.add_to_outer(input_button, 1)
		input_button.save_button.connect("pressed", self, "_on_save_button_pressed")

func _setup_right(_config: Dictionary) -> void:
	right_container.clear_children()

func _create_preset_info_display(toggle_name, data) -> void:
	var preset_info_display: MarginContainer = PRESET_INFO_DISPLAY.instance()
	right_container.add_to_inner(preset_info_display)
	

###############################################################################
# Public functions                                                            #
###############################################################################

func save() -> Dictionary:
	_setup()
	return presets
