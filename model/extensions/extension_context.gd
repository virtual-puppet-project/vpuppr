class_name ExtensionContext
extends Reference

## Extensions must use relative paths to their associated resources/scripts. This class helps
## wrap resource access so that extensions only need to provide a relative path.

## The absolute path to extension resources
var context_path := ""

#-----------------------------------------------------------------------------#
# Builtin functions                                                           #
#-----------------------------------------------------------------------------#

func _init(path: String) -> void:
	context_path = path

#-----------------------------------------------------------------------------#
# Connections                                                                 #
#-----------------------------------------------------------------------------#

#-----------------------------------------------------------------------------#
# Private functions                                                           #
#-----------------------------------------------------------------------------#

#-----------------------------------------------------------------------------#
# Public functions                                                            #
#-----------------------------------------------------------------------------#

## Reconstructs the absolute path to the resource and loads it
##
## @param: path: String - The relative path to a resource
##
## @return: Result<Variant> - The resource located at `path`
func load_resource(path: String) -> Result:
	var resource = load("%s/%s" % [context_path, path])
	if resource == null:
		return Result.err(Error.Code.EXTENSION_CONTEXT_RESOURCE_NOT_FOUND, path)
	
	return Result.ok(resource)

## Reconstructs the absolute paths to an array of resources and loads them
##
## @param: paths: Array - An array of resource paths
##
## @return: Array<Result<Variant>> - An array of Results containing resources
func load_resources(paths: Array) -> Array:
	var r := []
	
	for path in paths:
		r.append(load_resource(path))
	
	return r
