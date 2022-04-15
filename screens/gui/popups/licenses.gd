extends TextEdit

const LICENSES_PATH := "resources/licenses/"

###############################################################################
# Builtin functions                                                           #
###############################################################################

func _ready() -> void:
	var path := "res://%s" % LICENSES_PATH
	
	if not OS.is_debug_build():
		path = "%s/%s" % [OS.get_executable_path(), LICENSES_PATH]
	
	var dir := Directory.new()
	if not dir.dir_exists(path):
		printerr("%s does not exist, please visit the main repo to find the licenses" % path)
		return
	
	var load_paths := []
	_traverse_directory(path, load_paths)
	
	for p in load_paths:
		var file := File.new()
		
		if not file.open(p, File.READ) == OK:
			printerr("Unable to open file: %s" % p)
		
		text += "%s\n" % p.get_file().get_basename()
		text += "%s\n" % file.get_as_text()

###############################################################################
# Connections                                                                 #
###############################################################################

###############################################################################
# Private functions                                                           #
###############################################################################

func _traverse_directory(base_directory: String, paths: Array) -> Array:
	var dir_names: Array = []

	var dir := Directory.new()
	if dir.open(base_directory) == OK:
		dir.list_dir_begin(true, true)
		var file_name = dir.get_next()
		while file_name != "":
			if dir.current_is_dir():
				dir_names.append("%s/%s" % [base_directory, file_name])
			else:
				paths.append("%s/%s" % [base_directory, file_name])
			file_name = dir.get_next()
	
	for dir_name in dir_names:
		_traverse_directory(dir_name, paths)
	
	return paths

###############################################################################
# Public functions                                                            #
###############################################################################
