extends "res://tests/base_test.gd"

const PROP_DATA: Resource = preload("res://screens/gui/PropData.gd")

###############################################################################
# Builtin functions                                                           #
###############################################################################

func _ready() -> void:
	pass

###############################################################################
# Utils                                                                       #
###############################################################################

###############################################################################
# Tests                                                                       #
###############################################################################

func test_load_from_dict() -> void:
	var prop_data: PROP_DATA
	var parent_transform = {
		"basis": { "x": { "x": 1, "y": 1, "z": 1 }, "y": { "x": 1, "y": 1, "z": 1 }, "z": { "x": 1, "y": 1, "z": 1 } },
		"origin": { "x": 1, "y": 1, "z": 1 }
	}
	var child_transform = {
		"basis": { "x": { "x": 2, "y": 2, "z": 2 }, "y": { "x": 2, "y": 2, "z": 2 }, "z": { "x": 2, "y": 2, "z": 2 } },
		"origin": { "x": 2, "y": 2, "z": 2 }
	}
	
	prop_data = PROP_DATA.new()
	prop_data.load_from_dict({
		"prop_name": "test_name",
		"prop_path": "test_path",
		"parent_transform": parent_transform,
		"child_transform": child_transform,
	})

	assert_true(prop_data.prop_name == "test_name")
	assert_true(prop_data.prop_path == "test_path")
	assert_true(prop_data.parent_transform.basis.x.x == 1)
	assert_true(prop_data.child_transform.basis.x.x == 2)
	
