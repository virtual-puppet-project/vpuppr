extends CanvasLayer

signal setup_completed

const PropData: Resource = preload("res://screens/gui/PropData.gd")

const PresetData: Resource = preload("res://screens/gui/PresetData.gd")

const DEFAULT_METADATA: String = "metadata.xml"

const XmlConstants: Dictionary = {
	#region Tag names
	"FILE": "file",

	"VIEW": "view",
	"LEFT": "left",
	"RIGHT": "right",
	"FLOATING": "float",

	"LABEL": "label",
	"LIST": "list",
	"TOGGLE": "toggle",
	"INPUT": "input",
	"BUTTON": "button",
	"PRESET": "preset",
	"COLOR_PICKER": "color_picker",
	"INPUT_BUTTON": "input_button",
	"DROP_DOWN": "drop_down",

	"DOUBLE_TOGGLE": "double_toggle",
	
	"PROP_INPUT": "prop_input",
	"PROP_TOGGLE": "prop_toggle",
	"PROP_COLOR_PICKER": "prop_color_picker",
	
	"PRESET_TOGGLE": "preset_toggle",

	#endregion

	# Attribute names
	"NAME": "name",
	"DATA": "data",
	"EVENT": "event",
	"VALUE": "value",
	"TYPE": "type",
	"DISABLED": "disabled",
	"LABEL_UPDATABLE": "label_updatable",
	"LISTEN_FOR_SELF": "listen_for_self",
	"SETUP": "setup", # If defined, the script must have a function that matches the passed value for SETUP

	"SCRIPT": "script" # If defined, the script must have a setup() -> void function defined
}

const DoubleToggleConstants: Dictionary = {
	"TRACK": "track",
	"POSE": "pose"
}

const ListTypes: Dictionary = {
	"PROP_RECEIVER": "prop_receiver",
	"PRESET_RECEIVER": "preset_receiver"
}

const GuiFileParser: Resource = preload("res://screens/gui/GuiFileParser.gd")

# Containers
const BaseView: Resource = preload("res://screens/gui/BaseView.tscn")
const LeftContainer: Resource = preload("res://screens/gui/LeftContainer.tscn")
const RightContainer: Resource = preload("res://screens/gui/RightContainer.tscn")
const FloatingContainer: Resource = preload("res://screens/gui/FloatingContainer.tscn")

const FilePopup: Resource = preload("res://screens/gui/BaseFilePopup.tscn")

const LicensesPopup: PackedScene = preload("res://screens/gui/LicensesPopup.tscn")

# Elements
const ButtonElement: Resource = preload("res://screens/gui/elements/ButtonElement.tscn")
const InputElement: Resource = preload("res://screens/gui/elements/InputElement.tscn")
const LabelElement: Resource = preload("res://screens/gui/elements/LabelElement.tscn")
const ListElement: Resource = preload("res://screens/gui/elements/ListElement.tscn")
const ToggleElement: Resource = preload("res://screens/gui/elements/ToggleElement.tscn")
const DoubleToggleElement: Resource = preload("res://screens/gui/elements/DoubleToggleElement.tscn")
const ViewButton: Resource = preload("res://screens/gui/elements/ViewButton.tscn")
const ColorPickerElement: Resource = preload("res://screens/gui/elements/ColorPickerElement.tscn")
const InputButtonElement: Resource = preload("res://screens/gui/elements/InputButtonElement.tscn")
const DropDownElement: Resource = preload("res://screens/gui/elements/DropDownElement.tscn")

const PropInputElement: Resource = preload("res://screens/gui/elements/PropInputElement.tscn")
const PropToggleElement: Resource = preload("res://screens/gui/elements/PropToggleElement.tscn")
const PropColorPickerElement: Resource = preload("res://screens/gui/elements/PropColorPickerElement.tscn")

const PresetToggleElement: Resource = preload("res://screens/gui/elements/PresetToggleElement.tscn")

const BaseProp: Resource = preload("res://entities/BaseProp.gd")

const GUI_GROUP: String = "Gui"
var gui_views: Dictionary = {} # String: BaseView

const PROP_SCRIPT_PATH := "res://entities/BaseProp.gd"

#region Signal groups

const HIGH_INTENSITY_SIGNALS := [
	"mouse_motion_data",
	"mouse_scroll_data"
]

const MODEL_SIGNALS := [
	"move_model",
	"rotate_model",
	"zoom_model",
	
	"load_model",

	"reset_model_transform",
	"a_pose_model",
	"t_pose_model",

	"bone_toggled"
]

const TRACKING_SIGNALS := [

]

const FEATURES_SIGNALS := [
	"add_custom_prop",

	"prop_toggled",
	
	"move_prop",
	"rotate_prop",
	"zoom_prop",
	"delete_prop"
]

const PRESET_SIGNALS := [
	"new_preset",
	"preset_toggled",

	"config_name",
	"description",
	"hotkey",
	"notes",
	"is_default_for_model",
	"load_preset",
	"delete_preset"
]

const APP_SETTINGS_SIGNALS := [
	"use_transparent_background",
	"use_fxaa",
	"msaa_value",

	"view_licenses",
	"reconstruct_views"
]

#endregion

onready var button_bar: Control = $ButtonBar
onready var button_bar_hbox: HBoxContainer = $ButtonBar/HBoxContainer

var base_path: String

# Model references
var model: BasicModel
var model_parent: Spatial

var initial_model_transform: Transform
var initial_model_parent_transform: Transform

# Input
var is_left_clicking := false
var should_modify_bone := false
var bone_to_modify: String = ""
var should_zoom_model := false
var should_move_model := false
var should_rotate_model := false

var mouse_move_strength: float = 0.002
var scroll_strength: float = 0.05

# View toggling
var current_view: String = ""
var should_hide := false

# Props
var props: Dictionary = {} # String: PropData
var current_prop_data: Reference = PropData.new()
var prop_to_move: Spatial
var should_move_prop := false
var should_rotate_prop := false
var should_zoom_prop := false

# Presets
var presets: Dictionary = {} # String: PresetToggleElement
var current_edited_preset: Reference

###############################################################################
# Builtin functions                                                           #
###############################################################################

func _ready() -> void:
	AppManager.sb.connect("model_loaded", self, "_on_model_loaded")

	for i in HIGH_INTENSITY_SIGNALS:
		AppManager.sb.register(self, i)

	for i in MODEL_SIGNALS:
		AppManager.sb.register(self, i)

	for i in TRACKING_SIGNALS:
		AppManager.sb.register(self, i)

	for i in FEATURES_SIGNALS:
		AppManager.sb.register(self, i)

	for i in PRESET_SIGNALS:
		AppManager.sb.register(self, i)

	for i in APP_SETTINGS_SIGNALS:
		AppManager.sb.register(self, i)

	if not OS.is_debug_build():
		base_path = "%s/%s" % [OS.get_executable_path().get_base_dir(), "resources/gui"]
	else:
		base_path = "res://resources/gui"

	_construct_views_from_xml()

func _unhandled_input(event: InputEvent) -> void:
	if event.is_action_pressed("toggle_gui"):
		should_hide = not should_hide
		if should_hide:
			for c in get_children():
				c.visible = false
		else:
			button_bar.visible = true
			_toggle_view(current_view)

	if event.is_action_pressed("left_click"):
		is_left_clicking = true
	elif event.is_action_released("left_click"):
		is_left_clicking = false

		AppManager.save_config()

	# Bone posing
	if should_modify_bone:
		if (is_left_clicking and event is InputEventMouseMotion):
			var transform: Transform = model.skeleton.get_bone_pose(
					model.skeleton.find_bone(bone_to_modify))
			transform = transform.rotated(Vector3.UP, event.relative.x * mouse_move_strength)
			transform = transform.rotated(Vector3.RIGHT, event.relative.y * mouse_move_strength)

			model.skeleton.set_bone_pose(
					model.skeleton.find_bone(bone_to_modify), transform)
		elif event.is_action("scroll_up"):
			var transform: Transform = model.skeleton.get_bone_pose(
					model.skeleton.find_bone(bone_to_modify))
			transform = transform.rotated(Vector3.FORWARD, scroll_strength)

			model.skeleton.set_bone_pose(
					model.skeleton.find_bone(bone_to_modify), transform)
		elif event.is_action("scroll_down"):
			var transform: Transform = model.skeleton.get_bone_pose(
					model.skeleton.find_bone(bone_to_modify))
			transform = transform.rotated(Vector3.FORWARD, -scroll_strength)

			model.skeleton.set_bone_pose(
					model.skeleton.find_bone(bone_to_modify), transform)
	
	# Model and prop movement
	if (is_left_clicking and event is InputEventMouseMotion):
		AppManager.sb.broadcast_mouse_motion_data(event.relative)
	elif event.is_action("scroll_up"):
		AppManager.sb.broadcast_mouse_scroll_data(1)
	elif event.is_action("scroll_down"):
		AppManager.sb.broadcast_mouse_scroll_data(2)

###############################################################################
# Connections                                                                 #
###############################################################################

func _on_view_button_pressed(view_name: String) -> void:
	_switch_view_to(view_name)

func _on_model_loaded(p_model: BasicModel) -> void:
	model = p_model
	initial_model_transform = model.transform
	
	model_parent = model.get_parent()
	initial_model_parent_transform = model_parent.transform

	model.additional_bones_to_pose_names = AppManager.cm.current_model_config.mapped_bones
	model.scan_mapped_bones()

	_setup_gui_nodes()

func _on_mouse_motion_data(mouse_delta: Vector2) -> void:
	if should_move_model:
		model_parent.translate(Vector3(mouse_delta.x, -mouse_delta.y, 0.0) * mouse_move_strength)
	if should_rotate_model:
		model.rotate_x(mouse_delta.y * mouse_move_strength)
		model.rotate_y(mouse_delta.x * mouse_move_strength)

	if should_move_prop:
		prop_to_move.translate(Vector3(mouse_delta.x, -mouse_delta.y, 0.0) * mouse_move_strength)
	if should_rotate_prop:
		prop_to_move.get_child(0).rotate_x(mouse_delta.y * mouse_move_strength)
		prop_to_move.get_child(0).rotate_y(mouse_delta.x * mouse_move_strength)

func _on_mouse_scroll_data(scroll_direction: int) -> void:
	if should_zoom_model:
		model_parent.translate(Vector3(0.0, 0.0, scroll_strength * scroll_direction))
	if should_zoom_prop:
		prop_to_move.translate(Vector3(0.0, 0.0, scroll_strength * scroll_direction))

# Model

func _on_move_model(value: bool) -> void:
	should_move_model = value

func _on_rotate_model(value: bool) -> void:
	should_rotate_model = value

func _on_zoom_model(value: bool) -> void:
	should_zoom_model = value

func _on_load_model() -> void:
	var popup: FileDialog = FilePopup.instance()
	add_child(popup)

	yield(get_tree(), "idle_frame")

	var load_path: String = AppManager.cm.metadata_config.default_model_search_path
	if not load_path.ends_with("/"):
		load_path += "/"
	popup.current_dir = load_path
	popup.current_path = load_path

	# TODO this might be a memory leak if you open up many popups but don't select a model
	yield(popup, "file_selected")
	
	AppManager.sb.broadcast_default_model_search_path(popup.file)
	AppManager.cm.save_config()

	_cleanup_props()

	AppManager.sb.set_file_to_load(popup.file)

	popup.queue_free()

func _on_reset_model_transform() -> void:
	model.transform = initial_model_transform
	model_parent.transform = initial_model_parent_transform

func _on_t_pose_model() -> void:
	model.reset_all_bone_poses()

func _on_a_pose_model() -> void:
	model.a_pose()

func _on_bone_toggled(bone_name: String, toggle_type: String, toggle_value: bool) -> void:
	match toggle_type:
		DoubleToggleConstants.TRACK:
			if toggle_value:
				AppManager.cm.current_model_config.mapped_bones.append(bone_name)
			else:
				AppManager.cm.current_model_config.mapped_bones.erase(bone_name)
			model.scan_mapped_bones()
		DoubleToggleConstants.POSE:
			if toggle_value:
				should_modify_bone = true
				bone_to_modify = bone_name
			else:
				should_modify_bone = false
		_:
			AppManager.logger.error("Unhandled toggle received: %s" % toggle_type)

# Tracking

# Features

func _on_add_custom_prop() -> void:
	var popup: FileDialog = FilePopup.instance()
	add_child(popup)

	yield(get_tree(), "idle_frame")

	var load_path: String = AppManager.cm.metadata_config.default_prop_search_path
	if not load_path.ends_with("/"):
		load_path += "/"
	popup.current_dir = load_path
	popup.current_path = load_path

	yield(popup, "file_selected")
	
	AppManager.sb.broadcast_default_prop_search_path(popup.file)
	AppManager.cm.save_config()
	
	var prop_name: String = popup.file.get_file() \
		.trim_suffix(popup.file.get_extension()).trim_suffix(".")
	# Set distinct prop name so we don't accidentally override existing props
	var final_prop_name := prop_name
	var counter: int = 0
	while props.has(final_prop_name):
		final_prop_name = "%s%d" % [prop_name, counter]
		counter += 1

	var prop: Spatial = create_prop(popup.file)
	if (prop and prop.get_child_count() == 0):
		AppManager.logger.error("Invalid prop")
		return

	AppManager.main.model_display_screen.props.call_deferred("add_child", prop)

	var toggle: BaseElement = generate_ui_element(XmlConstants.PROP_TOGGLE, {
		"name": final_prop_name,
		"event": "prop_toggled"
	})
	AppManager.sb.broadcast_custom_prop_toggle_created(toggle)
	
	var prop_data = PropData.new()
	prop_data.prop_name = final_prop_name
	prop_data.prop = prop
	prop_data.toggle = toggle
	prop_data.prop_path = prop.prop_path
	
	props[final_prop_name] = prop_data
	AppManager.cm.current_model_config.instanced_props[final_prop_name] = prop_data.get_as_dict()

	popup.queue_free()

func _on_prop_toggled(prop_name: String, is_visible: bool) -> void:
	if (not is_visible or prop_name == "Main Light" or prop_name == "World Environment"):
		should_move_prop = false
		should_rotate_prop = false
		should_zoom_prop = false
	if props.has(prop_name):
		current_prop_data = props[prop_name]
		prop_to_move = current_prop_data.prop

func _on_move_prop(value: bool) -> void:
	should_move_prop = value

func _on_rotate_prop(value: bool) -> void:
	should_rotate_prop = value

func _on_zoom_prop(value: bool) -> void:
	should_zoom_prop = value

func _on_delete_prop() -> void:
	var prop_name = current_prop_data.prop_name

	current_prop_data.prop.queue_free()
	current_prop_data.toggle.queue_free()
	props.erase(prop_name)

	prop_to_move = null
	current_prop_data = null

	should_move_prop = false
	should_rotate_prop = false
	should_zoom_prop = false

	AppManager.cm.current_model_config.instanced_props.erase(prop_name)

# Presets

func _on_new_preset(preset_name: String) -> void:
	# TODO add name validation if there is a naming conflict
	var toggle: BaseElement = generate_ui_element(XmlConstants.PRESET_TOGGLE, {
		"name": preset_name,
		"event": "preset_toggled"
	})
	toggle.preset_name = preset_name
	AppManager.sb.connect("preset_toggled", toggle, "_on_preset_toggled")

	presets[preset_name] = toggle
	AppManager.sb.broadcast_preset_toggle_created(toggle)

	var cd = AppManager.cm.current_model_config.duplicate()
	cd.config_name = preset_name
	cd.is_default_for_model = false
	AppManager.cm.metadata_config.config_data[preset_name] = cd.model_path
	AppManager.cm.save_config(cd)

	AppManager.cm.current_model_config = cd

func _on_preset_toggled(preset_name: String, is_visible: bool) -> void:
	if is_visible:
		AppManager.save_config_instant(current_edited_preset)
		current_edited_preset = AppManager.cm.load_config_for_preset(preset_name)

# TODO this will break deleting presets
# Maybe use ids to track presets
func _on_config_name(config_name: String) -> void:
	current_edited_preset.config_name = config_name

func _on_description(description: String) -> void:
	current_edited_preset.description = description

func _on_hotkey(hotkey: String) -> void:
	current_edited_preset.hotkey = hotkey

func _on_notes(notes: String) -> void:
	current_edited_preset.notes = notes

func _on_is_default_for_model(value: bool) -> void:
	current_edited_preset.is_default_for_model = value

func _on_load_preset() -> void:
	AppManager.save_config_instant()
	var cmc = AppManager.cm.current_model_config
	if cmc.config_name == current_edited_preset.config_name:
		return # Do nothing if we try to load the current config

	_cleanup_props()
	
	AppManager.cm.current_model_config = current_edited_preset.duplicate()
	if cmc.model_name != current_edited_preset.model_name:
		AppManager.main.load_file(AppManager.cm.current_model_config.model_path)
	else:
		_setup_gui_nodes()

	AppManager.sb.broadcast_preset_loaded()

	model.transform = AppManager.cm.current_model_config.model_transform
	model_parent.transform = AppManager.cm.current_model_config.model_parent_transform

func _on_delete_preset() -> void:
	var preset_name: String = current_edited_preset.config_name
	var is_default: bool = current_edited_preset.is_default_for_model

	# Delete the config file
	var config_path = AppManager.cm.metadata_config.config_data.get(preset_name)
	if not config_path:
		AppManager.logger.error("Unable to delete preset, metadata does not contain preset: %s" % preset_name)
		return
	var dir := Directory.new()
	if not dir.file_exists(config_path):
		AppManager.logger.info("Unable to delete preset, file not found: %s" % preset_name)
		return
	dir.remove(config_path)

	# Update metadata
	AppManager.cm.metadata_config.config_data.erase(preset_name)
	if is_default:
		AppManager.cm.metadata_config.model_defaults.erase(current_edited_preset.model_name)
	
	# Generate a new config if we just deleted the one in use
	if AppManager.cm.current_model_config == current_edited_preset:
		var cd = AppManager.cm.ConfigData.new()
		cd.config_name = AppManager.cm.current_model_config.config_name
		cd.model_name = AppManager.cm.current_model_config.model_name
		cd.model_path = AppManager.cm.current_model_config.model_path
		AppManager.cm.current_model_config = cd.duplicate()

	presets[preset_name].queue_free()
	presets.erase(preset_name)
	
	current_edited_preset = null

# App settings

func _on_view_licenses() -> void:
	var popup: Popup = LicensesPopup.instance()
	add_child(popup)

func _on_use_transparent_background(value: bool) -> void:
	ProjectSettings.set_setting("display/window/per_pixel_transparency/allowed", value)
	ProjectSettings.set_setting("display/window/per_pixel_transparency/enabled", value)
	get_viewport().transparent_bg = value
	AppManager.cm.metadata_config.use_transparent_background = value

func _on_use_fxaa(value: bool) -> void:
	ProjectSettings.set_setting("rendering/quality/filters/use_fxaa", value)
	get_viewport().fxaa = value
	AppManager.cm.metadata_config.use_fxaa = value

func _on_msaa_value(value: bool) -> void:
	# TODO needs to take in a list
	if value:
		ProjectSettings.set_setting("rendering/quality/filters/msaa", Viewport.MSAA_4X)
		get_viewport().msaa = Viewport.MSAA_4X
	else:
		ProjectSettings.set_setting("rendering/quality/filters/msaa", Viewport.MSAA_DISABLED)
		get_viewport().msaa = Viewport.MSAA_DISABLED
	
	AppManager.cm.metadata_config.msaa_value = value

func _on_reconstruct_views() -> void:
	_construct_views_from_xml()

	yield(get_tree(), "idle_frame")

	_setup_gui_nodes()

###############################################################################
# Private functions                                                           #
###############################################################################

func _switch_view_to(view_name: String) -> void:
	if view_name == current_view:
		_toggle_view(view_name)
		current_view = ""
		return
	_toggle_view(current_view)
	_toggle_view(view_name)
	current_view = view_name

func _toggle_view(view_name: String) -> void:
	if view_name:
		gui_views[view_name].visible = not gui_views[view_name].visible

func _setup_gui_nodes() -> void:
	for node in get_tree().get_nodes_in_group(GUI_GROUP):
		node.setup()

func _cleanup_props() -> void:
	for prop_name in props:
		props[prop_name].prop.queue_free()
		props[prop_name].toggle.queue_free()
	props.clear()

func _construct_views_from_xml() -> void:
	# These must use queue_free or else we hard crash
	for value in gui_views.values():
		value.queue_free()
	for child in button_bar_hbox.get_children():
		child.queue_free()
	gui_views.clear()

	yield(get_tree(), "idle_frame")

	var xml_files_to_parse: Array = []
	
	# Null check or else we segfault
	var dir := Directory.new()
	if not dir.dir_exists(base_path):
		AppManager.logger.error("%s does not exist. Please check your installation." % base_path)
		return

	var metadata_parser = GuiFileParser.new()
	AppManager.logger.info("Loading metadata: %s" % DEFAULT_METADATA)
	metadata_parser.open_resource("%s/%s" % [base_path, DEFAULT_METADATA])
	while true:
		var data = metadata_parser.read_node()
		if not data.is_empty and data.node_name == XmlConstants.FILE:
			if not data.data.has(XmlConstants.NAME):
				AppManager.logger.error("Invalid gui metadata")
				return
			xml_files_to_parse.append(data.data[XmlConstants.NAME])

		if data.is_complete:
			break
	
	# Process and generate guis per file
	for xml_file in xml_files_to_parse:
		var base_view: Control = BaseView.instance()
		add_child(base_view)

		var c_view: String
		var left = null
		var right = null
		var floating = null

		var gui_parser = GuiFileParser.new()
		AppManager.logger.info("Loading gui file: %s" % xml_file)
		gui_parser.open_resource("%s/%s" % [base_path, xml_file])
		while true:
			var data = gui_parser.read_node()
			if not data.is_empty:
				match data.node_name:
					XmlConstants.LEFT:
						if left:
							AppManager.logger.error("Invalid data for %s" % xml_file)
							return
						left = LeftContainer.instance()
						base_view.add_child(left)
						c_view = XmlConstants.LEFT
					XmlConstants.RIGHT:
						if right:
							AppManager.logger.error("Invalid data for %s" % xml_file)
							return
						right = RightContainer.instance()
						base_view.add_child(right)
						c_view = XmlConstants.RIGHT
					XmlConstants.FLOATING:
						if floating:
							AppManager.logger.error("Invalid data for %s" % xml_file)
							return
						floating = FloatingContainer.instance()
						base_view.add_child(floating)
						c_view = XmlConstants.FLOATING
					XmlConstants.VIEW:
						base_view.name = data.data["name"]
						
						if data.data.has("script"):
							var file := File.new()
							if file.open("%s/%s" % [base_path, data.data["script"]], File.READ) != OK:
								AppManager.logger.error("Failed to open script")

							var script: Script = base_view.get_script().duplicate()
							script.source_code = file.get_as_text()
							base_view.set_script(null)
							script.reload()
							base_view.set_script(script)
							
							if base_view.has_method("setup"):
								base_view.call("setup")
					_:
						var element: BaseElement = generate_ui_element(data.node_name, data.data)
						element.containing_view = base_view
						match c_view:
							XmlConstants.LEFT:
								left.vbox.add_child(element)
							XmlConstants.RIGHT:
								right.vbox.add_child(element)
							XmlConstants.FLOATING:
								floating.vbox.add_child(element)

			if data.is_complete:
				break

		# Create top bar buttons
		var button := ViewButton.instance()
		button.button_text = base_view.name
		button.name = base_view.name
		button.connect("view_selected", self, "_on_view_button_pressed")
		button_bar_hbox.add_child(button)

		gui_views[base_view.name] = base_view

	emit_signal("setup_completed")

	# Toggle initial views
	current_view = button_bar_hbox.get_child(0).name
	for key in gui_views.keys():
		if key == current_view:
			continue
		_toggle_view(key)

###############################################################################
# Public functions                                                            #
###############################################################################

func generate_ui_element(tag_name: String, data: Dictionary) -> BaseElement:
	var result: BaseElement

	if not data.has("name"):
		AppManager.logger.error("Invalid element data")
		return result

	var display_name: String = data["name"]
	var node_name = display_name.replace(" ", "").validate_node_name()

	match tag_name:
		XmlConstants.LABEL:
			result = LabelElement.instance()
		XmlConstants.LIST:
			result = ListElement.instance()
		XmlConstants.TOGGLE:
			result = ToggleElement.instance()
		XmlConstants.DOUBLE_TOGGLE:
			result = DoubleToggleElement.instance()
			AppManager.sb.connect("head_bone", result, "_on_head_bone")
		XmlConstants.PROP_TOGGLE:
			result = PropToggleElement.instance()
			result.prop_name = data["name"]

			AppManager.sb.connect("prop_toggled", result, "_on_prop_toggled")
		XmlConstants.INPUT:
			result = InputElement.instance()
			if data.has(XmlConstants.TYPE):
				result.data_type = data[XmlConstants.TYPE]
		XmlConstants.PROP_INPUT:
			result = PropInputElement.instance()
			result.prop_name = data["name"]
			if data.has(XmlConstants.TYPE):
				result.data_type = data[XmlConstants.TYPE]
		XmlConstants.BUTTON:
			result = ButtonElement.instance()
		XmlConstants.COLOR_PICKER:
			result = ColorPickerElement.instance()
		XmlConstants.PROP_COLOR_PICKER:
			result = PropColorPickerElement.instance()
			result.prop_name = data["name"]
		XmlConstants.PRESET_TOGGLE:
			result = PresetToggleElement.instance()
		XmlConstants.INPUT_BUTTON:
			result = InputButtonElement.instance()
		XmlConstants.DROP_DOWN:
			result = DropDownElement.instance()
		_:
			AppManager.logger.info("Unhandled tag_name: %s" % tag_name)
			return result

	if data.has(XmlConstants.DATA):
		result.data_bind = data[XmlConstants.DATA]

	if data.has(XmlConstants.EVENT):
		result.event_name = data[XmlConstants.EVENT]

	if data.has(XmlConstants.DISABLED):
		match data[XmlConstants.DISABLED].to_lower():
			"true", "yes":
				result.is_disabled = true
			"false", "no":
				result.is_disabled = false
			_:
				# Ignore invalid syntax
				pass

	if data.has(XmlConstants.LABEL_UPDATABLE):
		match data[XmlConstants.LABEL_UPDATABLE].to_lower():
			"true", "yes":
				AppManager.sb.connect("update_label_text", result, "_on_label_updated")
			"false", "no":
				pass
			_:
				# Ignore invalid syntax
				pass

	if data.has(XmlConstants.LISTEN_FOR_SELF):
		match data[XmlConstants.LISTEN_FOR_SELF].to_lower():
			"true", "yes":
				AppManager.sb.connect(result.event_name, result, "_on_value_updated")
			"false", "no":
				pass
			_:
				# Ignore invalid syntax
				pass

	if data.has(XmlConstants.SETUP):
		result.setup_function = data[XmlConstants.SETUP]

	result.name = node_name
	result.label_text = display_name

	result.add_to_group(GUI_GROUP)

	result.parent = self

	return result

func create_prop(prop_path: String, parent_transform: Transform = Transform(),
			child_transform: Transform = Transform()) -> Spatial:
	var prop_parent := Spatial.new()
	prop_parent.set_script(BaseProp)

	var prop: Spatial
	match prop_path.get_extension().to_lower():
		"tscn":
			prop = ResourceLoader.load(prop_path).instance()
		"glb":
			var gltf: PackedSceneGLTF = PackedSceneGLTF.new()
			prop = gltf.import_gltf_scene(prop_path, 1, 1000.0)
			prop.name = prop_path.get_file().trim_suffix(prop_path.get_extension())
		"vrm":
			var vrm_loader = load("res://addons/vrm/vrm_loader.gd")
			prop = vrm_loader.import_scene(prop_path, 1, 1000)
			prop.name = prop_path.get_file().trim_suffix(prop_path.get_extension())
		"png", "jpg", "jpeg":
			var texture: Texture = ImageTexture.new()
			var image: Image = Image.new()
			var error = image.load(prop_path)
			if error != OK:
				continue
			texture.create_from_image(image, 0)
			prop = Sprite3D.new()
			prop.texture = texture
			prop.name = prop_path.get_file().trim_suffix(prop_path.get_extension())
		_:
			AppManager.logger.error("Unhandled filetype: %s" % prop_path)

	if not prop:
		return prop_parent

	prop_parent.name = prop.name
	prop_parent.add_child(prop)

	prop_parent.prop_path = prop_path
	prop_parent.transform = parent_transform
	prop.transform = child_transform

	prop_parent.set_script(load(PROP_SCRIPT_PATH))

	return prop_parent
