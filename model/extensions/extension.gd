class_name Extension
extends Reference

var extension_name := ""
var translation_key := ""

## Absolute path to the extension
var context := ""
var resources := {} # Name: String -> ExtensionResource

# Presort resources, these all refer to something in the resources dictionary
var runners := [] # Resource name: String
var puppets := [] # Resources name: String
var trackers := [] # Resources name: String
var guis := [] # Resources name: String
var plugins := [] # Resources name: String

#-----------------------------------------------------------------------------#
# Builtin functions                                                           #
#-----------------------------------------------------------------------------#

#-----------------------------------------------------------------------------#
# Connections                                                                 #
#-----------------------------------------------------------------------------#

#-----------------------------------------------------------------------------#
# Private functions                                                           #
#-----------------------------------------------------------------------------#

#-----------------------------------------------------------------------------#
# Public functions                                                            #
#-----------------------------------------------------------------------------#

## Adds a resource and pre-sorts it
##
## @param: res_name: String - The name of the resource from the config file
## @param: res_type: String - The type of the resource from the config file
## @param: res_entrypoint: String - The absolute path for the entrypoint for the resource
##
## @return: Result<ExtensionResource> - The new ExtensionResource that's implicitly added
## to the Extension
func add_resource(res_name: String, res_type: String, res_entrypoint: String) -> Result:
	if resources.has(res_name):
		return Safely.err(Error.Code.EXTENSION_RESOURCE_ALREADY_EXISTS)

	var ext_res := ExtensionResource.new(
		extension_name,
		res_name,
		res_type,
		res_entrypoint
	)

	resources[res_name] = ext_res

	match res_type:
		Globals.ExtensionTypes.RUNNER:
			runners.append(res_name)
		Globals.ExtensionTypes.PUPPET:
			puppets.append(res_name)
		Globals.ExtensionTypes.TRACKER:
			trackers.append(res_name)
		Globals.ExtensionTypes.GUI:
			guis.append(res_name)
		Globals.ExtensionTypes.PLUGIN:
			plugins.append(res_name)
		_:
			return Safely.err(Error.Code.UNHANDLED_EXTENSION_TYPE)

	return Safely.ok(ext_res)

## Gets all data as a Dictionary
##
## @return: Dictionary - The Dictionary of Extension properties
func as_data() -> Dictionary:
	return {
		"extension_name": extension_name,
		"translation_key": translation_key,
		"context_path": context,
		"runner": runners.duplicate(),
		"puppet": puppets.duplicate(),
		"tracker": trackers.duplicate(),
		"gui": guis.duplicate(),
		"plugin": plugins.duplicate()
	}

func has_file(rel_path: String) -> bool:
	var file := File.new()
	
	return file.file_exists("%s/%s" % [context, rel_path])

func has_directory(rel_path: String) -> bool:
	var dir := Directory.new()
	
	return dir.dir_exists("%s/%s" % [context, rel_path])

func load_file_text(rel_path: String) -> Result:
	var file := File.new()
	if not file.file_exists(rel_path):
		return Safely.err(Error.Code.EXTENSION_CONTEXT_RESOURCE_NOT_FOUND, rel_path)
	
	if file.open("%s/%s" % [context, rel_path], File.READ) != OK:
		return Safely.err(Error.Code.FILE_PARSE_FAILURE, "%s/%s" % [context, rel_path])
	
	var file_text := file.get_as_text()
	
	file.close()
	
	return Safely.ok(file_text)

func load_resource(rel_path: String) -> Result:
	var resource = load("%s/%s" % [context, rel_path])
	if resource == null:
		return Safely.err(Error.Code.EXTENSION_CONTEXT_RESOURCE_NOT_FOUND, rel_path)
	
	return Safely.ok(resource)
