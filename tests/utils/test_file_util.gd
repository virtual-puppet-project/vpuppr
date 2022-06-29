extends "res://tests/base_test.gd"

# https://github.com/bitwes/Gut/wiki/Quick-Start

#-----------------------------------------------------------------------------#
# Builtin functions                                                           #
#-----------------------------------------------------------------------------#

func before_all():
	.before_all()

	var dir := Directory.new()
	if not dir.dir_exists(TEST_TEMP_DIR):
		dir.make_dir_recursive(TEST_TEMP_DIR)

func before_each():
	pass

func after_each():
	pass

func after_all():
	var dir := Directory.new()
	if not dir.file_exists(FILE_PATH):
		return
	
	if dir.remove(FILE_PATH) != OK:
		assert_false(true, "Unable to remove test resource %s" % FILE_PATH)

#-----------------------------------------------------------------------------#
# Utils                                                                       #
#-----------------------------------------------------------------------------#

#-----------------------------------------------------------------------------#
# Tests                                                                       #
#-----------------------------------------------------------------------------#

const FILE_PATH := "res://tests/temp/my_file.gd"
const FILE_CONTENT := "var my_content"

func test_save_load_remove_pass():
	var res = FileUtil.save_file_at_path(FILE_PATH, FILE_CONTENT)

	if not assert_result_is_ok(res):
		return
	if not assert_eq(res.unwrap(), FILE_PATH):
		return

	res = FileUtil.load_godot_resource_from_path(FILE_PATH)

	if not assert_result_is_ok(res):
		return
	if not assert_true(res.unwrap() is Reference):
		print(res.unwrap())
		return

	assert_eq(res.unwrap().get_script().source_code, FILE_CONTENT)

	res = FileUtil.remove_file_at_path(FILE_PATH)

	if not assert_result_is_ok(res):
		return
	if not assert_eq(res.unwrap(), FILE_PATH):
		return
