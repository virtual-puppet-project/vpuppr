extends XMLParser

"""
One GuiFileParser per xml file.

No text data will be read, all data is passed as node attributes.
"""

class NodeData:
	var node_name: String = "changeme"
	var data: Dictionary = {}
	var is_empty: bool = false
	var is_complete: bool = false

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

func open_resource(resource_path: String) -> void:
	open(resource_path)

func read_node() -> NodeData:
	var nd := NodeData.new()
	# Using a match so we can check for other node types in the future
	match get_node_type():
		XMLParser.NODE_ELEMENT:
			nd.node_name = get_node_name()
			for i in get_attribute_count():
				nd.data[get_attribute_name(i)] = get_attribute_value(i)
		_:
			nd.is_empty = true

	# Move pointer to next node
	if read() != OK:
		# Assume we are done reading on any error
		nd.is_complete = true

	return nd
