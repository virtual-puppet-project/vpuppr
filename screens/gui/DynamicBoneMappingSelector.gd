extends MarginContainer

#const CHECK_BOX_LABEL: Resource = preload("res://screens/gui/elements/CheckBoxLabel.tscn")
const CHECK_BOX_LABEL: Resource = preload("res://screens/gui/elements/DoubleCheckBoxLabel.tscn")

onready var v_box_container: VBoxContainer = $Control/MarginContainer/VBoxContainer/ScrollContainer/VBoxContainer

var current_model: BasicModel
# Whether or not the bones are currently being tracked
var initial_bone_state: Array

###############################################################################
# Builtin functions                                                           #
###############################################################################

func _ready() -> void:
	connect("visibility_changed", self, "_on_visibility_changed")
	
	AppManager.connect("model_loaded", self, "_on_model_loaded")
	
	$Control/MarginContainer/VBoxContainer/HBoxContainer/ApplyControl/MarginContainer/ApplyButton.connect("pressed", self, "_on_apply_button_pressed")
	$Control/MarginContainer/VBoxContainer/HBoxContainer/ResetControl/MarginContainer/ResetButton.connect("pressed", self, "_on_reset_button_pressed")

###############################################################################
# Connections                                                                 #
###############################################################################

func _on_visibility_changed() -> void:
	match self.visible:
		true:
			pass
		false:
			pass

func _on_model_loaded(model_reference: BasicModel) -> void:
	current_model = model_reference
	initial_bone_state = current_model.additional_bones_to_pose_names
	
	_generate_bone_list()

func _on_apply_button_pressed() -> void:
	_trigger_bone_remap()

func _on_reset_button_pressed() -> void:
	_reset_bone_values()

###############################################################################
# Private functions                                                           #
###############################################################################

func _generate_bone_list() -> void:
	for child in v_box_container.get_children():
		child.free()
	
	var bone_values = current_model.get_mapped_bones()
	for bone_name in bone_values.keys():
		var check_box_label = CHECK_BOX_LABEL.instance()
		check_box_label.check_box_text = "Mapping"
		check_box_label.second_check_box_text = "Physics"
		# Don't allow the user to disable head bone tracking
		if bone_name == current_model.HEAD_BONE:
			check_box_label.label_text = bone_name + " (not editable)"
			check_box_label.check_box_disabled = true
			check_box_label.second_check_box_disabled = true
		else:
			check_box_label.label_text = bone_name
			check_box_label.check_box_value = bone_values[bone_name]
		v_box_container.add_child(check_box_label)

func _trigger_bone_remap() -> void:
	var new_bones: Array = []
	for child in v_box_container.get_children():
		if child.check_box.pressed:
			new_bones.append(child.label.text)
	
	current_model.additional_bones_to_pose_names = new_bones
	current_model.scan_mapped_bones()

func _reset_bone_values() -> void:
	current_model.additional_bones_to_pose_names = initial_bone_state
	current_model.reset_all_bone_poses()
	_generate_bone_list()

###############################################################################
# Public functions                                                            #
###############################################################################


