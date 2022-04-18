class_name BasePopupTreeLayout
extends Control

const TREE_COLUMN: int = 0

onready var tree = $Tree as Tree

var pages := {}

var current_page: Control
var _initial_page := ""

###############################################################################
# Builtin functions                                                           #
###############################################################################

func _ready() -> void:
	_setup()

func _setup() -> void:
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

###############################################################################
# Connections                                                                 #
###############################################################################

func _on_item_selected() -> void:
	var page_name: String = tree.get_selected().get_text(tree.get_selected_column())
	
	_toggle_page(page_name)

###############################################################################
# Private functions                                                           #
###############################################################################

func _toggle_page(page_name: String) -> void:
	if page_name.empty():
		return
	if current_page != null:
		print("hiding %s" % current_page.name)
		current_page.hide()
	
	current_page = pages[page_name]
	current_page.show()

	print("showing %s" % current_page.name)

###############################################################################
# Public functions                                                            #
###############################################################################
