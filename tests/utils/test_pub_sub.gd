extends "res://tests/base_test.gd"

# https://github.com/bitwes/Gut/wiki/Quick-Start

###############################################################################
# Builtin functions                                                           #
###############################################################################

func before_all():
	.before_all()

func before_each():
	pub_sub = PubSub.new()

func after_each():
	pass

func after_all():
	pass

###############################################################################
# Utils                                                                       #
###############################################################################

class MyClass:
	var callback_count: int = 0

	func _on_callback() -> void:
		callback_count += 1

	var other_callback_count: int = 0
	var other_callback_arg := ""

	func _other_callback(k: String) -> void:
		other_callback_count += 1
		other_callback_arg = k

	var last_callback_count: int = 0
	var args := []
	var key := ""

	func _last_callback(arg, p_key: String = "") -> void:
		last_callback_count += 1
		args.append(arg)
		key = p_key

###############################################################################
# Tests                                                                       #
###############################################################################

var pub_sub: PubSub

func test_register_for_signal_pass():
	pub_sub.add_user_signal("callback")
	pub_sub.add_user_signal("other_signal")
	pub_sub.add_user_signal("last_signal")
	
	watch_signals(pub_sub)

	var test_class := MyClass.new()
	
	pub_sub.register(test_class, "callback")
	pub_sub.register(test_class, "other_signal", PubSubRegisterPayload.new("_other_callback"))
	pub_sub.register(test_class, "last_signal", PubSubRegisterPayload.new({
		"callback": "_last_callback",
		"args": ["test_key"]
	}))

	pub_sub.emit_signal("callback")
	
	assert_signal_emit_count(pub_sub, "callback", 1)
	assert_eq(test_class.callback_count, 1)

	pub_sub.emit_signal("callback")

	pub_sub.emit_signal("other_signal", "test")

	pub_sub.emit_signal("last_signal", "arg0")
	pub_sub.emit_signal("last_signal", "arg1")

	assert_signal_emit_count(pub_sub, "callback", 2)
	assert_eq(test_class.callback_count, 2)

	assert_signal_emit_count(pub_sub, "other_signal", 1)
	assert_eq(test_class.other_callback_count, 1)
	assert_eq(test_class.other_callback_arg, "test")

	assert_signal_emit_count(pub_sub, "last_signal", 2)
	assert_eq(test_class.last_callback_count, 2)
	assert_eq(test_class.key, "test_key")
	assert_has(test_class.args, "arg0")
	assert_has(test_class.args, "arg1")
	assert_does_not_have(test_class.args, "test_key")
