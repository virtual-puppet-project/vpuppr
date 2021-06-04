tool
extends EditorPlugin

var goth = load("res://addons/goth/GOTH.gd").new()
var goth_ui

###############################################################################
# Builtin functions                                                           #
###############################################################################

func _enter_tree() -> void:
	goth_ui = load("res://addons/goth/GOTHGui.tscn").instance()
	
	add_control_to_bottom_panel(goth_ui, "GOTH")
	
	yield(get_tree(), "idle_frame")
	
	goth_ui.connect("should_run_unit_tests", goth, "run_unit_tests")
	goth_ui.connect("should_run_bdd_tests", goth, "run_bdd_tests")
	goth_ui.connect("should_rescan", goth, "scan")
	
	goth.connect("message_logged", goth_ui, "_on_message_logged")

func _exit_tree() -> void:
	remove_control_from_bottom_panel(goth_ui)
	
	if goth_ui.is_connected("should_run_unit_tests", goth, "run_unit_tests"):
		goth_ui.disconnect("should_run_unit_tests", goth, "run_unit_tests")
	if goth_ui.is_connected("should_run_bdd_tests", goth, "run_bdd_tests"):
		goth_ui.disconnect("should_run_bdd_tests", goth, "run_bdd_tests")
	if goth_ui.is_connected("should_rescan", goth, "scan"):
		goth_ui.disconnect("should_rescan", goth, "scan")
	
	if goth.is_connected("message_logged", goth_ui, "_on_message_logged"):
		goth.disconnect("message_logged", goth_ui, "_on_message_logged")
	
	goth_ui.free()

###############################################################################
# Connections                                                                 #
###############################################################################

###############################################################################
# Private functions                                                           #
###############################################################################

###############################################################################
# Public functions                                                            #
###############################################################################


