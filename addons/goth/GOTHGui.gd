tool
class_name GOTHGui
extends MarginContainer

signal should_run_unit_tests(test_name)
signal should_run_bdd_tests(test_name)
signal should_rescan

onready var run_unit_tests_button: Button = $MarginContainer/HBoxContainer/OptionContainer/MarginContainer/OptionList/UnitTestHBox/RunUnitTestsButton
onready var unit_test_line_edit: LineEdit = $MarginContainer/HBoxContainer/OptionContainer/MarginContainer/OptionList/UnitTestHBox/UnitTestLineEdit

onready var run_bdd_tests_button: Button = $MarginContainer/HBoxContainer/OptionContainer/MarginContainer/OptionList/BDDTestHBox/RunBDDTestsButton
onready var bdd_test_line_edit: LineEdit = $MarginContainer/HBoxContainer/OptionContainer/MarginContainer/OptionList/BDDTestHBox/BDDTestLineEdit

onready var rescan_button: Button = $MarginContainer/HBoxContainer/OptionContainer/MarginContainer/OptionList/Rescan

onready var clear_output_button: Button = $MarginContainer/HBoxContainer/OptionContainer/MarginContainer/OptionList/ClearOutput

onready var output: VBoxContainer = $MarginContainer/HBoxContainer/OutputContainer/MarginContainer/ScrollContainer/Output
onready var scroll_container: ScrollContainer = $MarginContainer/HBoxContainer/OutputContainer/MarginContainer/ScrollContainer

###############################################################################
# Builtin functions                                                           #
###############################################################################

func _ready() -> void:
	run_unit_tests_button.connect("pressed", self, "_on_run_unit_tests")
	run_bdd_tests_button.connect("pressed", self, "_on_run_bdd_tests")
	rescan_button.connect("pressed", self, "_on_rescan")
	
	clear_output_button.connect("pressed", self, "_clear_output")

###############################################################################
# Connections                                                                 #
###############################################################################

func _on_run_unit_tests() -> void:
	_clear_output()
	_on_message_logged("Running unit tests")
	emit_signal("should_run_unit_tests", unit_test_line_edit.text)

func _on_run_bdd_tests() -> void:
	_clear_output()
	_on_message_logged("Running BDD tests")
	emit_signal("should_run_bdd_tests", bdd_test_line_edit.text)

func _on_rescan() -> void:
	_clear_output()
	_on_message_logged("Rescanning 'tests/' directory")
	emit_signal("should_rescan")

func _on_message_logged(message: String) -> void:
	var label: Label = Label.new()
	label.text = message
	output.call_deferred("add_child", label)
	yield(label, "ready")
	
	scroll_container.scroll_vertical = int(scroll_container.get_v_scrollbar().max_value)

###############################################################################
# Private functions                                                           #
###############################################################################

func _clear_output() -> void:
	for c in output.get_children():
		c.queue_free()

###############################################################################
# Public functions                                                            #
###############################################################################


