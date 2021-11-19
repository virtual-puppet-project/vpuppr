extends WindowDialog

const LICENSES_DIRECTORY: String = "res://resources/licenses/"

onready var vbox: VBoxContainer = $PanelContainer/ScrollContainer/VBoxContainer

var load_paths: Array = [] # String

###############################################################################
# Builtin functions                                                           #
###############################################################################

func _ready():
	var screen_middle: Vector2 = Vector2(get_viewport_rect().size.x/2, get_viewport_rect().size.y/2)
	
	set_global_position(screen_middle)
	rect_size = screen_middle
	popup_centered(screen_middle)

	connect("popup_hide", self, "_on_popup_hide")

	# TODO read from licenses
	var dir := Directory.new()
	if not dir.dir_exists(LICENSES_DIRECTORY):
		AppManager.logger.info("%s does not exist, please visit the main repo to find licenses" % LICENSES_DIRECTORY)
		return

	_traverse_directory(LICENSES_DIRECTORY)

	for path in load_paths:
		var file := File.new()

		if file.open(path, File.READ) == OK:
			var title_label := Label.new()
			title_label.autowrap = true
			title_label.text = path.get_file().get_basename()

			vbox.call_deferred("add_child", title_label)

			var label := Label.new()
			label.autowrap = true
			label.text = file.get_as_text()

			vbox.call_deferred("add_child", label)

###############################################################################
# Connections                                                                 #
###############################################################################

func _on_popup_hide() -> void:
	queue_free()

###############################################################################
# Private functions                                                           #
###############################################################################

func _traverse_directory(base_directory: String) -> void:
	var dir_names: Array = []

	var dir := Directory.new()
	if dir.open(base_directory) == OK:
		dir.list_dir_begin(true, true)
		var file_name = dir.get_next()
		while file_name != "":
			if dir.current_is_dir():
				dir_names.append("%s/%s" % [base_directory, file_name])
			else:
				load_paths.append("%s/%s" % [base_directory, file_name])
			file_name = dir.get_next()
	
	for dir_name in dir_names:
		_traverse_directory(dir_name)

###############################################################################
# Public functions                                                            #
###############################################################################
