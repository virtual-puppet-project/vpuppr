class_name NodeUtil
extends Reference

#-----------------------------------------------------------------------------#
# Builtin functions                                                           #
#-----------------------------------------------------------------------------#

func _init() -> void:
	pass

#-----------------------------------------------------------------------------#
# Connections                                                                 #
#-----------------------------------------------------------------------------#

#-----------------------------------------------------------------------------#
# Private functions                                                           #
#-----------------------------------------------------------------------------#

#-----------------------------------------------------------------------------#
# Public functions                                                            #
#-----------------------------------------------------------------------------#

## Frees a node. Meant to be used as a signal callback
##
## @param: node: Node - The node to free
static func try_free(node: Node) -> void:
	if node == null or not is_instance_valid(node):
		AM.logger.error("NodeUtil node is not valid, cannot free")
		return
	node.free()

## Queue frees a node. Meant to be used as a signal callback
##
## @param: node: Node - The node to queue free
static func try_queue_free(node: Node) -> void:
	if node == null or not is_instance_valid(node):
		AM.logger.error("NodeUtil node is not valid, cannot queue_free")
		return
	node.queue_free()
