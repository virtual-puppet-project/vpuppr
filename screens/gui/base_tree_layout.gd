class_name BaseTreeLayout
extends BaseLayout

const TREE_COLUMN: int = 0
const TREE_MIN_X: int = 200

var tree: Tree setget _set_tree

class Page extends Reference:
	var control: Control
	var tree_item: TreeItem

	func _init(p_control: Control, p_tree_item: TreeItem) -> void:
		control = p_control
		tree_item = p_tree_item

	## Deletes the contained objects. Only needs to be called when modifying objects
	## without changing the current_scene
	func delete() -> void:
		control.queue_free()
		tree_item.free()

## Page name: String -> Page
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

	tree.hide_root = true
	var root: TreeItem = tree.create_item()

	for child in get_children():
		if child == tree:
			continue
		
		var page_name: String = child.name.capitalize()

		var item := tree.create_item(root)
		item.set_text(TREE_COLUMN, page_name)

		pages[page_name] = Page.new(child, item)
		child.hide()

	pages[_initial_page].tree_item.select(TREE_COLUMN)
	_toggle_page(_initial_page)
	
	tree.connect("item_selected", self, "_on_item_selected")

	return Result.ok()

func _teardown() -> void:
	pages.clear()

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
	tree.rect_min_size.x = TREE_MIN_X

func _toggle_page(page_name: String) -> void:
	if page_name.empty():
		return
	if current_page != null:
		current_page.hide()
	
	current_page = pages[page_name].control
	current_page.show()

#-----------------------------------------------------------------------------#
# Public functions                                                            #
#-----------------------------------------------------------------------------#
