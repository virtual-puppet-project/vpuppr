extends CanvasLayer

class ExtensionItem extends PanelContainer:
	const SHOW_IN_FILESYSTEM := "Show in filesystem"

	var _ext_data := {}

	var popup: PopupMenu

	func _init(p_extension_data: Dictionary) -> void:
		_ext_data = p_extension_data

		ControlUtil.all_expand_fill(self)
		
		var vbox := VBoxContainer.new()
		
		var margin_container := MarginContainer.new()
		
		vbox.add_child(margin_container)
		
		var name_label := Label.new()
		name_label.text = _ext_data["extension_name"]
		name_label.align = Label.ALIGN_CENTER
		
		margin_container.add_child(name_label)
		
		var menu_button := MenuButton.new()
		menu_button.size_flags_horizontal = Control.SIZE_SHRINK_END
		menu_button.flat = true
		menu_button.text = ":"
		popup = menu_button.get_popup()
		popup.add_item(SHOW_IN_FILESYSTEM)

		popup.connect("index_pressed", self, "_on_menu_idx_pressed")
		
		margin_container.add_child(menu_button)
		
		var context_path_label := Label.new()
		context_path_label.align = Label.ALIGN_CENTER
		context_path_label.text = _ext_data["context_path"]
		
		vbox.add_child(context_path_label)
		
		var h_separator := HSeparator.new()
		
		vbox.add_child(h_separator)
		
		add_child(vbox)

		for section in Globals.ExtensionTypes.values():
			if _ext_data.get(section, []).empty():
				continue

			var section_hbox := HBoxContainer.new()
			var section_label := Label.new()
			ControlUtil.h_expand_fill(section_label)
			section_label.text = section.capitalize()

			section_hbox.add_child(section_label)
			section_hbox.add_child(VSeparator.new())

			var section_vbox := VBoxContainer.new()
			ControlUtil.h_expand_fill(section_vbox)
			for i in _ext_data[section]:
				var label := Label.new()
				label.text = i
				section_vbox.add_child(label)

			section_hbox.add_child(section_vbox)

			vbox.add_child(section_hbox)
			vbox.add_child(HSeparator.new())

	func _on_menu_idx_pressed(idx: int) -> void:
		match popup.get_item_text(idx):
			SHOW_IN_FILESYSTEM:
				OS.shell_open(_ext_data["context_path"])

#-----------------------------------------------------------------------------#
# Builtin functions                                                           #
#-----------------------------------------------------------------------------#

func _ready() -> void:
	var extensions := $RootControl/TabContainer/Extensions/ScrollContainer/ExtensionsList as VBoxContainer

	for key in AM.em.extensions.keys():
		var extension_item := ExtensionItem.new(AM.em.extensions[key].as_data())
		extensions.add_child(extension_item)

#-----------------------------------------------------------------------------#
# Connections                                                                 #
#-----------------------------------------------------------------------------#

#-----------------------------------------------------------------------------#
# Private functions                                                           #
#-----------------------------------------------------------------------------#

#-----------------------------------------------------------------------------#
# Public functions                                                            #
#-----------------------------------------------------------------------------#
