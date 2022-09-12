class_name ExtensionManager
extends AbstractManager

const EXTENSION_MANAGER_NAME := "ExtensionManager"

const Config := {
	"SCAN_PATH_FORMAT": "%s/resources/%s",
	"DEFAULT_SEARCH_FOLDER": "extensions/",

	"CONFIG_NAME": "config.ini",
	"GENERAL": "General",
	"GENERAL_KEYS": {
		# How the resource will be referred to when loading via RLM
		"NAME": "name",
		"TRANSLATION_KEY": "translation_key"
	},
	"SECTION_KEYS": {
		"TYPE": "type",
		"ENTRYPOINT": "entrypoint",
		"GDNATIVE": "gdnative",
		"TRANSLATION_KEY": "translation_key"
	}
}

## The dict of extension names to extension objects
##
## Extension name: String -> Extension object: Extension
var extensions := {}

#-----------------------------------------------------------------------------#
# Builtin functions                                                           #
#-----------------------------------------------------------------------------#

func _init() -> void:
	pass

func _setup_logger() -> void:
	logger = Logger.new(EXTENSION_MANAGER_NAME)

func _setup_class() -> void:
	var scan_path: String = FileUtil.inject_env_vars(Globals.RESOURCE_PATH)
	if scan_path.empty():
		if not OS.is_debug_build():
			scan_path = Config.SCAN_PATH_FORMAT % [
				OS.get_executable_path().get_base_dir(), Config.DEFAULT_SEARCH_FOLDER]
		else:
			scan_path = Config.SCAN_PATH_FORMAT % [
				ProjectSettings.globalize_path("res://"), Config.DEFAULT_SEARCH_FOLDER]
	else:
		scan_path = "%s/%s" % [scan_path, Config.DEFAULT_SEARCH_FOLDER]
	
	var res: Result = Safely.wrap(_scan(scan_path))
	if res.is_err():
		logger.error(res)

#-----------------------------------------------------------------------------#
# Connections                                                                 #
#-----------------------------------------------------------------------------#

#-----------------------------------------------------------------------------#
# Private functions                                                           #
#-----------------------------------------------------------------------------#

## Scans the scan_path for folders. For each folder, the resource config file is read and the
## extension is added to the list of known extensions.
##
## AVOID CALLING THIS IN USER CODE. This can cause things to crash unexpectedly and without an
## error log. Hence, why it's labeled as private. Unexpected crashes are generally due to
## loading/unloading gdnative libraries at runtime, but without logs, it's hard to tell.
##
## @return: Result<int> - The error code
func _scan(scan_path: String) -> Result:
	var dir := Directory.new()

	if dir.open(scan_path) != OK:
		return Safely.err(Error.Code.EXTENSION_MANAGER_RESOURCE_PATH_DOES_NOT_EXIST, scan_path)

	dir.list_dir_begin(true, true)

	var possible_extensions := []

	var file_name := "start"
	while file_name != "":
		file_name = dir.get_next()
		
		if file_name.empty():
			continue
		
		if dir.current_is_dir():
			# The directory that houses the extension
			possible_extensions.append("%s/%s" % [scan_path, file_name])

	for i in possible_extensions:
		var r := Safely.wrap(_parse_extension(i))
		if r.is_err():
			logger.error(r)
			continue

	return Safely.ok()

## Checks for necessary metadata and then iterates through every section in the
## extension's ini file
##
## @param: path: String - The absolute path to the extension folder
##
## @return: Result<int> - The error code
func _parse_extension(path: String) -> Result:
	var file := File.new()

	if file.open("%s/%s" % [path, Config.CONFIG_NAME], File.READ) != OK:
		return Safely.err(
			Error.Code.EXTENSION_MANAGER_CONFIG_DOES_NOT_EXIST,
			"%s/%s" % [path, Config.CONFIG_NAME])

	var c := ConfigFile.new()
	if c.parse(file.get_as_text()) != OK:
		return Safely.err(Error.Code.EXTENSION_MANAGER_RESOURCE_CONFIG_PARSE_FAILURE, path)

	if not c.has_section(Config.GENERAL):
		return Safely.err(Error.Code.EXTENSION_MANAGER_MISSING_GENERAL_SECTION, path)

	var extension_name: String = c.get_value(Config.GENERAL, Config.GENERAL_KEYS.NAME, "")
	if extension_name.empty():
		return Safely.err(Error.Code.EXTENSION_MANAGER_MISSING_EXTENSION_NAME, path)

	var ext = Extension.new()
	ext.context = path
	ext.extension_name = extension_name
	ext.translation_key = c.get_value(Config.GENERAL, Config.GENERAL_KEYS.TRANSLATION_KEY, ext.extension_name)
	
	for i in c.get_sections():
		if i == Config.GENERAL:
			continue
		var r := _parse_extension_section(path, c, i, ext)
		if r.is_err():
			return r
	
	extensions[extension_name] = ext

	return Safely.ok()

## Parses an extension section and registers the absolute path to the entrypoint.
##
## The only files known to the ExtensionManager are entrypoint files. After that,
## files need to be accessed via the context.
##
## @param: path: String - The absolute path to a resource
## @param: c: ConfigFile - The ini file's contents
## @param: section_name: String - The name of the ini section currently being processed
## @param: e: Extension - The extension's Extension object
##
## @return: Result<int> - The error code
func _parse_extension_section(path: String, c: ConfigFile, section_name: String, e: Extension) -> Result:
	if not c.has_section_key(section_name, Config.SECTION_KEYS.TYPE):
		return Safely.err(
			Error.Code.EXTENSION_MANAGER_MISSING_EXTENSION_SECTION_KEY,
			Config.SECTION_KEYS.TYPE
		)

	if not c.has_section_key(section_name, Config.SECTION_KEYS.ENTRYPOINT):
		return Safely.err(
			Error.Code.EXTENSION_MANAGER_MISSING_EXTENSION_SECTION_KEY,
			Config.SECTION_KEYS.ENTRYPOINT
		)

	var res := e.add_resource(
		section_name,
		c.get_value(section_name, Config.SECTION_KEYS.TYPE).to_lower(),
		"%s/%s" % [path, c.get_value(section_name, Config.SECTION_KEYS.ENTRYPOINT)]
	)
	if res.is_err():
		return res

	var ext_resource: ExtensionResource = res.unwrap()

	for key in c.get_section_keys(section_name):
		if key in Config.SECTION_KEYS.values():
			continue

		ext_resource.other[key] = c.get_value(section_name, key)

	var is_native = c.get_value(section_name, Config.SECTION_KEYS.GDNATIVE, false)
	# INI files don't define a boolean type, so just try to assume
	# NOTE I think Godot parses 'true' (no quotes) as a bool by default
	if bool(is_native) == true:
		var dir := Directory.new()

		var native_dir: String = c.get_value(section_name, Config.SECTION_KEYS.ENTRYPOINT)
		var full_native_dir: String = "%s/%s" % [path, native_dir]

		if not dir.dir_exists(full_native_dir):
			return Safely.err(Error.Code.EXTENSION_MANAGER_BAD_GDNATIVE_ENTRYPOINT, full_native_dir)

		if AM.grl.process_folder(full_native_dir) != OK:
			return Safely.err(Error.Code.EXTENSION_MANAGER_FAILED_PROCESSING_GDNATIVE, full_native_dir)

		ext_resource.is_gdnative = true
		ext_resource.resource_entrypoint = native_dir

	ext_resource.translation_key = c.get_value(
		section_name, Config.SECTION_KEYS.TRANSLATION_KEY, ext_resource.resource_name)

	return Safely.ok()

#-----------------------------------------------------------------------------#
# Public functions                                                            #
#-----------------------------------------------------------------------------#

## Null-safe wrapper for getting an Extension
##
## @param: extension_name: String - The extension to get, corresponds to the name in config.ini
##
## @return: Result<Extension> - The extension
func get_extension(extension_name: String) -> Result:
	var extension: Extension = extensions.get(extension_name)
	if extension == null:
		return Safely.err(Error.Code.EXTENSION_MANAGER_EXTENSION_DOES_NOT_EXIST, extension_name)
	return Safely.ok(extension)

## Gets all extensions of a certain type
##
## @param: ext_type: String - The extension type
##
## @return: Array<ExtensionResource> - The extension resources that match the `ext_type`
func query_extensions_for_type(ext_type: String) -> Array:
	var r := []

	for key in extensions.keys():
		var ext_resources: Dictionary = extensions[key].resources
		for inner_key in ext_resources.keys():
			if ext_resources[inner_key].resource_type == ext_type:
				r.append(ext_resources[inner_key])

	return r

## Finds a given value in an extension using node-path syntax
##
## @example: extension_name/resources/resource_name/resource_entrypoint
##
## @param: query: String - A '/' delimited String containing the path to a Variant
##
## @return: Result<Variant> - The Variant found for the query
func find_in_extensions(query: String) -> Result:
	var split_query := query.strip_edges().lstrip("/").rstrip("/").split("/")

	if split_query.empty():
		return Safely.err(Error.Code.EXTENSION_MANAGER_EMPTY_QUERY, query)

	var r := [extensions]

	for key_idx in split_query.size():
		var current_container = r[key_idx]
		var key: String = split_query[key_idx]

		var val

		match typeof(current_container):
			TYPE_ARRAY:
				if key.is_valid_integer():
					val = current_container[int(key)]
			TYPE_DICTIONARY, TYPE_OBJECT:
				val = current_container.get(key)
		
		if val != null:
			r.append(val)
			continue

		return Safely.err(Error.Code.EXTENSION_MANAGER_BAD_QUERY, "%s: %s" % [str(split_query), key])
	
	return Safely.ok(r.pop_back())

## Wrapper function for safely getting an extension's context path
##
## @param: extension_name: String - The Extension's name
##
## @return: Result<ExtensionContext> - The ExtensionContext
func get_context(extension_name: String) -> Result:
	var ext: Extension = extensions.get(extension_name)
	if ext == null:
		return Safely.err(Error.Code.EXTENSION_MANAGER_EXTENSION_DOES_NOT_EXIST, extension_name)

	return Safely.ok(ext.context)

## Wrapper function for safely loading a resource from an extension's context
##
## @param: extension_name: String - The extension name
## @param: rel_res_path: String - The relative path to the resource
##
## @return: Result<Variant> - The loaded resource
func load_resource(extension_name: String, rel_res_path: String) -> Result:
	var result := Safely.wrap(get_extension(extension_name))
	if result.is_err():
		return result

	result = result.unwrap().load_resource(rel_res_path)
	if result.is_err():
		return result
	
	return result

## Wrapper function for safely creating a class from a GDNative library.
##
## This works differently from loading a normal resource, as we need to figure
## out the entrypoint from the extension_resource first.
##
## This is technically not necessary and can be completely bypassed by directly
## accessing the gdnative_runtime_loader (grl) in the AppManager and calling
## create_class(<your_folder_name_for_the_lib>, <your_native_class>)
##
## TODO this might need to be refactored
##
## @param: extension_name: String - The name of the Extension
## @param: resource_name: String - The name of the resource in the ini file
## @param: clazz_name: String - The name of the class to instance
##
## @return: Result<Variant> - The new GDNative class instance
func load_gdnative_resource(
	extension_name: String,
	resource_name: String,
	clazz_name: String
) -> Result:
	var ext = extensions.get(extension_name)
	if ext == null:
		return Safely.err(Error.Code.EXTENSION_MANAGER_EXTENSION_DOES_NOT_EXIST, extension_name)

	var ext_res = ext.resources.get(resource_name)
	if ext_res == null:
		return Safely.err(Error.Code.EXTENSION_MANAGER_EXTENSION_RESOURCE_DOES_NOT_EXIST, resource_name)

	var native_class = AM.grl.create_class(ext_res.resource_entrypoint, clazz_name)
	if native_class == null:
		return Safely.err(Error.Code.EXTENSION_MANAGER_BAD_GDNATIVE_CLASS, clazz_name)

	return Safely.ok(native_class)
