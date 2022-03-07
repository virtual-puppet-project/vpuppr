class_name ExtensionManager
extends Reference

const Config := {
	"DEFAULT_SEARCH_FOLDER": "resources/plugins",

	"CONFIG_NAME": "config.ini",
	"GENERAL": "General",
	"GENERAL_KEYS": {
		# How the resource will be referred to when loading via RLM
		"NAME": "name"
	},
	"SECTION_KEYS": {
		"TYPE": "type",
		"ENTRYPOINT": "entrypoint"
	},
	"EXTENSION_TYPES": {
		"RUNNER": "runner",
		"PUPPET": "puppet",
		"TRACKER": "tracker",
		"GUI": "gui",
		"PLUGIN": "plugin"
	}
}

var logger := Logger.new("ExtensionManager")

var scan_path := ""

var extensions := {} # Plugin name: String -> Plugin object: RuntimeLoadablePlugin

###############################################################################
# Builtin functions                                                           #
###############################################################################

func _init() -> void:
	if not OS.is_debug_build():
		scan_path = "%s/%s" % [OS.get_executable_path().get_base_dir(), Config.DEFAULT_SEARCH_FOLDER]
	else:
		scan_path = "%s/%s" % [ProjectSettings.globalize_path("res://"), Config.DEFAULT_SEARCH_FOLDER]

	_scan()

###############################################################################
# Connections                                                                 #
###############################################################################

###############################################################################
# Private functions                                                           #
###############################################################################

func _scan() -> Result:
	var dir := Directory.new()

	if dir.open(Config.DEFAULT_SEARCH_FOLDER) != OK:
		return Result.err(Error.Code.RUNTIME_LOADABLE_MANAGER_RESOURCE_PATH_DOES_NOT_EXIST)

	dir.list_dir_begin(true, true)

	var possible_extensions := []

	var file_name := dir.get_next()
	while file_name != "":
		if dir.current_is_dir():
			# The directory that houses the extension
			possible_extensions.append("%s/%s" % [scan_path, file_name])

		file_name = dir.get_next()

	for i in possible_extensions:
		var r := _parse_extension(i)
		if r.is_err():
			logger.error(r.to_string())
			continue

	return Result.ok()

func _parse_extension(path: String) -> Result:
	var file := File.new()

	if file.open("%s/%s" % [path, Config.CONFIG_NAME], File.READ) != OK:
		return Result.err(Error.Code.RUNTIME_LOADABLE_MANAGER_CONFIG_DOES_NOT_EXIST)

	var c := ConfigFile.new()
	if c.parse(file.get_as_text()) != OK:
		return Result.err(Error.Code.RUNTIME_LOADABLE_MANAGER_RESOURCE_CONFIG_PARSE_FAILURE)

	if not c.has_section(Config.GENERAL):
		return Result.err(Error.Code.RUNTIME_LOADABLE_MANAGER_MISSING_GENERAL_SECTION)

	var extension_name: String = c.get_value(Config.GENERAL, Config.GENERAL_KEYS.NAME, "")
	if extension_name.empty():
		return Result.err(Error.Code.RUNTIME_LOADABLE_MANAGER_MISSING_EXTENSION_NAME)

	var ext = Extension.new()
	ext.extension_name = extension_name
	
	for i in c.get_sections():
		var r := _parse_extension_section(path, c, i, ext)
		if r.is_err():
			return r
	
	extensions[extension_name] = ext

	return Result.ok()

func _parse_extension_section(path: String, c: ConfigFile, section_name: String, e: Extension) -> Result:
	for key in Config.SECTION_KEYS.keys():
		if not c.has_section_key(section_name, Config.SECTION_KEYS[key]):
			return Result.err(Error.Code.RUNTIME_LOADABLE_MANAGER_MISSING_EXTENSION_SECTION_KEY,
				Config.SECTION_KEYS[key])

	var res := e.add_resource(
		section_name,
		c.get_value(section_name, Config.SECTION_KEYS.TYPE),
		c.get_value(section_name, "%s/%s" % [path, Config.SECTION_KEYS.ENTRYPOINT])
	)
	if res.is_err():
		return res

	return Result.ok()

###############################################################################
# Public functions                                                            #
###############################################################################
