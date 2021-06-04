tool
class_name GOTH
extends Reference

"""
GOth Test Harness
uwu
"""

signal message_logged(message)

const TEST_PREFIX: String = "test"
const STEP_PREFIX: String = "step"
const BDD_SUFFIX: String = "bdd"
const BASE_TEST_DIRECTORY: String = "res://tests/"

var test_paths: Array = [] # String

var bdd_paths: Array = [] # String
var step_paths: Array = [] # String

###############################################################################
# Builtin functions                                                           #
###############################################################################

func _init() -> void:
	scan()

###############################################################################
# Connections                                                                 #
###############################################################################

###############################################################################
# Private functions                                                           #
###############################################################################

###############################################################################
# Public functions                                                            #
###############################################################################

func log_message(message: String) -> void:
	if Engine.editor_hint:
		emit_signal("message_logged", message)
	else:
		print(message)

func scan() -> void:
	var dir: Directory = Directory.new()
	var current_directory: String = BASE_TEST_DIRECTORY
	var directories: Array = [] # String
	
	# Loop through all found directories
	while dir.open(current_directory) == OK:
		dir.list_dir_begin(true, true)
		
		var file_name: String = dir.get_next()
		# Loop through current directory
		while file_name != "":
			var absolute_path: String = "%s/%s" % [dir.get_current_dir(), file_name]
			if dir.current_is_dir():
				directories.append(absolute_path)

			if file_name.length() < 4:
				file_name = dir.get_next()
				continue
			
			if file_name.left(4).to_lower() == TEST_PREFIX:
				if file_name.get_extension() == BDD_SUFFIX:
					bdd_paths.append(absolute_path)
				else:
					test_paths.append(absolute_path)
			elif file_name.left(4).to_lower() == STEP_PREFIX:
				step_paths.append(absolute_path)
			
			file_name = dir.get_next()
		
		if not directories.empty():
			current_directory = directories.pop_back()
		else:
			break

func run_unit_tests(test_name: String = "") -> void:
	for test in test_paths:
		if not test_name.empty():
			if test.get_file() == test_name:
				var specific_test = load(test).new()
				specific_test.goth = self
				if not specific_test.has_method("run_tests"):
					push_error("Invalid test file loaded")
					return
				log_message(test)
				specific_test.run_tests()
				break
			else:
				continue
		
		var test_file = load(test).new()
		test_file.goth = self
		if not test_file.has_method("run_tests"):
			push_error("Invalid test file loaded")
			return
		log_message(test)
		test_file.run_tests()

func run_bdd_tests(test_name: String = "") -> void:
	var step_definitions: Dictionary = {}
	for step in step_paths:
		var step_file = load(step).new()
		step_definitions[step] = step_file.get_method_list()

	var bdd: BDD = BDD.new()
	bdd.step_definitions = step_definitions
	bdd.goth = self
	
	for path in bdd_paths:
		bdd.run(path)
