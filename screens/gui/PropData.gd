extends Reference

"""
PropData

Only used for custom props. Used for passing around information
"""

var prop_name: String
var prop: Node
var toggle: BaseElement

var prop_path: String

var parent_transform: Transform
var child_transform: Transform

###############################################################################
# Builtin functions                                                           #
###############################################################################

###############################################################################
# Connections                                                                 #
###############################################################################

###############################################################################
# Private functions                                                           #
###############################################################################

###############################################################################
# Public functions                                                            #
###############################################################################

func get_as_dict() -> Dictionary:
	var result: Dictionary = {}

	result["prop_name"] = prop_name
	result["prop_path"] = prop_path
	result["parent_transform"] = JSONUtil.transform_to_dictionary(prop.transform)
	result["child_transform"] = JSONUtil.transform_to_dictionary(prop.get_child(0).transform)

	return result

func load_from_dict(dict: Dictionary) -> void:
	if not dict.has("prop_name"):
		AppManager.logger.error("Invalid prop data: no prop_name")
		return
	prop_name = dict["prop_name"]

	if not dict.has("prop_path"):
		AppManager.logger.error("Invalid prop data: no prop_path")
		return
	prop_path = dict["prop_path"]

	if not dict.has("parent_transform"):
		AppManager.logger.error("Invalid prop data: no parent_transform")
		return
	parent_transform = JSONUtil.dictionary_to_transform(dict["parent_transform"])

	if not dict.has("child_transform"):
		AppManager.logger.error("Invalid prop data: no child_transform")
		return
	child_transform = JSONUtil.dictionary_to_transform(dict["child_transform"])
