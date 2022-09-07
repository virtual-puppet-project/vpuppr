class_name TranslationManager
extends AbstractManager

const IGNORED_CHARS := ";;"
const TRANSLATION_EXTENSION := ".txt"
const ESCAPED_QUOTE := "\\\""

const DEFAULT_GUI_PREFIX := "DEFAULT_GUI_%s"

var scan_path := ""

#-----------------------------------------------------------------------------#
# Builtin functions                                                           #
#-----------------------------------------------------------------------------#

func _init() -> void:
	pass

func _setup_logger() -> void:
	logger = Logger.new("TranslationManager")

func _setup_class() -> void:
	scan_path = FileUtil.inject_env_vars(Globals.RESOURCE_PATH)
	if scan_path.empty():
		if not OS.is_debug_build():
			scan_path = "%s/%s" % [OS.get_executable_path().get_base_dir(), Globals.TRANSLATIONS_PATH]
		else:
			scan_path = "%s/%s" % [ProjectSettings.globalize_path("res://"), Globals.TRANSLATIONS_PATH]
	else:
		scan_path = "%s/%s" % [scan_path, Globals.TRANSLATIONS_PATH]
	
	logger.debug("Using scan_path: %s" % scan_path)
	
	var dir := Directory.new()
	var file := File.new()
	
	_scan(dir, file, scan_path)
	for extension in AM.em.extensions.values():
		if extension.has_directory(Globals.EXTENSION_TRANSLATION_PATH):
			_scan(dir, file, "%s/%s" % [extension.context, Globals.EXTENSION_TRANSLATION_PATH])
	
	logger.debug("Auto-detected language is: %s" % TranslationServer.get_locale())

#-----------------------------------------------------------------------------#
# Connections                                                                 #
#-----------------------------------------------------------------------------#

#-----------------------------------------------------------------------------#
# Private functions                                                           #
#-----------------------------------------------------------------------------#

func _scan(dir: Directory, file: File, path: String) -> Result:
	logger.debug("Scanning %s for translations" % path)
	
	if dir.open(path) != OK:
		return Safely.err(Error.Code.TRANSLATION_MANAGER_DIRECTORY_DOES_NOT_EXIST, scan_path)
	
	dir.list_dir_begin(true, true)
	
	var file_name := "start"
	while file_name != "":
		file_name = dir.get_next()
		
		if not file_name.ends_with(TRANSLATION_EXTENSION):
			continue
		
		if dir.current_is_dir():
			continue
		
		if file.open("%s/%s" % [path, file_name], File.READ) != OK:
			printerr("Unable to open translation file %s, skipping", file_name)
			continue
		
		logger.debug("Loading translation file %s" % file_name)
		
		_load_translation(file_name.trim_suffix(TRANSLATION_EXTENSION), file.get_as_text())
		
		logger.debug("Finished loading translation file %s" % file_name)
		
		file.close()
	
	dir.list_dir_end()
	
	logger.debug("Finished scanning %s for translations" % path)
	
	return Safely.ok()

## Parses the translation file into Godot's Translation object. Note that it doesn't matter if
## a translation for the same locale is loaded twice. The new translation is appended to the
## existing translation. Keys are overridden if the new translation contains existing keys.
##
## NOTE: PHashTranslation cannot be used at runtime
##
## @param: locale: String - The locale for the translation
## @param: file_text: String - The full, unparsed text of the file
func _load_translation(locale: String, file_text: String) -> void:
	logger.debug("Loading translation for locale: %s" % locale)
	
	var translation := Translation.new()
	translation.locale = locale
	
	# Attempt to normalize line endings
	file_text = file_text.replace("\r", "")
	
	var current_key := ""
	var current_message := ""
	for line in file_text.split("\n"):
		var ignored_chars_pos: int = line.find(IGNORED_CHARS)
		line = line.substr(0, ignored_chars_pos if ignored_chars_pos > -1 else line.length()).strip_edges()
		
		var split: PoolStringArray = line.split("=", true, 1)
		if split.size() < 2:
			current_message += "\n%s" % line.replace(ESCAPED_QUOTE, "\"")
			continue
		
		if not current_key.empty():
			var final_message := current_message.strip_edges()
			if not _valid_message_ending(final_message):
				current_message += "\n%s" % line.replace(ESCAPED_QUOTE, "\"")
				continue
			else:
				translation.add_message(current_key, final_message.substr(1, final_message.length() - 2))
				
				logger.debug("Added translation: %s - %s" % [
					current_key, final_message.substr(1, final_message.length() - 2)])
				
				current_key = ""
				current_message = ""
		
		current_key = split[0]
		current_message = split[1].replace(ESCAPED_QUOTE, "\"")
		if not current_message.begins_with("\""):
			printerr("Translation messages must start with a \" character, skipping: %s" % current_key)
			current_key = ""
			current_message = ""
	
	var final_message := current_message.strip_edges()
	if not _valid_message_ending(final_message):
		printerr("Translation messages must end with a \" character, skipping: %s" % current_key)
	else:
		translation.add_message(current_key, final_message.substr(1, final_message.length() - 2))
	
	logger.debug("Loaded %d translations" % translation.get_message_count())
	
	TranslationServer.add_translation(translation)
	
	logger.debug("Finished loading translation")

static func _valid_message_ending(text: String) -> bool:
	return text.ends_with("\"") and not text.ends_with(ESCAPED_QUOTE)

#-----------------------------------------------------------------------------#
# Public functions                                                            #
#-----------------------------------------------------------------------------#

static func to_translation_key(text: String) -> String:
	return text.capitalize().to_upper().replace(" ", "_")

static func builtin_res_path_to_key(res_path: String) -> String:
	return DEFAULT_GUI_PREFIX % res_path.get_file().get_basename().capitalize().to_upper().replace(" ", "_")

static func parent_item_to_key(parent_name: String, item_name: String) -> String:
	return "%s_%s" % [to_translation_key(parent_name), to_translation_key(item_name)]
