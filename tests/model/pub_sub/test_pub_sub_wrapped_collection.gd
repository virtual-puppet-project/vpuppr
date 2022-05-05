extends "res://addons/gut/test.gd"

# https://github.com/bitwes/Gut/wiki/Quick-Start

###############################################################################
# Builtin functions                                                           #
###############################################################################

func before_all():
	pass

func before_each():
	pass

func after_each():
	pass

func after_all():
	pass

###############################################################################
# Utils                                                                       #
###############################################################################

###############################################################################
# Tests                                                                       #
###############################################################################

func test_wrapped_collection():
	var array := [1, 2, 3]
	var id: int = 1
	var signal_name := "test_signal"

	var data := PubSubWrappedCollection.new(array, id, signal_name)

	assert_eq(data.get_changed(), 2)

	var wrapped_array = data.get_data()

	if not assert_eq(typeof(wrapped_array), TYPE_ARRAY):
		return
	if not assert_eq(wrapped_array.size(), 3):
		return

	for idx in wrapped_array.size():
		assert_eq(wrapped_array[idx], array[idx])
