extends TextEdit

const AUTHORS_PATH := "res://AUTHORS.md"
const LICENSES_PATH := "/licenses/"

#-----------------------------------------------------------------------------#
# Builtin functions                                                           #
#-----------------------------------------------------------------------------#

func _ready() -> void:
	# Always pull the AUTHORS.md file first
	var file := File.new()

	if not file.open(AUTHORS_PATH, File.READ) == OK:
		printerr("Unable to open file for reading %s" % AUTHORS_PATH)
	else:
		text += "%s\n" % file.get_as_text()

	file.close()

	var path := FileUtil.inject_env_vars("%s/%s" % [Globals.RESOURCE_PATH, LICENSES_PATH])
	
	var dir := Directory.new()
	if not dir.dir_exists(path):
		printerr("%s does not exist, please visit the main repo to find the licenses" % path)
		return
	
	var load_paths := []
	_traverse_directory(path, load_paths)
	
	for p in load_paths:
		if not file.open(p, File.READ) == OK:
			printerr("Unable to open file: %s" % p)
			continue
		
		text += "%s\n" % p.get_file().get_basename()
		text += "%s\n" % file.get_as_text()

		file.close()

#-----------------------------------------------------------------------------#
# Connections                                                                 #
#-----------------------------------------------------------------------------#

#-----------------------------------------------------------------------------#
# Private functions                                                           #
#-----------------------------------------------------------------------------#

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

#-----------------------------------------------------------------------------#
# Public functions                                                            #
#-----------------------------------------------------------------------------#
