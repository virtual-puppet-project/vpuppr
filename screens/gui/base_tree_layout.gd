class_name BaseTreeLayout
extends BaseLayout

const TREE_COLUMN: int = 0
const SPLIT_OFFSET_RATIO: float = 0.3

var tree: Tree setget _set_tree

## Page name: String -> Control
var pages := {}

var current_page: Control
var _initial_page := ""

#-----------------------------------------------------------------------------#
# Builtin functions                                                           #
#-----------------------------------------------------------------------------#

func _pre_setup() -> Result:
	yield(_wait_for_parent(), "completed")

	return Result.ok()

func _setup() -> Result:
	_set_tree($Tree)

	for child in get_children():
		if child == tree:
			continue
		pages[child.name.capitalize()] = child
		child.hide()
	
	tree.hide_root = true
	var root: TreeItem = tree.create_item()
	
	for page_name in pages.keys():
		var item: TreeItem = tree.create_item(root)
		item.set_text(TREE_COLUMN, page_name)
		
		if page_name == _initial_page:
			item.select(TREE_COLUMN)
			_toggle_page(page_name)
	
	tree.connect("item_selected", self, "_on_item_selected")

	return Result.ok()

#-----------------------------------------------------------------------------#
# Connections                                                                 #
#-----------------------------------------------------------------------------#

func _on_item_selected() -> void:
	var page_name: String = tree.get_selected().get_text(tree.get_selected_column())
	
	_toggle_page(page_name)

#-----------------------------------------------------------------------------#
# Private functions                                                           #
#-----------------------------------------------------------------------------#

func _wait_for_parent() -> int:
	emit_signal("ready")
	yield(get_parent(), "ready")
	yield(get_tree(), "idle_frame")
	
	return OK

func _set_tree(p_tree: Tree) -> void:
	tree = p_tree

	if not self.is_class("SplitContainer"):
		logger.debug("Tried to set split_offset, but %s was not a SplitContainer" % name)
		return

	var parent: Node = get_parent()
	if not parent.is_class("Control"):
		logger.debug("%s's parent was not a Control, using window size for split_offset comparison" % name)
		set("split_offset", OS.window_size * SPLIT_OFFSET_RATIO)
	else:
		set("split_offset", parent.rect_size.x * SPLIT_OFFSET_RATIO)

func _toggle_page(page_name: String) -> void:
	if page_name.empty():
		return
	if current_page != null:
		current_page.hide()
	
	current_page = pages[page_name]
	current_page.show()

#-----------------------------------------------------------------------------#
# Public functions                                                            #
#-----------------------------------------------------------------------------#
