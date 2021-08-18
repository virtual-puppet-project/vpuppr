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

const GuiFileParser: Resource = preload("res://screens/gui/GuiFileParser.gd")

# Containers
const BaseView: Resource = preload("res://screens/gui/BaseView.tscn")
const LeftContainer: Resource = preload("res://screens/gui/LeftContainer.tscn")
const RightContainer: Resource = preload("res://screens/gui/RightContainer.tscn")
const FloatingContainer: Resource = preload("res://screens/gui/FloatingContainer.tscn")

# Elements
const ButtonElement: Resource = preload("res://screens/gui/elements/ButtonElement.tscn")
const InputElement: Resource = preload("res://screens/gui/elements/InputElement.tscn")
const LabelElement: Resource = preload("res://screens/gui/elements/LabelElement.tscn")
const ListElement: Resource = preload("res://screens/gui/elements/ListElement.tscn")
const ToggleElement: Resource = preload("res://screens/gui/elements/ToggleElement.tscn")
const DoubleToggleElement: Resource = preload("res://screens/gui/elements/DoubleToggleElement.tscn")

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

		# Create buttons
		var button := Button.new()
		button.text = xml_file.get_file() # TODO get rid of the xml suffix
		# TODO connect this to some toggling logic
		button_bar_hbox.call_deferred("add_child", button)

		base_view.setup()

		yield(get_tree(), "idle_frame")

		emit_signal("setup_completed")

func _unhandled_input(event: InputEvent) -> void:
	# Long if/else chain because unhandled input processes only 1 input at a time

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

	for node in get_tree().get_nodes_in_group(XmlConstants.LIST):
		node.setup(self, p_model)

func _on_move_model(value: bool) -> void:
	should_move_model = value

func _on_rotate_model(value: bool) -> void:
	should_rotate_model = value

func _on_zoom_model(value: bool) -> void:
	should_zoom_model = value

func _on_load_model() -> void:
	pass # TODO method stub

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

###############################################################################
# Private functions                                                           #
###############################################################################

###############################################################################
# Public functions                                                            #
###############################################################################

static func generate_ui_element(tag_name: String, data: Dictionary) -> BaseElement:
	var result: BaseElement

	if not data.has("name"):
		AppManager.log_message("Invalid element data", true)
		return result

	var display_name: String = data["name"]
	var node_name = display_name.replace(" ", "").validate_node_name()

	match tag_name:
		XmlConstants.LABEL:
			result = LabelElement.instance()
			result.name = node_name
			result.label_text = display_name
		XmlConstants.LIST:
			result = ListElement.instance()
			result.name = node_name
			result.label_text = display_name

			if not data.has("data"):
				AppManager.log_message("Data mapping must be specified for lists", true)
				return result
			result.data_mapping = data["data"]
		XmlConstants.TOGGLE:
			result = ToggleElement.instance()
			result.name = node_name
			result.label_text = display_name
		XmlConstants.DOUBLE_TOGGLE:
			result = DoubleToggleElement.instance()
			result.name = node_name
			result.label_text = display_name
		XmlConstants.INPUT:
			result = InputElement.instance()
			result.name = node_name
			result.label_text = display_name
			if data.has("type"):
				result.data_type = data["type"]
		XmlConstants.BUTTON:
			result = ButtonElement.instance()
			result.name = node_name
			result.label_text = display_name
		_:
			AppManager.log_message("Unhandled tag_name: %s" % tag_name)
			return result

	if data.has("event"):
		result.event_name = data["event"]

	return result
