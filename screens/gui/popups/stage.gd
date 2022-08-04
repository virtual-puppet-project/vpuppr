extends BaseTreeLayout

enum StageItem {
	NONE = 0,

	LIGHT,
	CAMERA,
	WORLD
}

#-----------------------------------------------------------------------------#
# Builtin functions                                                           #
#-----------------------------------------------------------------------------#

func _setup() -> Result:
	_initial_page = "Info"

	var stage: Dictionary = get_tree().current_scene.get_stage()
	for item_name in stage.keys():
		var item = stage[item_name]

		var sc := ScrollContainer.new()
		ControlUtil.h_expand_fill(sc)
		sc.name = item_name.capitalize()
		
		add_child(sc)

		var vb := VBoxContainer.new()
		ControlUtil.all_expand_fill(vb)

		sc.add_child(vb)

		if item is Light:
			_create_elements(vb, item, Globals.IGNORED_SPATIAL_PROPERTIES, StageItem.LIGHT)
		elif item is Camera:
			_create_elements(vb, item, Globals.IGNORED_SPATIAL_PROPERTIES, StageItem.CAMERA)
		elif item is World:
			_create_elements(vb, item.environment, Globals.IGNORED_RESOURCE_PROPERTIES, StageItem.WORLD)
		else: # TODO seems like this could be improved
			logger.error("Unhandled stage item: %s" % str(item))
			continue
	
	return ._setup()

#-----------------------------------------------------------------------------#
# Connections                                                                 #
#-----------------------------------------------------------------------------#

#-----------------------------------------------------------------------------#
# Private functions                                                           #
#-----------------------------------------------------------------------------#

func _handle_property(prop_name: String, prop) -> Control:
	match typeof(prop):
		TYPE_REAL, TYPE_INT:
			var hbox := HBoxContainer.new()
			ControlUtil.h_expand_fill(hbox)

			var label := Label.new()
			ControlUtil.h_expand_fill(label)
			label.text = prop_name

			hbox.add_child(label)

			var line_edit := LineEdit.new()
			ControlUtil.h_expand_fill(line_edit)
			line_edit.text = str(prop)

			hbox.add_child(line_edit)

			return hbox
		TYPE_BOOL:
			var check_button := CheckButton.new()
			ControlUtil.h_expand_fill(check_button)
			check_button.pressed = prop
			check_button.text = prop_name

			return check_button
		TYPE_COLOR:
			var hbox := HBoxContainer.new()
			ControlUtil.h_expand_fill(hbox)

			var label := Label.new()
			ControlUtil.h_expand_fill(label)
			label.text = prop_name

			hbox.add_child(label)

			var color_picker_button := ColorPickerButton.new()
			ControlUtil.h_expand_fill(color_picker_button)
			color_picker_button.color = prop

			hbox.add_child(color_picker_button)

			return hbox
		TYPE_VECTOR2:
			return null
		TYPE_VECTOR3:
			return null
		_:
			return null

func _create_elements(vbox: VBoxContainer, obj: Object, ignore_list: Array, type: int) -> void:
	for prop in obj.get_property_list():
		if prop.name in ignore_list:
			continue

		var display_name: String = prop.name.capitalize()
		var config_name := ""
		match type:
			StageItem.LIGHT:
				config_name = "stage_light_%s" % prop.name
			StageItem.CAMERA:
				config_name = "stage_camera_%s" % prop.name
			StageItem.WORLD:
				config_name = "stage_world_%s" % prop.name
			_:
				logger.error("Unhandled stage item: %s" % prop.name)

		var control: Control = _handle_property(display_name, obj.get(prop.name))
		if control == null:
			continue

		control.name = display_name
		_connect_element(control if control is CheckButton else control.get_child(1), config_name)

		vbox.add_child(control)

#-----------------------------------------------------------------------------#
# Public functions                                                            #
#-----------------------------------------------------------------------------#
