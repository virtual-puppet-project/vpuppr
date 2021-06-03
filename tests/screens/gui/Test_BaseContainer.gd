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

	# All outer children are preset
	assert(bc.outer.get_child(0).name == control_1.name)
	assert(bc.outer.get_child(1).name == control_0.name)

	# No inner children are present
	assert(bc.inner.get_child_count() == 0)

func test_add_to_inner() -> void:
	_construct_test()

	var bc = BASE_CONTAINER.instance()

	tree.root.add_child(bc)

	yield(bc, "ready")

	var control_0: Control = Control.new()
	control_0.name = "control_0"
	var control_1: Control = Control.new()
	control_1.name = "control_1"

	bc.add_to_inner(control_0)
	bc.add_to_inner(control_1)

	# All inner children are present
	assert(bc.inner.get_child(0).name == control_0.name)
	assert(bc.inner.get_child(1).name == control_1.name)

	assert(bc.outer.get_child_count() == 0)

func test_get_inner_children() -> void:
	_construct_test()

	var bc = BASE_CONTAINER.instance()

	tree.root.add_child(bc)

	yield(bc, "ready")

	var control_0: Control = Control.new()
	control_0.name = "control_0"
	var control_1: Control = Control.new()
	control_1.name = "control_1"

	bc.add_to_inner(control_0)
	bc.add_to_inner(control_1)

	# Check inner children
	assert(bc.get_inner_children().size() == 2)
	assert(bc.inner.get_child_count() == 2)

func test_clear_children() -> void:
	_construct_test()

	var bc = BASE_CONTAINER.instance()

	tree.root.add_child(bc)

	yield(bc, "ready")

	var control_0: Control = Control.new()
	control_0.name = "control_0"
	var control_1: Control = Control.new()
	control_1.name = "control_1"

	bc.add_to_inner(control_0)
	bc.add_to_inner(control_1)

	yield(tree, "idle_frame")

	assert(bc.get_inner_children() == 2)

	bc.clear_children()

	yield(tree, "idle_frame")

	assert(bc.get_inner_children() == 0)
