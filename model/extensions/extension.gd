class_name Extension
extends Reference

class ExtensionResource extends Reference:
	var extension_name := ""
	var resource_name := ""
	var tags := []
	var entrypoint := ""
	var translation_key := ""

	var extra := {}

class GDNativeExtensionResource extends ExtensionResource:
	pass

var extension_name := ""
var translation_key := ""

## Absolute path to the extension
var context := ""
var resources := {} # Name: String -> ExtensionResource

## Dictionary<String, Array<ExtensionResources>>
var tags := {}

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

## Gets all data as a Dictionary
##
## @return: Dictionary - The Dictionary of Extension properties
func as_data() -> Dictionary:
	return {
		"extension_name": extension_name,
		"translation_key": translation_key,
		"context_path": context,
		"resources": resources.duplicate()
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
