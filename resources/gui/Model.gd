extends Control

func setup() -> void:
	print("this is a test print in Model.gd. Extend this by modifying resources/gui/Model.gd")
	pass

func setup_mapped_bones(element: Control) -> void:
	var parent = element.parent

	element.clear_details()
	
	var head_bone_name: String = AppManager.cm.current_model_config.head_bone
	for bone_i in parent.model.skeleton.get_bone_count():
		var bone_name: String = parent.model.skeleton.get_bone_name(bone_i)
		var elem: BaseElement = parent.generate_ui_element(
			parent.XmlConstants.DOUBLE_TOGGLE,
			{
				"name": bone_name,
				"event": "bone_toggled"
			}
		)
		elem.toggle1_label = parent.DoubleToggleConstants.TRACK
		if bone_name in AppManager.cm.current_model_config.mapped_bones:
			elem.toggle1_value = true

		if bone_name == head_bone_name:
			elem.is_disabled = true

		elem.toggle2_label = parent.DoubleToggleConstants.POSE
		
		element.vbox.call_deferred("add_child", elem)
