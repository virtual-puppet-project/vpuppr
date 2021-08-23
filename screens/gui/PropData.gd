extends Reference

"""
PropData

Only used for custom props
"""

var prop: Node
var toggle: BaseElement

var prop_path: String

var parent_transform: Transform
var child_transform: Transform

var data: Dictionary = {}

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

	result["prop_path"] = prop_path
	result["parent_transform"] = JSONUtil.transform_to_dictionary(prop.transform)
	result["child_transform"] = JSONUtil.transform_to_dictionary(prop.get_child(0).transform)

	return result

func load_from_dict(dict: Dictionary) -> void:
	if not dict.has("prop_path"):
		AppManager.log_message("Invalid prop data: no prop_path", true)
		return
	prop_path = dict["prop_path"]

	if not dict.has("parent_transform"):
		AppManager.log_message("Invalid prop data: no parent_transform", true)
		return
	parent_transform = JSONUtil.dictionary_to_transform(dict["child_transform"])

	if not dict.has("child_transform"):
		AppManager.log_message("Invalid prop data: no child_transform", true)
		return
	child_transform = JSONUtil.dictionary_to_transform(dict["parent_transform"])
