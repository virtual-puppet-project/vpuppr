extends CanvasLayer

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
	"INPUT": "input",
	"BUTTON": "button",

	# Attribute names
	"NAME": "name",
	"DATA": "data",
	"EVENT": "event",
	"VALUE": "value",
	"TYPE": "type",

	"SCRIPT": "script"
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

onready var button_bar_hbox: HBoxContainer = $ButtonBar/HBoxContainer

var base_path: String

###############################################################################
# Builtin functions                                                           #
###############################################################################

func _ready() -> void:
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
						
						var file := File.new()
						if file.open("%s/%s" % [base_path, data.data["script"]], File.READ) != OK:
							AppManager.log_message("Failed to open script", true)

						var script: Script = base_view.get_script()
						script.source_code = file.get_as_text()
						base_view.set_script(null)
						script.reload()
						base_view.set_script(script)
					_:
						var element: Control = _generate_ui_element(data.node_name, data.data)
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
		button.text = xml_file.get_file()
		# TODO connect this to some toggling logic
		button_bar_hbox.call_deferred("add_child", button)

		base_view.setup()

###############################################################################
# Connections                                                                 #
###############################################################################

###############################################################################
# Private functions                                                           #
###############################################################################

static func _generate_ui_element(tag_name: String, data: Dictionary) -> BaseElement:
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
		XmlConstants.TOGGLE:
			result = ToggleElement.instance()
			result.name = node_name
			result.label_text = display_name
		XmlConstants.INPUT:
			result = InputElement.instance()
			result.name = node_name
			result.label_text = display_name
		XmlConstants.BUTTON:
			result = ButtonElement.instance()
			result.name = node_name
			result.label_text = display_name
		_:
			AppManager.log_message("Unhandled tag_name: %s" % tag_name)
			return result

	return result

###############################################################################
# Public functions                                                            #
###############################################################################


