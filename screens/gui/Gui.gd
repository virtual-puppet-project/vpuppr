extends CanvasLayer

signal setup_completed

const DEFAULT_METADATA: String = "metadata.xml"

const XmlConstants: Dictionary = {
	# Tag names
	"FILE": "file",

	"VIEW": "view",
	"LEFT": "left",
	"RIGHT": "right",
	"FLOATING": "float",

	"LABEL": "label",
	"LIST": "list",
	"TOGGLE": "toggle",
	"DOUBLE_TOGGLE": "double_toggle",
	"INPUT": "input",
	"BUTTON": "button",
	"PRESET": "preset",

	# Attribute names
	"NAME": "name",
	"DATA": "data",
	"EVENT": "event",
	"VALUE": "value",
	"TYPE": "type",

	"SCRIPT": "script"
}

const DoubleToggleConstants: Dictionary = {
	"TRACK": "track",
	"POSE": "pose"
}

const ListTypes: Dictionary = {
	"RECEIVER": "receiver"
}

const GuiFileParser: Resource = preload("res://screens/gui/GuiFileParser.gd")

# Containers
const BaseView: Resource = preload("res://screens/gui/BaseView.tscn")
const LeftContainer: Resource = preload("res://screens/gui/LeftContainer.tscn")
const RightContainer: Resource = preload("res://screens/gui/RightContainer.tscn")
const FloatingContainer: Resource = preload("res://screens/gui/FloatingContainer.tscn")

const FilePopup: Resource = preload("res://screens/gui/BaseFilePopup.tscn")

# Elements
const ButtonElement: Resource = preload("res://screens/gui/elements/ButtonElement.tscn")
const InputElement: Resource = preload("res://screens/gui/elements/InputElement.tscn")
const LabelElement: Resource = preload("res://screens/gui/elements/LabelElement.tscn")
const ListElement: Resource = preload("res://screens/gui/elements/ListElement.tscn")
const ToggleElement: Resource = preload("res://screens/gui/elements/ToggleElement.tscn")
const DoubleToggleElement: Resource = preload("res://screens/gui/elements/DoubleToggleElement.tscn")
const ViewButton: Resource = preload("res://screens/gui/elements/ViewButton.tscn")

const BaseProp: Resource = preload("res://entities/BaseProp.gd")

const GUI_GROUP: String = "Gui"
const GUI_VIEWS: Dictionary = {} # String: BaseView
const PROPS: Dictionary = {} # String: Spatial

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

###############################################################################
# Builtin functions                                                           #
###############################################################################

func _ready() -> void:
	AppManager.sb.connect("model_loaded", self, "_on_model_loaded")
	
	AppManager.sb.connect("move_model", self, "_on_move_model")
	AppManager.sb.connect("rotate_model", self, "_on_rotate_model")
	AppManager.sb.connect("zoom_model", self, "_on_zoom_model")

	AppManager.sb.connect("load_model", self, "_on_load_model")
	
	AppManager.sb.connect("reset_model_transform", self, "_on_reset_model_transform")
	AppManager.sb.connect("reset_model_pose", self, "_on_reset_model_pose")

	AppManager.sb.connect("bone_toggled", self, "_on_bone_toggled")

	AppManager.sb.connect("add_custom_prop", self, "_on_add_custom_prop")

	if not OS.is_debug_build():
		base_path = "%s/%s" % [OS.get_executable_path().get_base_dir(), "resources/gui"]
	else:
		base_path = "res://resources/gui"
	
	var xml_files_to_parse: Array = []

	var metadata_parser = GuiFileParser.new()
	AppManager.log_message("Loading metadata: %s" % DEFAULT_METADATA)
	metadata_parser.open_resource("%s/%s" % [base_path, DEFAULT_METADATA])
	while true:
		var data = metadata_parser.read_node()
		if not data.is_empty and data.node_name == XmlConstants.FILE:
			if not data.data.has(XmlConstants.NAME):
				AppManager.log_message("Invalid gui metadata", true)
				return
			xml_files_to_parse.append(data.data[XmlConstants.NAME])

		if data.is_complete:
			break
	
	# Process and generate guis per file
	for xml_file in xml_files_to_parse:
		var base_view: Control = BaseView.instance()
		call_deferred("add_child", base_view)
		yield(base_view, "ready")

		var current_view: String
		var left
		var right
		var floating

		var gui_parser = GuiFileParser.new()
		AppManager.log_message("Loading gui file: %s" % xml_file)
		gui_parser.open_resource("%s/%s" % [base_path, xml_file])
		while true:
			var data = gui_parser.read_node()
			if not data.is_empty:
				match data.node_name:
					XmlConstants.LEFT:
						if left:
							AppManager.log_message("Invalid data for %s" % xml_file, true)
							return
						left = LeftContainer.instance()
						base_view.call_deferred("add_child", left)
						yield(left, "ready")
						current_view = XmlConstants.LEFT
					XmlConstants.RIGHT:
						if right:
							AppManager.log_message("Invalid data for %s" % xml_file, true)
							return
						right = RightContainer.instance()
						base_view.call_deferred("add_child", right)
						yield(right, "ready")
						current_view = XmlConstants.RIGHT
					XmlConstants.FLOATING:
						if floating:
							AppManager.log_message("Invalid data for %s" % xml_file, true)
							return
						floating = FloatingContainer.instance()
						base_view.call_deferred("add_child", floating)
						yield(floating, "ready")
						current_view = XmlConstants.FLOATING
					XmlConstants.VIEW:
						base_view.name = data.data["name"]
						
						if data.data.has("script"):
							var file := File.new()
							if file.open("%s/%s" % [base_path, data.data["script"]], File.READ) != OK:
								AppManager.log_message("Failed to open script", true)

							var script: Script = base_view.get_script()
							script.source_code = file.get_as_text()
							base_view.set_script(null)
							script.reload()
							base_view.set_script(script)
					_:
						var element: Control = generate_ui_element(data.node_name, data.data)
						element.connect("event", self, "_on_event")
						match current_view:
							XmlConstants.LEFT:
								left.vbox.call_deferred("add_child", element)
							XmlConstants.RIGHT:
								right.vbox.call_deferred("add_child", element)
							XmlConstants.FLOATING:
								floating.vbox.call_deferred("add_child", element)

			if data.is_complete:
				break

		# Create top bar buttons
		var button := ViewButton.instance()
		button.button_text = base_view.name
		button.name = base_view.name
		button.connect("view_selected", self, "_on_view_button_pressed")
		button_bar_hbox.call_deferred("add_child", button)

		GUI_VIEWS[base_view.name] = base_view
		base_view.setup()

		yield(get_tree(), "idle_frame")

		emit_signal("setup_completed")
	# Toggle initial views
	current_view = button_bar_hbox.get_child(0).name
	for key in GUI_VIEWS.keys():
		if key == current_view:
			continue
		_toggle_view(key)

func _unhandled_input(event: InputEvent) -> void:
	# Long if/else chain because unhandled input processes only 1 input at a time

	if event.is_action_pressed("toggle_gui"):
		should_hide = not should_hide
		if should_hide:
			for c in get_children():
				c.visible = false
		else:
			button_bar.visible = true
			# bottom_container.visible = true
			_toggle_view(current_view)

	if event.is_action_pressed("left_click"):
		is_left_clicking = true
	elif event.is_action_released("left_click"):
		is_left_clicking = false

	# Intentionally verbose so logic can cancel out
	# i.e. we don't want to modify bone and move model at the same time
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
	
	if (is_left_clicking and event is InputEventMouseMotion):
		if should_move_model:
			model_parent.translate(Vector3(event.relative.x, -event.relative.y, 0.0) * mouse_move_strength)
		if should_rotate_model:
			model.rotate_x(event.relative.y * mouse_move_strength)
			model.rotate_y(event.relative.x * mouse_move_strength)
	elif should_zoom_model:
		if event.is_action("scroll_up"):
			model_parent.translate(Vector3(0.0, 0.0, scroll_strength))
		elif event.is_action("scroll_down"):
			model_parent.translate(Vector3(0.0, 0.0, -scroll_strength))

###############################################################################
# Connections                                                                 #
###############################################################################

func _on_view_button_pressed(view_name: String) -> void:
	_switch_view_to(view_name)

func _on_event(event_value) -> void:
	match typeof(event_value):
		TYPE_ARRAY: # input and toggle
			if event_value.size() > 2:
				AppManager.sb.call("broadcast_%s" % event_value[0], event_value.slice(1, event_value.size() - 1))
			else:
				AppManager.sb.call("broadcast_%s" % event_value[0], event_value[1])
		TYPE_STRING:
			AppManager.sb.call("broadcast_%s" % event_value)
		_:
			AppManager.log_message("Unhandled gui event" % str(event_value), true)

func _on_model_loaded(p_model: BasicModel) -> void:
	model = p_model
	initial_model_transform = model.transform
	
	model_parent = model.get_parent()
	initial_model_parent_transform = model_parent.transform

	model.additional_bones_to_pose_names = AppManager.cm.current_model_config.mapped_bones
	model.scan_mapped_bones()

	for node in get_tree().get_nodes_in_group(GUI_GROUP):
		node.setup()

func _on_move_model(value: bool) -> void:
	should_move_model = value

func _on_rotate_model(value: bool) -> void:
	should_rotate_model = value

func _on_zoom_model(value: bool) -> void:
	should_zoom_model = value

func _on_load_model() -> void:
	var popup: FileDialog = FilePopup.instance()
	get_parent().add_child(popup)

	yield(get_tree(), "idle_frame")

	var load_path: String = AppManager.cm.metadata_config.default_search_path
	if not load_path.ends_with("/"):
		load_path += "/"
	popup.current_dir = load_path
	popup.current_path = load_path

	yield(popup, "file_selected")

	AppManager.sb.set_file_to_load(popup.file)

	popup.queue_free()

func _on_reset_model_transform() -> void:
	model.transform = initial_model_transform
	model_parent.transform = initial_model_parent_transform

func _on_reset_model_pose() -> void:
	model.reset_all_bone_poses()

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
			AppManager.log_message("Unhandled toggle received: %s" % toggle_type, true)

func _on_add_custom_prop() -> void:
	var popup: FileDialog = FilePopup.instance()
	get_parent().add_child(popup)

	yield(get_tree(), "idle_frame")

	var load_path: String = AppManager.cm.metadata_config.default_search_path
	if not load_path.ends_with("/"):
		load_path += "/"
	popup.current_dir = load_path
	popup.current_path = load_path

	yield(popup, "file_selected")

	var prop: Spatial = _create_prop(popup.file)
	get_parent().call_deferred("add_child", prop)

	popup.queue_free()

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
		GUI_VIEWS[view_name].visible = not GUI_VIEWS[view_name].visible

# TODO method stub
func _create_prop(prop_path: String) -> Spatial:
	var prop_parent := Spatial.new()
	prop_parent.set_script(BaseProp)

	var prop: Spatial

	return prop_parent

###############################################################################
# Public functions                                                            #
###############################################################################

func generate_ui_element(tag_name: String, data: Dictionary) -> BaseElement:
	var result: BaseElement

	if not data.has("name"):
		AppManager.log_message("Invalid element data", true)
		return result

	var display_name: String = data["name"]
	var node_name = display_name.replace(" ", "").validate_node_name()

	match tag_name:
		XmlConstants.LABEL:
			result = LabelElement.instance()
		XmlConstants.LIST:
			result = ListElement.instance()
			if data.has(XmlConstants.TYPE):
				match data[XmlConstants.TYPE]:
					ListTypes.RECEIVER:
						AppManager.sb.connect("prop_gui_toggled", result, "_load_prop_information")
					_:
						AppManager.log_message("Unhandled list type %s" % data[XmlConstants.TYPE])
		XmlConstants.TOGGLE:
			result = ToggleElement.instance()
		XmlConstants.DOUBLE_TOGGLE:
			result = DoubleToggleElement.instance()
		XmlConstants.INPUT:
			result = InputElement.instance()
			if data.has(XmlConstants.TYPE):
				result.data_type = data[XmlConstants.TYPE]
		XmlConstants.BUTTON:
			result = ButtonElement.instance()
		_:
			AppManager.log_message("Unhandled tag_name: %s" % tag_name)
			return result

	result.name = node_name
	result.label_text = display_name
	if data.has(XmlConstants.DATA):
		result.data_bind = data[XmlConstants.DATA]

	result.add_to_group(GUI_GROUP)

	if data.has(XmlConstants.EVENT):
		result.event_name = data[XmlConstants.EVENT]

	result.parent = self

	return result
