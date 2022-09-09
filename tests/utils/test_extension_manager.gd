extends "res://tests/base_test.gd"

# https://github.com/bitwes/Gut/wiki/Quick-Start

#-----------------------------------------------------------------------------#
# Builtin functions                                                           #
#-----------------------------------------------------------------------------#

func before_all():
	.before_all()

func before_each():
	AM.em = partial_double(
		"res://tests/utils/test_extension_manager.gd",
		"ExtensionManagerTester"
	).new()

func after_each():
	AM.em.extensions.clear()
	# This seems to return false indicating it was not successful, but adding this line
	# prevents a resource leak warning when this test is complete
	# How curious :thinking:
	AM.em.unreference()

func after_all():
	pass

#-----------------------------------------------------------------------------#
# Utils                                                                       #
#-----------------------------------------------------------------------------#

class ExtensionManagerTester extends ExtensionManager:
	func _init() -> void:
		pass
	
	func _setup_class() -> void:
		pass

#-----------------------------------------------------------------------------#
# Tests                                                                       #
#-----------------------------------------------------------------------------#

# NOTE GDNative loading cannot be tested in CI, as the required binaries are not checked
# into git. We could do this but it's bad practice

func test_scan_pass():
	var scan_path := "res://tests/test_resources/extension_resources/good_extensions/"
	
	AM.em._scan(scan_path)

	assert_called(AM.em, "_scan")
	assert_call_count(AM.em, "_scan", 1)
	assert_called(AM.em, "_parse_extension")

	assert_has(AM.em.extensions, "TestExtension")
	assert_has(AM.em.extensions, "Other-Test_extension")

	#region TestExtension

	var ext_res: Result = AM.em.get_extension("TestExtension")

	assert_true(ext_res.is_ok())

	# Test loading a resource from a context

	var extension: Extension = ext_res.unwrap()

	var runner_res = extension.load_resource("runner_entrypoint.gd")

	assert_true(runner_res.is_ok())

	var runner = runner_res.unwrap().new()
	
	assert_true(runner.success())

	# Test loading a resource from its entrypoint

	var runner_script = load(AM.em.extensions["TestExtension"].resources["Runner"].resource_entrypoint)

	assert_true(runner_script is GDScript)

	runner = runner_script.new()

	assert_true(runner.success())

	var tracking_dummy_res: Result = AM.em.find_in_extensions(
		"TestExtension/resources/TrackingDummy/resource_entrypoint")

	assert_true(tracking_dummy_res.is_ok())

	var tracking_dummy = load(tracking_dummy_res.unwrap()).new()

	var tracking_backend_dummy = tracking_dummy.get_tracking_backend()

	assert_true(tracking_backend_dummy.is_listening())
	assert_eq(tracking_backend_dummy.test_func(), 10)
	
	# TODO test applying data to a model using apply(...)

	#endregion

# TODO I think this test is flaky
# It crashed the test runner once, which is something that happens when a library is unloaded
# Hard to reproduce :<
#func test_gdnative_pass():
#	if OS.get_environment("VSS_ENV") or OS.has_feature("Server"):
#		gut.p("Skipping in ci build")
#		return
#	var res: Result = AM.em._parse_extension(
#		"res://tests/test_resources/extension_resources/gdnative_extension/")
#
#	assert_true(res.is_ok())
#
#	var pinger_res = AM.em.load_gdnative_resource("GDNativeExtension", "PingerNative", "Pinger")
#	assert_true(pinger_res.is_ok())
#
#	var pinger = pinger_res.unwrap()
#	assert_has_method(pinger, "ping")
#	assert_has_method(pinger, "count_up_msec")
#	assert_has_method(pinger, "add_int")
#	assert_eq(pinger.add_int(1, 2), 3)
