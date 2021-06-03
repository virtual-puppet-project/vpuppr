extends TestBase

const BASE_CONTAINER: Resource = preload("res://screens/gui/BaseContainer.tscn")

var tree: SceneTree

###############################################################################
# Builtin functions                                                           #
###############################################################################

###############################################################################
# Utils                                                                       #
###############################################################################

func _construct_test() -> void:
	if tree:
		tree.free()
	tree = SceneTree.new()

###############################################################################
# Tests                                                                       #
###############################################################################

func test_add_to_outer() -> void:
	_construct_test()

	var bc = BASE_CONTAINER.instance()

	tree.root.add_child(bc)

	yield(bc, "ready")

	var control_0: Control = Control.new()
	control_0.name = "control_0"
	var control_1: Control = Control.new()
	control_1.name = "control_1"

	bc.add_to_outer(control_0, 0)
	bc.add_to_outer(control_1, 0)

	assert(bc.outer.get_child(0).name == control_1.name)
	assert(bc.outer.get_child(1).name == control_0.name)

func test_add_to_inner() -> void:
	pass

func test_get_inner_children() -> void:
	pass

func test_clear_children() -> void:
	pass
