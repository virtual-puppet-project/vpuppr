extends BaseSidebar

const BASIC_PHYSICS_ATTACHMENT: Resource = preload("res://entities/physics/BasicPhysicsAttachment.tscn")
const DOUBLE_CHECK_BOX_LABEL: Resource = preload("res://screens/gui/elements/DoubleCheckBoxLabel.tscn")

# Whether or not the bones are currently being tracked, allows for resetting pose
var initial_bone_state: Array = []

# TODO Do I even need to reference count?
class LoadedPhysicsBone:
	var bone_name: String
	var bone_id: int
	var is_static: bool
	var loaded_children_names: Array # String

	func _init(p_name: String, p_id: int, p_is_static: bool) -> void:
		bone_name = p_name
		bone_id = p_id
		is_static = p_is_static
		loaded_children_names = []

var loaded_physics_bones: Array = [] # LoadedPhysicsBone

###############################################################################
# Builtin functions                                                           #
###############################################################################

###############################################################################
# Connections                                                                 #
###############################################################################

func _on_model_loaded(model_reference: BasicModel) -> void:
	._on_model_loaded(model_reference)
	initial_bone_state = current_model.additional_bones_to_pose_names
	
	# TODO right now the custom build with skeleton fixes is breaking dynamic physics bones
	# Generate all physics bones at the start instead of
	# manually reference counting them
#	var bone_values = current_model.get_mapped_bones()
#	for bone_name in bone_values.keys():
#		_create_physics_bone(current_model.skeleton.find_bone(bone_name), bone_name)
#		yield(get_tree(), "physics_frame")

	loaded_physics_bones.clear()
	
	_generate_bone_list()
	
	AppManager.push_log("Model loaded.")

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
	
	# TODO test this with a vrm model
	# yield(get_tree().create_timer(1.0), "timeout")
	
	var bone_values = current_model.get_mapped_bones()
	for bone_name in bone_values.keys():
		var check_box_label: Control
		# TODO better control flow is possible here
		if AppManager.DYNAMIC_PHYSICS_BONES:
			check_box_label = DOUBLE_CHECK_BOX_LABEL.instance()
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
		else:
			check_box_label = CHECK_BOX_LABEL.instance()
			check_box_label.check_box_text = "Mapping"
			if bone_name == current_model.HEAD_BONE:
				check_box_label.label_text = bone_name + " (not editable)"
				check_box_label.check_box_disabled = true
			else:
				check_box_label.label_text = bone_name
				check_box_label.check_box_value = bone_values[bone_name]
		v_box_container.add_child(check_box_label)

func _trigger_bone_remap() -> void:
	var new_bone_list: Array = [] # String
	var new_physics_bone_list: Array = [] # String
	for child in v_box_container.get_children():
		if child.check_box.pressed:
			new_bone_list.append(child.label.text)
		if(child.get("second_check_box") and child.second_check_box.pressed):
			new_physics_bone_list.append(child.label.text)
	
	###
	# Handle bone mapping
	###
	current_model.additional_bones_to_pose_names = new_bone_list
	current_model.scan_mapped_bones()
	
	###
	# Handle adding physics bones
	###
	# var dynamic_physics_bones_names: Array = []
	# for pb in loaded_physics_bones:
	# 	if not pb.is_static:
	# 		dynamic_physics_bones_names.append(pb.bone_name)

	# var bones_to_add: Array = _only_in_first_array(new_physics_bone_list,
	# 		dynamic_physics_bones_names) # String
	# var bones_to_remove: Array = _only_in_first_array(dynamic_physics_bones_names,
	# 		new_physics_bone_list) # String

	# current_model.skeleton.physical_bones_stop_simulation()

	# var queued_bones_to_remove: Array = [] # String
	
	# # Don't remove physics bones yet since a bone might be a static parent bone
	# for b in bones_to_remove:
	# 	var bone_node: Node = current_model.skeleton.get_node_or_null(b)
	# 	if bone_node and bone_node is BasicPhysicsAttachment:
	# 		for pb in loaded_physics_bones:
	# 			if pb.bone_name == b:
	# 				queued_bones_to_remove.append(b)
	# 			elif b in pb.loaded_children_names:
	# 				pb.loaded_children_names.erase(b)

	# # If a bone is queued for removal and has no children, it should be removed
	# # If a bone is queued for removal but still has children, change it to static
	# var loaded_physics_bones_to_remove: Array = []
	# for pb in loaded_physics_bones:
	# 	if pb.is_static:
	# 		if pb.loaded_children_names.empty():
	# 			# Parent bone has no references to it, so it should be removed
	# 			queued_bones_to_remove.erase(pb.bone_name)
	# 			loaded_physics_bones_to_remove.append(pb)
	# 			current_model.skeleton.get_node(pb.bone_name).free()
	# 	else: # not pb.is_static
	# 		if pb.bone_name in queued_bones_to_remove:
	# 			if not pb.loaded_children_names.empty():
	# 				# Remove bone from physics simulation but do not free it because
	# 				# there are still references to it
	# 				queued_bones_to_remove.erase(pb.bone_name)
	# 				pb.is_static = true
	# 			else:
	# 				# This bone is a child bone with no children so it can be
	# 				# safely removed
	# 				queued_bones_to_remove.erase(pb.bone_name)
	# 				loaded_physics_bones_to_remove.append(pb)
	# 				current_model.skeleton.get_node(pb.bone_name).free()
	
	# for pb in loaded_physics_bones_to_remove:
	# 	loaded_physics_bones.erase(pb)
	
	# for b in bones_to_add:
	# 	var bone_id: int = current_model.skeleton.find_bone(b)
	# 	var bone_parent_id: int = current_model.skeleton.get_bone_parent(bone_id)

	# 	# Value of -1 indicates no parent
	# 	if bone_parent_id > 0:
	# 		var is_parent_loaded: bool = false
	# 		for pb in loaded_physics_bones:
	# 			if pb.bone_id == bone_parent_id:
	# 				is_parent_loaded = true
	# 				pb.loaded_children_names.append(b)
	# 				break

	# 		if not is_parent_loaded:
	# 			var bone_parent_name: String = current_model.skeleton.get_bone_name(bone_parent_id)
	# 			_create_physics_bone(bone_parent_id, bone_parent_name)
	# 			var loaded_physics_bone: LoadedPhysicsBone = LoadedPhysicsBone.new(bone_parent_name, bone_parent_id, true)
	# 			loaded_physics_bone.loaded_children_names.append(b)
	# 			loaded_physics_bones.append(loaded_physics_bone)

	# 	var is_loaded: bool = false
	# 	for pb in loaded_physics_bones:
	# 		if pb.bone_id == bone_id:
	# 			pb.is_static = false
	# 			is_loaded = true
	# 			break

	# 	if not is_loaded:
	# 		_create_physics_bone(bone_id, b)
	# 		loaded_physics_bones.append(LoadedPhysicsBone.new(b, bone_id, false))

	# var bones_to_simulate: Array = []
	# for pb in loaded_physics_bones:
	# 	if not pb.is_static:
	# 		bones_to_simulate.append(pb.bone_name)

	# current_model.skeleton.physical_bones_start_simulation(bones_to_simulate)
	current_model.skeleton.physical_bones_start_simulation(new_physics_bone_list)

func _reset_bone_values() -> void:
	current_model.additional_bones_to_pose_names = initial_bone_state
	current_model.reset_all_bone_poses()
	_generate_bone_list()

func _create_physics_bone(bone_id: int, bone_name: String) -> void:
	var basic_physics_attachment = BASIC_PHYSICS_ATTACHMENT.instance()
	basic_physics_attachment.bone_name = bone_name
	basic_physics_attachment.name = bone_name
	# basic_physics_attachment.body_offset = current_model.skeleton.get_bone_pose(bone_id)
	# basic_physics_attachment.transform = current_model.skeleton.get_bone_global_pose(bone_id)
	basic_physics_attachment.transform = current_model.skeleton.get_bone_pose(bone_id)
	# current_model.skeleton.add_child(basic_physics_attachment)
	current_model.skeleton.call_deferred("add_child", basic_physics_attachment)

static func _only_in_first_array(array_1: Array, array_2: Array) -> Array:
	var only_in_array_1: Array = []

	for v in array_1:
		if not v in array_2:
			only_in_array_1.append(v)

	return only_in_array_1

###############################################################################
# Public functions                                                            #
###############################################################################


