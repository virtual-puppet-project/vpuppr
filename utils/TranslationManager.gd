class_name TranslationManager
extends Reference

const TRANSLATION_FOLDER_NAME: String = "translations"

var current_language: String = "en"

var current_translation: Dictionary = {}

###############################################################################
# Builtin functions                                                           #
###############################################################################

func _init() -> void:
	# https://docs.godotengine.org/en/stable/tutorials/i18n/locales.html
	current_language = TranslationServer.get_locale()

	yield(AppManager, "ready")
	
	# Load translation file
	_load_translation_file("%s/translations/%s.json" % [AppManager.save_directory_path, current_language])

###############################################################################
# Connections                                                                 #
###############################################################################

###############################################################################
# Private functions                                                           #
###############################################################################

func _load_translation_file(path: String) -> void:
	AppManager.logger.info("Loading translation file %s" % path)
	var translation_file := File.new()
	translation_file.open(path, File.READ)

	var data: JSONParseResult = JSON.parse(translation_file.get_as_text())
	if (data.error == OK and typeof(data.result) == TYPE_DICTIONARY):
		current_translation = data.result.duplicate()
	else:
		AppManager.logger.info("Unable to load translation file for %s" % path)

###############################################################################
# Public functions                                                            #
###############################################################################

func get_value(value: String) -> String:
	return current_translation[value]
