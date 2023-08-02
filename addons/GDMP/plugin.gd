@tool
extends EditorPlugin

var exporter: EditorExportPlugin = preload("editor/exporter.gd").new()

func _enter_tree() -> void:
	add_export_plugin(exporter)

func _exit_tree() -> void:
	remove_export_plugin(exporter)
