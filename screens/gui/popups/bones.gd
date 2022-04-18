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

###############################################################################
# Connections                                                                 #
###############################################################################

# func _on_item_selected() -> void:
# 	var page_name: String = tree.get_selected().get_text(tree.get_selected_column())
	
# 	if current_page == info:
# 		_toggle_page(page_name)
# 		return
	
# 	# Handle bones
# 	# current_page.reset_buttons()

# 	_toggle_page(page_name)

###############################################################################
# Private functions                                                           #
###############################################################################

###############################################################################
# Public functions                                                            #
###############################################################################
