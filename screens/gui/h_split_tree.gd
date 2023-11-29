class_name HSplitTree
extends HSplitContainer

## An [HSplitContainer] that expects a [Tree] and [ScrollContainer].
##
## Helper class that automatically resizes the [HSplitContainer] according to its
## window size. Expects a [Tree] and [ScrollContainer] as children.

signal message_received(message: GUIMessage)

## The [TreeItem] column that contains the name of the item.
const TREE_NAME_COL: int = 0
## The [Tree] managed by this node.
var tree: Tree = null

## The [ScrollContainer] managed by this node that contains all child pages.
var pages: ScrollContainer = null
## Data "struct" that contains the [TreeItem]->[Control] mapping for a single page.
class PageListing:
	## The listing in the [Tree]. Should be automatically cleaned up when the parent
	## [Tree] is freed.
	var tree_item: TreeItem = null
	## The actual page. Should be automatically cleaned up when the parent scene
	## is freed.
	var control: Control = null
	
	func _init(p_tree_item: TreeItem, p_control: Control) -> void:
		tree_item = p_tree_item
		control = p_control
	
	## Shows the page's [member control].
	func show() -> void:
		control.show()
	
	## Hides the page's [member control].
	func hide() -> void:
		control.hide()
	
	## Changes the [TreeItem] name for the page.
	func change_name(text: String) -> void:
		tree_item.set_text(TREE_NAME_COL, text)

## File name -> [HSplitTree.PageListing]. Used for toggling pages on and off.
var _pages := {}
## The currently selected page.
var _current_page: PageListing = null

## The percentage of the window to set the split at. Must be in decimal format.
@export
var split_percent_decimal: float = 0.15

## The logger. Initialized in [method _ready].
var _logger: Logger = null

#-----------------------------------------------------------------------------#
# Builtin functions
#-----------------------------------------------------------------------------#

## Sets up the callback for automatically setting the [HSplitContainer]'s
## [member SplitContainer.split_offset]. [br]
## [br]
## [b]Always needs to run. Call [code]super._init()[/code] if [code]_init[/code]
## needs to be modified.[/b]
func _init() -> void:
	ready.connect(func() -> void:
		if tree == null or pages == null:
			if _logger != null:
				_logger.error("Failed to setup HSplitTree, this is a major bug!")
			else:
				printerr("Failed to setup HSplitTree and its logger, this is a major bug!")
			return
		
		# Must give the window enough time to finish setting up
		await get_tree().physics_frame
		await get_tree().physics_frame
		split_offset = get_viewport().size.x * split_percent_decimal
	)

## Sets up the [code]HSplitTree[/code]. [br]
## [br]
## [b]Always needs to run. Call [code]super._ready()[/code] if [code]_ready[/code]
## needs to be modified.[/b]
func _ready() -> void:
	if _logger == null:
		_logger = Logger.create(String(name))
	
	var children := get_children()
	if children.size() != 2:
		_logger.error("HSplitTree expected exactly 2 children, bailing out")
		return
	if not children[0] is Tree:
		_logger.error("First child must be a Tree, bailing out")
		return
	if not children[1] is ScrollContainer:
		_logger.error("Second child must be a ScrollContainer, bailing out")
		return
	
	tree = children[0] as Tree
	pages = children[1] as ScrollContainer
	
	tree.hide_root = true
	tree.item_selected.connect(func() -> void:
		_show_page(tree.get_selected().get_text(TREE_NAME_COL))
	)
	var root := tree.create_item()
	
	for child in pages.get_children():
		add_page(child.name.capitalize(), child)
	
	if root.get_child_count() > 0:
		tree.set_selected(root.get_first_child(), TREE_NAME_COL)

#-----------------------------------------------------------------------------#
# Private functions
#-----------------------------------------------------------------------------#

## Shows a given page if it exists and hides the [member _current_page].
func _show_page(text: String) -> void:
	if not _pages.has(text):
		_logger.error("Page {0} does not exist, cannot switch page".format([text]))
		return
	if _current_page != null:
		_current_page.hide()
	
	_current_page = _pages[text]
	_current_page.show()

#-----------------------------------------------------------------------------#
# Public functions
#-----------------------------------------------------------------------------#

## Adds a page to the [member tree]. Returns an [enum Error] if the page already exists. [br]
## [br]
## [b]This does not add the page as a child. This step needs to be done manually.
## This because nodes should generally be pre-added as children, not at runtime.[/b]
func add_page(page_name: String, page: Control) -> Error:
	if _pages.has(page_name):
		return ERR_ALREADY_EXISTS
	
	var item := tree.create_item(tree.get_root())
	item.set_text(TREE_NAME_COL, page_name)
	
	_pages[page_name] = PageListing.new(item, page)
	page.hide()
	
	if page.has_signal(&"message_received"):
		page.message_received.connect(func(message: GUIMessage) -> void:
			message_received.emit(message)
		)
	
	return OK

func update(context: Context) -> void:
	for page in _pages.values():
		if page.control.has_signal(&"message_received"):
			page.control.update(context)
