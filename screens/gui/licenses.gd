extends HSplitTree

const APP_LICENSE_PATH := "res://LICENSE"
const APP_LICENSE_PAGE_NAME := "vpuppr"
const LICENSE_DIR := "res://licenses"

#-----------------------------------------------------------------------------#
# Builtin functions
#-----------------------------------------------------------------------------#

func _ready() -> void:
	_logger = Logger.create("Licenses")
	
	var tree := %Tree
	var pages := %Pages
	
	var app_license := FileAccess.open(APP_LICENSE_PATH, FileAccess.READ)
	if app_license == null:
		_logger.error("Unable to read app license, this is a major bug!")
		return
	
	pages.add_child(_create_license_gui(APP_LICENSE_PAGE_NAME, app_license.get_as_text()))

	var dir := DirAccess.open(LICENSE_DIR)
	if dir == null:
		_logger.error("Unable to open {0}, this is a major bug!".format([LICENSE_DIR]))
		return

	dir.list_dir_begin()

	var file_name := dir.get_next()
	while not file_name.is_empty():
		_logger.debug("Handling license {0}".format([file_name]))

		var file_path := "{0}/{1}".format([LICENSE_DIR, file_name])
		var file := FileAccess.open(file_path, FileAccess.READ)
		if file == null:
			_logger.error("Unable to open license file at {0}, skipping".format([file_path]))
			file_name = dir.get_next()
			continue

		pages.add_child(_create_license_gui(file_name, file.get_as_text()))

		file_name = dir.get_next()
	
	super._ready()

	if _pages.size() < 1:
		_logger.error("No license pages created, this is a major bug!")
		return
	pass

#-----------------------------------------------------------------------------#
# Private functions
#-----------------------------------------------------------------------------#

func _create_license_gui(page_name: String, content: String) -> RichTextLabel:
	var page := RichTextLabel.new()
	page.bbcode_enabled = true
	page.text = content
	page.name = page_name
	page.fit_content = true
	page.selection_enabled = true
	page.size_flags_horizontal = Control.SIZE_EXPAND_FILL
	
	return page

func _create_logger() -> void:
	_logger = Logger.create("Licenses")

#-----------------------------------------------------------------------------#
# Public functions
#-----------------------------------------------------------------------------#
