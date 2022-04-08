extends WindowDialog

signal selected(instanced_gui)

onready var options_list = $MarginContainer/VBoxContainer as VBoxContainer

###############################################################################
# Builtin functions                                                           #
###############################################################################

func _ready() -> void:
	for i in ["popup_hide", "hide"]:
		connect(i, self, "_terminate")

	var default_gui_button := Button.new()
	default_gui_button.name = "DefaultGui"
	default_gui_button.text = "Default Gui"
	default_gui_button.connect(
		"pressed",
		self,
		"_on_gui_button_pressed",
		[GlobalConstants.DEFAULT_GUI_PATH]
	)

	options_list.add_child(default_gui_button)
	
	for i in AM.em.query_extensions_for_type(GlobalConstants.ExtensionTypes.GUI):
		var button := Button.new()
		button.name = i.resource_name
		button.text = i.resource_name
		button.connect(
			"pressed",
			self,
			"_on_gui_button_pressed",
			[i.resource_entrypoint]
		)

		options_list.add_child(button)

###############################################################################
# Connections                                                                 #
###############################################################################

func _on_gui_button_pressed(path: String) -> void:
	var gui = load(path)
	if gui is PackedScene:
		gui = gui.instance()
	else:
		gui = gui.new()
	
	emit_signal("selected", gui)
	queue_free()

func _terminate() -> void:
	queue_free()

###############################################################################
# Private functions                                                           #
###############################################################################

###############################################################################
# Public functions                                                            #
###############################################################################
