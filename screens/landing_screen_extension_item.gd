extends PanelContainer

const SECTIONS := [
	"runners",
	"puppets",
	"trackers",
	"guis",
	"plugins"
]

const SHOW_IN_FILESYSTEM := "Show in filesystem"

var extension_data := {}

var popup: PopupMenu

#-----------------------------------------------------------------------------#
# Builtin functions                                                           #
#-----------------------------------------------------------------------------#

func _ready() -> void:
	$VBoxContainer/MarginContainer/ExtensionName.text = extension_data["extension_name"]
	$VBoxContainer/ContextPath.text = extension_data["context_path"]
	
	popup = $VBoxContainer/MarginContainer/MenuButton.get_popup()
	popup.add_item(SHOW_IN_FILESYSTEM)
	
	popup.connect("index_pressed", self, "_on_menu_idx_pressed")
	
	var list = $VBoxContainer
	
	for section in SECTIONS:
		if not extension_data.has(section) or extension_data[section].empty():
			continue
		
		var hbox := HBoxContainer.new()
		var section_label := Label.new()
		section_label.size_flags_horizontal = Control.SIZE_EXPAND_FILL
		section_label.text = section.capitalize()
		
		hbox.add_child(section_label)
		hbox.add_child(VSeparator.new())
		
		var vbox := VBoxContainer.new()
		vbox.size_flags_horizontal = Control.SIZE_EXPAND_FILL
		for i in extension_data[section]:
			var label := Label.new()
			label.text = i
			vbox.add_child(label)
		
		hbox.add_child(vbox)
		
		list.add_child(hbox)
		list.add_child(HSeparator.new())

#-----------------------------------------------------------------------------#
# Connections                                                                 #
#-----------------------------------------------------------------------------#

func _on_menu_idx_pressed(idx: int) -> void:
	match popup.get_item_text(idx):
		SHOW_IN_FILESYSTEM:
			OS.shell_open(extension_data["context_path"])

#-----------------------------------------------------------------------------#
# Private functions                                                           #
#-----------------------------------------------------------------------------#

func _add_labels_to_list_from_data(list: Control, data: Array) -> void:
	for i in data:
		var label := Label.new()
		label.text = i
		label.align = Label.ALIGN_CENTER
		
		list.add_child(label)

#-----------------------------------------------------------------------------#
# Public functions                                                            #
#-----------------------------------------------------------------------------#
