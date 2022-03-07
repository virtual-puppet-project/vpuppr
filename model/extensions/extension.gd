class_name Extension
extends Reference

var extension_name := ""

class ExtensionResource:
	var resource_name := ""
	var resource_type := ""
	var resource_entrypoint := ""

	func _init(p_resource_name: String, p_type: String, p_entrypoint: String) -> void:
		resource_name = p_resource_name
		resource_type = p_type
		resource_entrypoint = p_entrypoint

var resources := {}

###############################################################################
# Builtin functions                                                           #
###############################################################################

func _init() -> void:
	pass

###############################################################################
# Connections                                                                 #
###############################################################################

###############################################################################
# Private functions                                                           #
###############################################################################

###############################################################################
# Public functions                                                            #
###############################################################################

func add_resource(res_name: String, res_type: String, res_entrypoint: String) -> Result:
	if resources.has(res_type):
		return Result.err(Error.Code.EXTENSION_RESOURCE_ALREADY_EXISTS)

	resources[res_name] = ExtensionResource.new(
		res_name,
		res_type,
		res_entrypoint
	)

	return Result.ok()
