extends "res://tests/base_test.gd"

# https://github.com/bitwes/Gut/wiki/Quick-Start

#-----------------------------------------------------------------------------#
# Builtin functions                                                           #
#-----------------------------------------------------------------------------#

func before_all():
	.before_all()

func before_each():
	osf = partial_double("res://resources/extensions/open_see_face/open_see_face.gd").new()
	add_child_autoqfree(osf)

func after_each():
	pass

func after_all():
	pass

#-----------------------------------------------------------------------------#
# Utils                                                                       #
#-----------------------------------------------------------------------------#

func _disable_threads() -> void:
	stub(osf, "start_receiver").to_do_nothing()
	stub(osf, "_receive").to_do_nothing()
	stub(osf, "_perform_reception").to_return(OK)

#-----------------------------------------------------------------------------#
# Tests                                                                       #
#-----------------------------------------------------------------------------#

const OSF_DATA_PATH := "res://resources/extensions/open_see_face/open_see_face_data.gd"

var osf

func test_scene_tree_pass():
	assert_true(osf._tree is SceneTree)
	assert_true(osf._tree.has_method("create_timer"))

func test_toggle_tracker_pass():
	_disable_threads()
	stub(osf, "_start_tracker").to_return(true)

	osf._on_event_published(SignalPayload.new(GlobalConstants.TRACKER_TOGGLED, true, "OpenSeeFace"))

	assert_true(osf.is_tracking)
	assert_true(osf.is_listening())
	
	assert_called(osf, "_start_tracker")
	assert_call_count(osf, "_start_tracker", 1)

	assert_called(osf, "start_receiver")
	assert_call_count(osf, "start_receiver", 1)

	assert_not_called(osf, "stop_receiver")
	assert_call_count(osf, "stop_receiver", 0)

	osf._on_event_published(SignalPayload.new(GlobalConstants.TRACKER_TOGGLED, false, "OpenSeeFace"))

	assert_false(osf.is_tracking)
	assert_false(osf.is_listening())

	assert_call_count(osf, "_start_tracker", 1)
	assert_call_count(osf, "start_receiver", 1)

	assert_called(osf, "stop_receiver")
	assert_call_count(osf, "stop_receiver", 1)

func test_get_data_pass():
	# We must use the non-doubled instance here since doubling strips out default func params
	osf.free()
	osf = OpenSeeFace.new()
	add_child_autoqfree(osf)
	
	var osfd0: OpenSeeFaceData = create_class(
		OSF_DATA_PATH,
		{
			"time": 10.0,
			"id": 0,
			"camera_resolution": Vector2.ONE,
			"right_eye_open": 1.0,
			"left_eye_open": 0.5
		}
	)
	osf.data_map[0] = osfd0

	var osfd1: OpenSeeFaceData = create_class(
		OSF_DATA_PATH,
		{
			"time": 11.0,
			"id": 1
		}
	)
	osf.data_map[1] = osfd1
	
	# Prefer interface access
	var data0 = osf.get_data()

	assert_not_null(data0)
	assert_eq(data0.time, 10.0)
	assert_eq(data0.id, 0)
	assert_eq(data0.camera_resolution, Vector2.ONE)
	assert_eq(data0.right_eye_open, 1.0)
	assert_eq(data0.left_eye_open, 0.5)
	
	var data1 = osf.get_data(1)
	
	assert_not_null(data1)
	assert_eq(data1.time, 11.0)
	assert_eq(data1.id, 1)
	
	# This is also possible but not portable
	# Returns the same thing as get_data() and get_data(0)
	var data2 = osf.data_map[0]
	
	assert_not_null(data2)
	assert_eq(data2.id, 0)
