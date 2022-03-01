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

class TestClass:
	var callback_count: int = 0
	var other_callback_count: int = 0
	var other_callback_args := []

	var metadata_changed_count: int = 0

	func _callback(_text: String) -> void:
		callback_count += 1

	func _other_callback(_k: String, _v, arg0, arg1) -> void:
		other_callback_count += 1
		other_callback_args.append(arg0)
		other_callback_args.append(arg1)

	func _on_metadata_changed(_k: String, _v) -> void:
		metadata_changed_count += 1

###############################################################################
# Tests                                                                       #
###############################################################################

var pub_sub: PubSub

func test_register_pass():
	watch_signals(pub_sub)

	var test_class := TestClass.new()

	pub_sub.register(test_class, "metadata_changed")
	pub_sub.register(test_class, "logger_rebroadcast", PubSub.RegisterPayload.new("_callback"))
	pub_sub.register(test_class, "model_config_data_changed", PubSub.RegisterPayload.new({
		"args": ["test_arg0", "test_arg1"],
		"custom_callback": "_other_callback"
	}))

	pub_sub.broadcast_metadata_changed("test_key", "test_value")

	assert_signal_emit_count(pub_sub, "metadata_changed", 1)
	assert_eq(test_class.metadata_changed_count, 1)

	pub_sub.broadcast_logger_rebroadcast("test")
	pub_sub.broadcast_logger_rebroadcast("test")

	pub_sub.broadcast_model_config_data_changed("other_test_key", "other_test_value")

	assert_signal_emit_count(pub_sub, "logger_rebroadcast", 2)
	assert_eq(test_class.callback_count, 2)

	assert_signal_emit_count(pub_sub, "model_config_data_changed", 1)
	assert_eq(test_class.other_callback_count, 1)
	assert_has(test_class.other_callback_args, "test_arg0")
	assert_has(test_class.other_callback_args, "test_arg1")
	assert_does_not_have(test_class.other_callback_args, "other_test_key")
	assert_does_not_have(test_class.other_callback_args, "other_test_value")

func test_register_plugin_pass():
	pass
