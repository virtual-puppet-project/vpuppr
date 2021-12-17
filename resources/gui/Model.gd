extends Control

func setup() -> void:
	print("this is a test print in Model.gd. Extend this by modifying resources/gui/Model.gd")
	pass

func setup_mapped_bones(element: Control) -> void:
	var gui = element.parent

	element.clear_details()
	
	var head_bone_name: String = AppManager.cm.current_model_config.head_bone
	for bone_i in gui.model.skeleton.get_bone_count():
		var bone_name: String = gui.model.skeleton.get_bone_name(bone_i)
		var elem: BaseElement = gui.generate_ui_element(
			gui.XmlConstants.DOUBLE_TOGGLE,
			{
				"name": bone_name,
				"event": "bone_toggled"
			}
		)
		elem.toggle1_label = gui.DoubleToggleConstants.TRACK
		if bone_name in AppManager.cm.current_model_config.mapped_bones:
			elem.toggle1_value = true

		if bone_name == head_bone_name:
			elem.is_disabled = true

		elem.toggle2_label = gui.DoubleToggleConstants.POSE
		
		element.vbox.call_deferred("add_child", elem)

var model

var a_pose_element

func setup_a_pose(element: Control) -> void:
	if not AppManager.sb.is_connected("model_loaded", self, "_on_model_loaded_a_pose"):
		AppManager.sb.connect("model_loaded", self, "_on_model_loaded_a_pose")
	
	a_pose_element = element

	var gui = element.parent
	_on_model_loaded_a_pose(gui.model)

func _on_model_loaded_a_pose(p_model) -> void:
	if model != p_model:
		model = p_model

	if model.get("vrm_meta") != null:
		a_pose_element.show()
	else:
		a_pose_element.hide()

var t_pose_element
var initial_t_pose_label_text: String

func setup_t_pose(element: Control) -> void:
	if not AppManager.sb.is_connected("model_loaded", self, "_on_model_loaded_t_pose"):
		AppManager.sb.connect("model_loaded", self, "_on_model_loaded_t_pose")
	
	t_pose_element = element
	initial_t_pose_label_text = t_pose_element.label_text

	var gui = element.parent
	_on_model_loaded_t_pose(gui.model)

func _on_model_loaded_t_pose(p_model) -> void:
	if model != p_model:
		model = p_model

	if model.get("vrm_meta") != null:
		t_pose_element.button.text = initial_t_pose_label_text
	else:
		t_pose_element.button.text = "Reset pose"
