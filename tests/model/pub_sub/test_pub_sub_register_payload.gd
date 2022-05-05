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

func test_create_dict_pass():
	var payload := PubSubRegisterPayload.new({
		"args": ["hello", 1],
		"callback": "my_callback"
	})

	if not assert_eq(payload.args.size(), 2):
		return
	assert_eq(payload.args[0], "hello")
	assert_eq(payload.args[1], 1)

	assert_eq(payload.callback, "my_callback")

func test_create_array_pass():
	var payload := PubSubRegisterPayload.new(["my", "arg"])

	if not assert_eq(payload.args.size(), 2):
		return
	assert_eq(payload.args[0], "my")
	assert_eq(payload.args[1], "arg")
	
	assert_true(payload.callback.empty())

func test_create_string_pass():
	var payload := PubSubRegisterPayload.new("my_callback")

	assert_eq(payload.args.size(), 0)
	assert_eq(payload.callback, "my_callback")

func test_create_empty_pass():
	var payload := PubSubRegisterPayload.new()

	assert_eq(payload.args.size(), 0)
	assert_true(payload.callback.empty())

func test_create_fail():
	var payload := PubSubRegisterPayload.new(1)

	assert_eq(payload.args.size(), 0)
	assert_true(payload.callback.empty())
