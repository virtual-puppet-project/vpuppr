tool
extends EditorPlugin

const PLUGIN_NAME := "REPL GD"
var repl: Control

func _enter_tree():
	repl = preload("res://addons/repl_gd/repl.tscn").instance()
	_inject_tool(repl)
	add_control_to_bottom_panel(repl, PLUGIN_NAME)

func _exit_tree():
	if repl != null:
		remove_control_from_bottom_panel(repl)
		repl.queue_free()

func _inject_tool(node: Node) -> bool:
	var script: Script = node.get_script().duplicate()
	script.source_code = "tool\n%s" % script.source_code
	if script.reload(false) != OK:
		return false
	
	node.set_script(script)
	
	return true
