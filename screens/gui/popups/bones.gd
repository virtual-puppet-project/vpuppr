extends BasePopupTreeLayout

const BoneDisplay = preload("res://screens/gui/popups/bone_display.gd")

const INFO_PAGE := "Info"

var info: ScrollContainer

var model: Node

###############################################################################
# Builtin functions                                                           #
###############################################################################

func _setup() -> void:
	info = $Info
	
	_initial_page = INFO_PAGE
	
	tree.hide_root = true
	var root: TreeItem = tree.create_item()
	
	pages[INFO_PAGE] = info
	
	var info_item: TreeItem = tree.create_item(root)
	info_item.set_text(TREE_COLUMN, INFO_PAGE)
	info_item.select(TREE_COLUMN)
	_toggle_page(INFO_PAGE)

	tree.connect("item_selected", self, "_on_item_selected")

	model = get_tree().current_scene.get("model")
	if model == null:
		printerr("No model found, no bone functionality will be available")
		return

	var model_skeleton = model.get("skeleton")
	if model_skeleton == null:
		printerr("No model skeleton found, no bone functionality will be available")
		return

	# Store all references to TreeItems, discard afterwards
	var known_bones := {}

	for bone_idx in model_skeleton.get_bone_count():
		var bone_name: String = model_skeleton.get_bone_name(bone_idx)
		var bone_parent_id: int = model_skeleton.get_bone_parent(bone_idx)

		var parent_item: TreeItem = root if bone_parent_id < 0 else known_bones[model_skeleton.get_bone_name(bone_parent_id)]

		var item: TreeItem = tree.create_item(parent_item)
		item.set_text(TREE_COLUMN, bone_name)

		known_bones[bone_name] = item
		
		var bone_page := BoneDisplay.new(bone_name)
		pages[bone_name] = bone_page
		
		add_child(bone_page)

		bone_page.connect("is_tracking_set", self, "_on_is_tracking")
		bone_page.connect("should_pose_set", self, "_on_should_pose")
		bone_page.connect("should_use_custom_interpolation_set", self, "_on_should_use_custom_interpolation")
		bone_page.connect("interpolation_rate_set", self, "_on_interpolation_rate")

		_connect_element(bone_page.is_tracking_button)
		_connect_element(bone_page.should_pose_button)
		_connect_element(bone_page.should_use_custom_interpolation)
		_connect_element(bone_page.interpolation_rate)

###############################################################################
# Connections                                                                 #
###############################################################################

func _on_is_tracking(bone_name: String, state: bool) -> void:
	var additional_bones = AM.cm.get_data("additional_bones")
	if additional_bones == null:
		# TODO might not be an error
		return

	var bone_id: int = model.skeleton.find_bone(bone_name)
	if bone_id < 0:
		logger.error("Bone %s not found, aborting config modification" % bone_name)
		return
	
	if state:
		additional_bones[bone_name] = bone_id
	else:
		additional_bones[bone_name].erase(bone_id)

func _on_should_pose(bone_name: String, state: bool) -> void:
	# TODO nothing needs to be set in model config from here, only after posing
	pass

func _on_should_use_custom_interpolation(bone_name: String, state: bool) -> void:
	var bones_to_interpolate = AM.cm.get_data("bones_to_interpolate")
	if bones_to_interpolate == null:
		# TODO might not be an error
		return

	var bone_id: int = model.skeleton.find_bone(bone_name)
	if bone_id < 0:
		logger.error("Bone %s not found, aborting config modification" % bone_name)
		return
	
	if state and not bones_to_interpolate.has(bone_id):
		bones_to_interpolate.append(bone_id)
	else:
		bones_to_interpolate.erase(bone_id)

func _on_interpolation_rate(bone_name: String, rate: float) -> void:
	var bone_interpolation_rate_dict = AM.cm.get_data("bone_interpolation_rates")
	if bone_interpolation_rate_dict == null:
		# TODO maybe this shouldn't be an error
		return

	bone_interpolation_rate_dict[bone_name] = rate
	AM.save_config()

###############################################################################
# Private functions                                                           #
###############################################################################

###############################################################################
# Public functions                                                            #
###############################################################################
