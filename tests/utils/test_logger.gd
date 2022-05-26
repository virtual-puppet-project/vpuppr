extends "res://tests/base_test.gd"

# https://github.com/bitwes/Gut/wiki/Quick-Start

#-----------------------------------------------------------------------------#
# Builtin functions                                                           #
#-----------------------------------------------------------------------------#

func before_all():
	.before_all()

func before_each():
	pass

func after_each():
	pass

func after_all():
	pass

#-----------------------------------------------------------------------------#
# Utils                                                                       #
#-----------------------------------------------------------------------------#

#-----------------------------------------------------------------------------#
# Tests                                                                       #
#-----------------------------------------------------------------------------#

func test_setup_pass():
	var l0 := Logger.new()

	l0.setup("test string")

	assert_eq(l0.parent_name, "test string")

	var l1 := Logger.new()

	l1.setup(l1)

	assert_eq(l1.parent_name, l1.get_script().resource_path.get_file())

	var node := Node.new()
	node.name = "Node"

	var l2 := Logger.new(node)

	assert_eq(l2.parent_name, "Node")

	node.free()
