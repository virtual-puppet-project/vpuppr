class_name GOTH
extends Reference

"""
GOdot Test Harness
uwu
"""

const TEST_PREFIX: String = "test"
const BASE_TEST_DIRECTORY: String = "res://tests/"

var test_paths: Array = [] # String

###############################################################################
# Builtin functions                                                           #
###############################################################################

func _init() -> void:
	var dir: Directory = Directory.new()
	var current_directory: String = BASE_TEST_DIRECTORY
	var directories: Array = [] # String
	
	# Loop through all found directories
	while dir.open(current_directory) == OK:
		dir.list_dir_begin(true, true)
		
		var file_name: String = dir.get_next()
		# Loop through current directory
		while file_name != "":
			if (file_name == "GOTH.gd" or file_name == "TestBase.gd"):
				file_name = dir.get_next()
				continue
			var absolute_path: String = "%s/%s" % [dir.get_current_dir(), file_name]
			if dir.current_is_dir():
				directories.append(absolute_path)
			if file_name.left(4).to_lower() == TEST_PREFIX:
				test_paths.append(absolute_path)
			
			file_name = dir.get_next()
		
		if not directories.empty():
			current_directory = directories.pop_back()
		else:
			break

###############################################################################
# Connections                                                                 #
###############################################################################

###############################################################################
# Private functions                                                           #
###############################################################################

###############################################################################
# Public functions                                                            #
###############################################################################

func run(test_name: String = "") -> void:
	for test in test_paths:
		if not test_name.empty():
			if test.get_file() == test_name:
				var specific_test = load(test).new()
				if not specific_test is TestBase:
					push_error("Invalid test file loaded")
					return
				(specific_test as TestBase).run_tests()
				break
			else:
				continue
		
		var test_file = load(test).new()
		if not test_file is TestBase:
			push_error("Invalid test file loaded")
			return
		
		(test_file as TestBase).run_tests()
