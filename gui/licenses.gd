extends HSplitContainer

const APP_LICENSE_PATH := "res://LICENSE"
const APP_LICENSE_PAGE_NAME := "vpuppr"
const LICENSE_DIR := "res://licenses"
const TREE_COL: int = 0
const ALL_ITEM := "All"

var _logger := Logger.create("Licenses")

@onready
var _tree: Tree = %Tree
@onready
var _license_container := %LicenseContainer

## File name -> Control. Used for toggling pages on and off.
var _pages := {}

#-----------------------------------------------------------------------------#
# Builtin functions
#-----------------------------------------------------------------------------#

func _init() -> void:
	ready.connect(func() -> void:
		# Must give the window enough time to finish popping up
		await get_tree().physics_frame
		await get_tree().physics_frame
		split_offset = get_viewport().size.x * 0.2
	)

func _ready() -> void:
	# TODO (you-win) Sept 10 2023 godot type inference still sucks, so we need this
	# for code completion. Godot is also not able to infer the child tree item types
	var root: TreeItem = _tree.create_item()
	_tree.item_selected.connect(func() -> void:
		_show_page(_tree.get_selected().get_text(TREE_COL))
	)
	var all_item: TreeItem = _tree.create_item(root)
	all_item.set_text(TREE_COL, ALL_ITEM)
	
	var app_license := FileAccess.open(APP_LICENSE_PATH, FileAccess.READ)
	if app_license == null:
		_logger.error("Unable to read app license, this is a major bug!")
		return

	_create_page(APP_LICENSE_PAGE_NAME, app_license.get_as_text())

	var dir := DirAccess.open(LICENSE_DIR)
	if dir == null:
		_logger.error("Unable to open {0}, this is a major bug!".format([LICENSE_DIR]))
		return

	dir.list_dir_begin()

	var file_name := dir.get_next()
	while not file_name.is_empty():
		_logger.debug("Handling license {0}".format([file_name]))

		if _pages.has(file_name):
			_logger.error("Found duplicate file for {0} somehow, skipping".format([file_name]))
			file_name = dir.get_next()
			continue

		var file_path := "{0}/{1}".format([LICENSE_DIR, file_name])
		var file := FileAccess.open(file_path, FileAccess.READ)
		if file == null:
			_logger.error("Unable to open license file at {0}, skipping".format([file_path]))
			file_name = dir.get_next()
			continue

		_create_page(file_name, file.get_as_text())

		file_name = dir.get_next()

	if _pages.size() < 1:
		_logger.error("No license pages created, this is a major bug!")
		return

	_tree.set_selected(all_item, TREE_COL)

#-----------------------------------------------------------------------------#
# Private functions
#-----------------------------------------------------------------------------#

func _create_page(page_name: String, content: String) -> void:
	var item := _tree.create_item(_tree.get_root())
	item.set_text(TREE_COL, page_name)
	
	var page := RichTextLabel.new()
	page.bbcode_enabled = true
	page.text = content
	page.name = page_name
	page.fit_content = true
	page.selection_enabled = true
	
	_pages[page_name] = page
	_license_container.add_child(page)

func _show_page(text: String) -> void:
	if text == ALL_ITEM:
		for i in _pages.values():
			i.show()
	else:
		for i in _pages.values():
			i.hide()
		
		_pages[text].show()

#-----------------------------------------------------------------------------#
# Public functions
#-----------------------------------------------------------------------------#
