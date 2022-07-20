class_name Extension
extends Reference

var extension_name := ""

var context: ExtensionContext
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

func _init(context_path: String) -> void:
	context = ExtensionContext.new(context_path)

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
		"context_path": context.context_path,
		"runner": runners.duplicate(),
		"puppet": puppets.duplicate(),
		"tracker": trackers.duplicate(),
		"gui": guis.duplicate(),
		"plugin": plugins.duplicate()
	}
