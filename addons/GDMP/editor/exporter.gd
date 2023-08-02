extends EditorExportPlugin

func _export_begin(features: PackedStringArray, is_debug: bool, path: String, flags: int) -> void:
	var files := find_files("res://", ["binarypb", "pbtxt", "task", "tflite"])
	for file in files:
		var f := FileAccess.open(file, FileAccess.READ)
		if f:
			add_file(file, f.get_buffer(f.get_length()), false)
		else:
			printerr("GDMP: Failed to open %s: %d" % [file, FileAccess.get_open_error()])

func _export_file(path: String, type: String, features: PackedStringArray) -> void:
	if path.get_file() == "GDMP.gdextension":
		if features.has("android"):
			skip()

func _get_name() -> String:
	return "GDMP"

func find_files(path: String, extenstions: PackedStringArray) -> PackedStringArray:
	var files: PackedStringArray = []
	var dir := DirAccess.open(path)
	if dir:
		for f in dir.get_files():
			if f.get_extension() in extenstions:
				files.append(path.path_join(f))
		for d in dir.get_directories():
			d = path.path_join(d)
			if d.begins_with("res://android"):
				continue
			files.append_array(find_files(d, extenstions))
	else:
		printerr("GDMP: Failed to open %s: %d" % [path, DirAccess.get_open_error()])
	return files
