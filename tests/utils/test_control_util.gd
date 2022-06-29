extends "res://tests/base_test.gd"

# https://github.com/bitwes/Gut/wiki/Quick-Start

#-----------------------------------------------------------------------------#
# Builtin functions                                                           #
#-----------------------------------------------------------------------------#

func before_all():
	.before_all()

func before_each():
	control = Control.new()

func after_each():
	control.free()

func after_all():
	pass

#-----------------------------------------------------------------------------#
# Utils                                                                       #
#-----------------------------------------------------------------------------#

#-----------------------------------------------------------------------------#
# Tests                                                                       #
#-----------------------------------------------------------------------------#

var control: Control

func test_h_expand_fill():
	assert_eq(control.size_flags_horizontal, Control.SIZE_FILL)

	ControlUtil.h_expand_fill(control)

	assert_eq(control.size_flags_horizontal, Control.SIZE_EXPAND_FILL)

func test_v_expand_fill():
	assert_eq(control.size_flags_vertical, Control.SIZE_FILL)

	ControlUtil.v_expand_fill(control)

	assert_eq(control.size_flags_vertical, Control.SIZE_EXPAND_FILL)

func test_all_expand_fill():
	assert_eq(control.size_flags_horizontal, Control.SIZE_FILL)
	assert_eq(control.size_flags_vertical, Control.SIZE_FILL)

	ControlUtil.all_expand_fill(control)

	assert_eq(control.size_flags_horizontal, Control.SIZE_EXPAND_FILL)
	assert_eq(control.size_flags_vertical, Control.SIZE_EXPAND_FILL)
