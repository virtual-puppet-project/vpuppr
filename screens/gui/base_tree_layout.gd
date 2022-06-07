class_name BaseTreeLayout
extends BaseLayout

const TREE_COLUMN: int = 0

var tree: Tree

var pages := {}

var current_page: Control
var _initial_page := ""

#-----------------------------------------------------------------------------#
# Builtin functions                                                           #
#-----------------------------------------------------------------------------#

func _setup() -> void:
	tree = $Tree

	for child in get_children():
		if child == tree:
			continue
		pages[child.name] = child
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

#-----------------------------------------------------------------------------#
# Connections                                                                 #
#-----------------------------------------------------------------------------#

func _on_item_selected() -> void:
	var page_name: String = tree.get_selected().get_text(tree.get_selected_column())
	
	_toggle_page(page_name)

#-----------------------------------------------------------------------------#
# Private functions                                                           #
#-----------------------------------------------------------------------------#

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
