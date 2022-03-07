class_name ExtensionContext
extends Reference

"""
Extensions must use relative paths to their associated resources/scripts. This class helps
wrap resource access so that extensions only need to provide a relative path.
"""

var context_path := ""

###############################################################################
# Builtin functions                                                           #
###############################################################################

func _init(path: String) -> void:
	context_path = path

###############################################################################
# Connections                                                                 #
###############################################################################

###############################################################################
# Private functions                                                           #
###############################################################################

###############################################################################
# Public functions                                                            #
###############################################################################

func load_resource(path: String) -> Result:
	"""
	Reconstructs the absolute path to the resource and loads it in.
	
	Params:
		path: String - Relative path to a resource
	
	Return:
		Result[Variant]
	"""
	var resource = load("%s/%s" % [context_path, path])
	if resource == null:
		return Result.err(Error.Code.EXTENSION_CONTEXT_RESOURCE_NOT_FOUND, path)
	
	return Result.ok(resource)

func load_resources(paths: Array) -> Array:
	"""
	Reconstructs the absolute paths to an array of resources and loads them in
	
	Params:
		paths: Array - Array of resources paths
	
	Return:
		Array[Result] - Array of Results containing resources
	"""
	var r := []
	
	for path in paths:
		r.append(load_resource(path))
	
	return r
