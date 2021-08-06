class_name PresetView
extends BaseView

const INPUT_BUTTON: Resource = preload("res://screens/gui/preset-view/InputButton.tscn")
const SAVED_PRESET_ELEMENT: Resource = preload("res://screens/gui/preset-view/SavedPresetElement.tscn")
const PRESET_INFO_DISPLAY: Resource = preload("res://screens/gui/preset-view/PresetInfoDisplay.tscn")

const LAST_MODIFIED_TIME: String = "last_modified_time"

const PRESET_METADATA_NAME: String = "metadata"
const PRESET_METADATA_TEMPLATE: Dictionary = {
	"name": "",
	"description": "",
	"hotkey": "",
	"notes": "",
	"set_as_default": false
}

# var presets: Dictionary = {} # String: Dictionary
var presets: Array = [] # String

var input_button: MarginContainer

var gui_layer: CanvasLayer

###############################################################################
# Builtin functions                                                           #
###############################################################################

func _ready() -> void:
	gui_layer = get_parent()
	
	_setup()

func _unhandled_input(event: InputEvent) -> void:
	pass

###############################################################################
# Connections                                                                 #
###############################################################################

func _on_apply_button_pressed() -> void:
	pass

func _on_reset_button_pressed() -> void:
	pass

func _on_save_new_preset() -> void:
	if input_button.line_edit.text.empty():
		AppManager.log_message("Preset name cannot be empty")
		return
	
	var preset_name: String = input_button.line_edit.text
	input_button.line_edit.text = ""

	# var current_config: Dictionary = {}

	# current_config[gui_layer.model_view.name] = gui_layer.model_view.save()
	# current_config[gui_layer.pose_view.name] = gui_layer.pose_view.save()
	# current_config[gui_layer.feature_view.name] = gui_layer.feature_view.save()

	# current_config[PRESET_METADATA_NAME] = PRESET_METADATA_TEMPLATE.duplicate()
	# current_config[PRESET_METADATA_NAME]["name"] = preset_name
	# current_config[PRESET_METADATA_NAME][LAST_MODIFIED_TIME] = OS.get_datetime()
	
	if presets.has(preset_name):
		presets[presets.find(preset_name)] = AppManager.cm.current_model_config.config_name
	else:
		presets.append(AppManager.cm.current_model_config.config_name)
	# presets[preset_name] = current_config

	# AppManager.update_config(self.name, presets)
	AppManager.save_config()
	
	yield(get_tree(), "idle_frame")

	# _setup_left(presets)
	_setup_left(AppManager.cm.current_model_config.get_as_dict())
	_setup_right({})

# TODO updating a currently loaded preset doesn't work right now
func _on_update_preset() -> void:
	var preset_info_element: Control = right_container.inner.get_child(0)
	var preset_data: Dictionary = preset_info_element.save()

	# var config_data = AppManager.cm.get_config_as_dict(preset_info_element.preset_name_text)
	var config_data = AppManager.cm.get_config_as_dict(
			AppManager.cm.metadata_config.config_data[preset_info_element.preset_name_text]
	)

	# Update preset name
	# if preset_info_element.name != preset_data["name"]:
	# 	presets[presets.find(preset_data["name"])] = presets[presets.find(preset_info_element.name)].duplicate(true)
	# 	presets.erase(preset_info_element.name)
	if preset_info_element.preset_name_text != preset_data["name"]:
		presets.erase(preset_info_element.preset_name_text)
		presets.append(preset_data["name"])
	
	config_data.config_name = preset_data["name"]
	config_data.description = preset_data["description"]
	config_data.hotkey = preset_data["hotkey"]
	config_data.notes = preset_data["notes"]
	config_data.is_default_for_model = preset_data["set_as_default"]

	# if preset_data["set_as_default"]:
	# 	for preset_name in presets:
	# 		presets[preset_name][PRESET_METADATA_NAME]["set_as_default"] = false

	# Update last_modified_time
	# preset_data[LAST_MODIFIED_TIME] = OS.get_datetime()

	# presets[preset_data["name"]][PRESET_METADATA_NAME] = preset_data

	# AppManager.update_config(self.name, presets)
	AppManager.cm.update_config_from_dict(preset_info_element.preset_name_text, config_data)
	AppManager.cm.save_config()
	
	yield(get_tree(), "idle_frame")

	_setup_left(config_data)
	# _create_preset_info_display(presets[preset_data["name"]][PRESET_METADATA_NAME])
	_create_preset_info_display(
		# TODO wrap this logic in some sort of ConfigManager function
		AppManager.cm.get_config_as_dict(
			AppManager.cm.metadata_config.config_data[config_data.config_name]
		)
	)
	
	yield(get_tree(), "idle_frame")
	
	# TODO this is gross
	left_container.inner.get_node((config_data.config_name as String).replace(".", "")).toggle_button.pressed = true

func _on_load_preset() -> void:
	var cmc = AppManager.cm.current_model_config

	var config_name: String = right_container.inner.get_child(0).preset_name_text
	if cmc.config_name == config_name:
		# TODO not necesarily true
		# Given ConfigA and ConfigB, ConfigA is loaded
		# When ConfigB is renamed to ConfigA, try to load new ConfigA
		# Then this step fails
		return # Do nothing because it's the same config
	
	var new_config: Dictionary = AppManager.cm.get_config_as_dict(
		AppManager.cm.metadata_config.config_data[config_name]
	)
	if new_config.model_path == cmc.model_path:
		AppManager.cm.current_model_config = new_config
		AppManager.model_is_loaded() # NOTE fake a model load with the new config
	else:
		AppManager.set_file_to_load(new_config.model_path)

func _on_gui_toggle_set(toggle_name: String, view_name: String) -> void:
	._on_gui_toggle_set(toggle_name, view_name)

	for child in left_container.get_inner_children():
		if not child.toggle_button.pressed:
			continue
		var upper_text = child.get("upper_text")
		if (upper_text and presets.has(upper_text)):
			_create_preset_info_display(
				# TODO wrap this logic in some sort of ConfigManager function
				AppManager.cm.get_config_as_dict(
					AppManager.cm.metadata_config.config_data[upper_text]
				)
			)
			return

###############################################################################
# Private functions                                                           #
###############################################################################

func _setup_left(config: Dictionary) -> void:
	left_container.clear_children()

	if not AppManager.is_connected("gui_toggle_set", self, "_on_gui_toggle_set"):
		AppManager.connect("gui_toggle_set", self, "_on_gui_toggle_set")
	
	# if not config.empty():
	# 	presets = config.duplicate(true)
		
	# 	for preset_name in presets.keys():
	# 		var preset_element: MarginContainer = SAVED_PRESET_ELEMENT.instance()
	# 		preset_element.name = preset_name
	# 		preset_element.upper_text = preset_name
	# 		var lmt: Dictionary = presets[preset_name][PRESET_METADATA_NAME][LAST_MODIFIED_TIME]
	# 		if str(lmt["second"]).length() == 1:
	# 			lmt["second"] = "0%s" % lmt["second"]
	# 		preset_element.lower_text = "%s-%s-%s_%s:%s:%s" % [
	# 			lmt["year"], lmt["month"], lmt["day"],
	# 			lmt["hour"], lmt["minute"], lmt["second"]
	# 		]
	# 		left_container.call_deferred("add_to_inner", preset_element)

	presets = AppManager.cm.metadata_config.config_data.keys().duplicate()

	for cd_name in AppManager.cm.metadata_config.config_data.keys():
		var preset_element: MarginContainer = SAVED_PRESET_ELEMENT.instance()
		preset_element.name = cd_name
		preset_element.upper_text = cd_name
		preset_element.lower_text = "not yet implemented"
		left_container.call_deferred("add_to_inner", preset_element)

	if not left_container.outer.get_node_or_null("saved_presets"):
		left_container.add_to_outer(_create_element(ElementType.LABEL, "saved_presets",
				"Saved Presets"), 0)
		
		input_button = INPUT_BUTTON.instance()
		left_container.add_to_outer(input_button, 1)
		input_button.save_button.connect("pressed", self, "_on_save_new_preset")

func _setup_right(_config: Dictionary) -> void:
	right_container.clear_children()

	if not right_container.outer.get_node_or_null("preset_info"):
		right_container.add_to_outer(_create_element(ElementType.LABEL, "preset_info",
				"Preset Info"))

func _create_preset_info_display(data: Dictionary) -> void:
	right_container.clear_children()

	var preset_info_display: MarginContainer = PRESET_INFO_DISPLAY.instance()
	preset_info_display.name = data["config_name"]
	preset_info_display.preset_name_text = data["config_name"]
	preset_info_display.preset_description_text = data["description"]
	preset_info_display.preset_hotkey_text = data["hotkey"]
	preset_info_display.preset_notes_text = data["notes"]
	preset_info_display.preset_set_as_default_value = data["is_default_for_model"]
	
	right_container.add_to_inner(preset_info_display)

	yield(get_tree(), "idle_frame")

	preset_info_display.save_button.connect("pressed", self, "_on_update_preset")
	preset_info_display.load_button.connect("pressed", self, "_on_load_preset")

###############################################################################
# Public functions                                                            #
###############################################################################

func save() -> void:
	_setup()
