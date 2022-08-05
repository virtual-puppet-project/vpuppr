class_name TranslationManager
extends AbstractManager

const TRANSLATION_EXTENSION := ".txt"
const ESCAPED_QUOTE := "\\\""

var scan_path := ""

#-----------------------------------------------------------------------------#
# Builtin functions                                                           #
#-----------------------------------------------------------------------------#

func _init() -> void:
	pass

func _setup_logger() -> void:
	logger = Logger.new("TranslationManager")

func _setup_class() -> void:
	if not OS.is_debug_build():
		scan_path = "%s/%s" % [OS.get_executable_path().get_base_dir(), Globals.TRANSLATIONS_PATH]
	else:
		scan_path = "%s/%s" % [ProjectSettings.globalize_path("res://"), Globals.TRANSLATIONS_PATH]
	
	_scan()

#-----------------------------------------------------------------------------#
# Connections                                                                 #
#-----------------------------------------------------------------------------#

#-----------------------------------------------------------------------------#
# Private functions                                                           #
#-----------------------------------------------------------------------------#

func _scan() -> Result:
	var dir := Directory.new()
	
	if dir.open(scan_path) != OK:
		return Safely.err(Error.Code.TRANSLATION_MANAGER_DIRECTORY_DOES_NOT_EXIST, scan_path)
	
	dir.list_dir_begin(true, true)
	
	var file := File.new()
	
	var file_name := "start"
	while file_name != "":
		file_name = dir.get_next()
		
		if not file_name.ends_with(TRANSLATION_EXTENSION):
			continue
		
		if dir.current_is_dir():
			continue
		
		if file.open("%s/%s" % [scan_path, file_name], File.READ) != OK:
			printerr("Unable to open translation file %s, skipping", file_name)
			continue
		
		_load_translation(file_name.trim_suffix(TRANSLATION_EXTENSION), file.get_as_text())
		
		file.close()
	
	return Safely.ok()

## Parses the translation file into Godot's Translation object
##
## @param: locale: String - The locale for the translation
## @param: file_text: String - The full, unparsed text of the file
func _load_translation(locale: String, file_text: String) -> void:
	var translation := Translation.new()
	translation.locale = locale
	
	var current_key := ""
	var current_message := ""
	for line in file_text.split("\n"):
		var split: PoolStringArray = line.split("=", true, 1)
		if split.size() < 2:
			current_message += "\n%s" % line
			continue
		
		if not current_key.empty():
			var final_message := current_message.strip_edges()
			if not _valid_message_ending(final_message):
				current_message += "\n%s" % line.replace(ESCAPED_QUOTE, "\"")
				continue
			else:
				translation.add_message(current_key, final_message.substr(1, final_message.length() - 2))
				current_key = ""
				current_message = ""
		
		current_key = split[0]
		current_message = split[1]
		if not current_message.begins_with("\""):
			printerr("Translation messages must start with a \" character, skipping: %s" % current_key)
			current_key = ""
			current_message = ""
	
	var final_message := current_message.strip_edges()
	if not _valid_message_ending(final_message):
		printerr("Translation messages must end with a \" character, skipping: %s" % current_key)
	else:
		translation.add_message(current_key, final_message.substr(1, final_message.length() - 2))
	
	var hash_translation := PHashTranslation.new()
	hash_translation.generate(translation)
	
	TranslationServer.add_translation(hash_translation)

static func _valid_message_ending(text: String) -> bool:
	return text.ends_with("\"") or not text.ends_with(ESCAPED_QUOTE)

#-----------------------------------------------------------------------------#
# Public functions                                                            #
#-----------------------------------------------------------------------------#
