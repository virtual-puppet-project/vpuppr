class_name ExtensionManager
extends AbstractManager

const CONFIG_FILE_NAME_TOML := "config.toml"
const CONFIG_FILE_NAME_JSON := "config.json"
const EXTENSION_SECTION := "extension"
const RESOURCES_SECTION := "resources"

const TOML_EXT := "toml"
const JSON_EXT := "json"

const ExtensionKeys := {
	"NAME": "name",
	"TRANSLATION_KEY": "translation-key"
}
const ResourceKeys := {
	"NAME": "name",
	"TAGS": "tags",
	"ENTRYPOINT": "entrypoint",
	"GDNATIVE": "gdnative",
	"TRANSLATION_KEY": "translation-key",
	"GUI": "gui",
	"Extra": Globals.ExtensionExtraKeys
}

const RecognizedTags := {
	"FILE_PICKER": "file-picker"
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
	logger = Logger.new("ExtensionManager")

func _setup_class() -> void:
	var file := File.new()
	var dir := Directory.new()
	
	# Scan user data first for resources
	var scan_path: String = "%s/%s" % [
		OS.get_user_data_dir(), Globals.EXTENSIONS_PATH]
	
	if dir.dir_exists(scan_path):
		logger.info("Parsing user extensions: %s" % scan_path)

		var res: Result = Safely.wrap(_scan(file, dir, scan_path))
		if res.is_err():
			logger.error(res)
	else:
		logger.info("No user extensions found, skipping")
	
	# Scan normal resource path afterwards. Ignore duplicates
	scan_path = AM.inject_env_vars(Globals.RESOURCE_PATH)
	if scan_path.empty():
		if not OS.is_debug_build():
			scan_path = "%s/%s" % [
				OS.get_executable_path().get_base_dir(), Globals.EXTENSIONS_PATH]
		else:
			scan_path = "%s/%s" % [
				ProjectSettings.globalize_path("res://"), Globals.EXTENSIONS_PATH]
	else:
		scan_path = "%s/%s" % [scan_path, Globals.EXTENSIONS_PATH]
	
	if dir.dir_exists(scan_path):
		logger.info("Parsing default extensions")

		var res: Result = Safely.wrap(_scan(file, dir, scan_path))
		if res.is_err():
			logger.error(res)
	else:
		logger.info("No default extensions found, skipping")

#-----------------------------------------------------------------------------#
# Connections                                                                 #
#-----------------------------------------------------------------------------#

#-----------------------------------------------------------------------------#
# Private functions                                                           #
#-----------------------------------------------------------------------------#

func _scan(file: File, dir: Directory, scan_path: String) -> Result:
	if dir.open(scan_path) != OK:
		return Safely.err(Error.Code.EXTENSION_MANAGER_RESOURCE_PATH_DOES_NOT_EXIST, scan_path)

	dir.list_dir_begin(true, true)

	var possible_extensions := []

	var file_name: String = dir.get_next()
	while not file_name.empty():
		if dir.current_is_dir():
			# The directory that contains the extension
			possible_extensions.append("%s/%s" % [scan_path, file_name])
		
		file_name = dir.get_next()
	
	dir.list_dir_end()

	for ext_path in possible_extensions:
		var res: Result = Safely.wrap(_parse_extension(file, dir, ext_path))
		if res.is_err():
			logger.error(res)
			continue
		
		var extension: Extension = res.unwrap()
		extensions[extension.extension_name] = extension

	return Safely.ok()

func _parse_extension(file: File, dir: Directory, path: String) -> Result:
	var config_path := ""
	var config_file_ext := ""
	var found_config := false
	for i in [{"name": CONFIG_FILE_NAME_TOML, "ext": TOML_EXT}, {"name": CONFIG_FILE_NAME_JSON, "ext": JSON_EXT}]:
		config_path = "%s/%s" % [path, i.name]
		config_file_ext = i.ext
		if file.open(config_path, File.READ) == OK:
			found_config = true
			break
	
	if not found_config:
		return Safely.err(Error.Code.EXTENSION_MANAGER_CONFIG_DOES_NOT_EXIST, path)

	var file_text := file.get_as_text()
	file.close()

	var data := {}
	var parse_res

	match config_file_ext:
		TOML_EXT:
			var toml := TOML.new()
			parse_res = toml.parse(file_text)
		JSON_EXT:
			parse_res = JSON.parse(file_text)

	if parse_res.error != OK:
		return Safely.err(Error.Code.EXTENSION_MANAGER_RESOURCE_CONFIG_PARSE_FAILURE,
			"Path: %s\nLine: %d\nDescription: %s" % [
				config_path, parse_res.error_line, parse_res.error_string
			])
	if not parse_res.result is Dictionary:
		return Safely.err(Error.Code.EXTENSION_MANAGER_RESOURCE_UNEXPECTED_CONFIG_TYPE, config_path)

	data = parse_res.result
	
	var metadata: Dictionary = data.get(EXTENSION_SECTION, {})

	if metadata.empty():
		return Safely.err(Error.Code.EXTENSION_MANAGER_MISSING_EXTENSION_SECTION, config_path)
	
	var extension := Extension.new()
	extension.context = path
	extension.extension_name = metadata.get(ExtensionKeys.NAME, "")
	if extension.extension_name.empty():
		return Safely.err(Error.Code.EXTENSION_MANAGER_MISSING_EXTENSION_NAME, config_path)
	extension.translation_key = metadata.get(
		ExtensionKeys.TRANSLATION_KEY, extension.extension_name)

	if not data.has(RESOURCES_SECTION):
		return Safely.err(Error.Code.EXTENSION_MANAGER_NO_RESOURCES_FOUND, config_path)

	for table in data[RESOURCES_SECTION]:
		var res: Result = Safely.wrap(_parse_extension_item(dir, extension, table))
		if res.is_err():
			return res # Immediately stop processing a bad extension

	return Safely.ok(extension)

func _parse_extension_item(dir: Directory, e: Extension, data: Dictionary) -> Result:
	var resource_name: String = data.get(ResourceKeys.NAME, "")
	if resource_name.empty():
		return Safely.err(Error.Code.EXTENSION_MANAGER_MISSING_RESOURCE_NAME, e.context)
	var entrypoint: String = data.get(ResourceKeys.ENTRYPOINT, "")
	if entrypoint.empty():
		return Safely.err(Error.Code.EXTENSION_MANAGER_MISSING_RESOURCE_ENTRYPOINT, e.context)

	#region Construct resource

	var ext_resource := Extension.ExtensionResource.new() if not data.get(ResourceKeys.GDNATIVE, false) \
		else Extension.GDNativeExtensionResource.new()
	
	ext_resource.extension_name = e.extension_name
	ext_resource.resource_name = resource_name
	ext_resource.tags.append_array(data.get(ResourceKeys.TAGS, []))
	ext_resource.entrypoint = "%s/%s" % [e.context, entrypoint]
	ext_resource.translation_key = data.get(ResourceKeys.TRANSLATION_KEY, resource_name)

	if ext_resource is Extension.GDNativeExtensionResource:
		var gdnative_dir: String = "%s/%s" % [e.context, entrypoint]

		if not dir.dir_exists(gdnative_dir):
			return Safely.err(Error.Code.EXTENSION_MANAGER_BAD_GDNATIVE_ENTRYPOINT, gdnative_dir)
		
		if AM.grl.process_folder(gdnative_dir) != OK:
			return Safely.err(Error.Code.EXTENSION_MANAGER_FAILED_PROCESSING_GDNATIVE, gdnative_dir)
		
		ext_resource.entrypoint = entrypoint
	
	for key in ResourceKeys.Extra.values():
		if not data.has(key):
			continue
		ext_resource.extra[key] = data[key]
	
	#endregion

	e.resources[resource_name] = ext_resource
	for tag in ext_resource.tags:
		if not e.tags.has(tag):
			e.tags[tag] = []
		e.tags[tag].append(ext_resource)

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
## @param: tag: String - The extension tag
##
## @return: Array<ExtensionResource> - The extension resources that match the `ext_type`
func query_extensions_for_tag(tag: String) -> Array:
	var r := []

	for extension in extensions.values():
		r.append_array(extension.tags.get(tag, []))

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

	result = result.unwrap().load_raw(rel_res_path)
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

	var native_class = AM.grl.create_class(ext_res.entrypoint, clazz_name)
	if native_class == null:
		return Safely.err(Error.Code.EXTENSION_MANAGER_BAD_GDNATIVE_CLASS, clazz_name)

	return Safely.ok(native_class)
