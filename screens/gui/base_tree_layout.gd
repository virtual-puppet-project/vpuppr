class_name BaseTreeLayout
extends BaseLayout

const TREE_COLUMN: int = 0
const TREE_MIN_X: int = 200

var tree: Tree setget _set_tree

class Page:
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

	return Safely.ok()

func _setup() -> Result:
	_set_tree($Tree)

	tree.hide_root = true
	tree.create_item()

	var res := Safely.wrap(_build_tree())
	if res.is_err():
		return res
	
	tree.connect("item_selected", self, "_on_item_selected")

	return Safely.ok()

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

## Builds the entire tree
##
## @param: excludes: PoolStringArray - Node names to exclude
##
## @return: Result<Error> - The error code
func _build_tree(excludes: PoolStringArray = []) -> Result:
	var root := tree.get_root()
	if root == null:
		return Safely.err(Error.Code.BASE_TREE_LAYOUT_NO_ROOT_TREE_ITEM)

	for child in get_children():
		if child == tree:
			continue
		
		var page_name: String = child.name.capitalize()
		if page_name in excludes:
			continue

		var item := tree.create_item(root)
		item.set_text(TREE_COLUMN, page_name)

		pages[page_name] = Page.new(child, item)
		child.hide()

	pages[_initial_page].tree_item.select(TREE_COLUMN)
	_toggle_page(_initial_page)

	return Safely.ok()

## Clears the entire Tree of TreeItems
##
## @return: Result<Error> - The error code
func _clear_tree() -> Result:
	var root := tree.get_root()
	if root == null:
		return Safely.err(Error.Code.BASE_TREE_LAYOUT_NO_ROOT_TREE_ITEM)

	var tree_item := root.get_children()
	if tree_item == null:
		return Safely.ok()

	while tree_item != null:
		var old_tree_item := tree_item
		tree_item = tree_item.get_next()

		old_tree_item.free()
	
	pages.clear()

	return Safely.ok()

## Finds a TreeItem in the Tree
##
## @param: item_name: String - The TreeItem text to match against
##
## @return: Result<TreeItem> - The matching TreeItem
func _find_tree_item(item_name: String) -> Result:
	var root := tree.get_root()
	if root == null:
		return Safely.err(Error.Code.BASE_TREE_LAYOUT_NO_ROOT_TREE_ITEM)
	
	var tree_item := root.get_children()
	if tree_item == null:
		return Safely.err(Error.Code.LANDING_SCREEN_TREE_ITEM_NOT_FOUND, item_name)
	
	while tree_item != null:
		if tree_item.get_text(TREE_COLUMN) == item_name:
			return Safely.ok(tree_item)

	return Safely.err(Error.Code.LANDING_SCREEN_TREE_ITEM_NOT_FOUND, item_name)

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
