extends Reference

## Returns data tailored for the default gui
func run() -> Dictionary:
	var r := {
		"name": "OpenSeeFaceUI"
	}

	var nodes := []

	if OS.get_name().to_lower() == "x11":
		nodes.append(_python_path())

	r["nodes"] = nodes

	return r

func _h_fill_expand(control: Control) -> void:
	control.size_flags_horizontal = Control.SIZE_EXPAND_FILL

func _python_path() -> HBoxContainer:
	var r := HBoxContainer.new()
	_h_fill_expand(r)

	var label := Label.new()
	_h_fill_expand(label)
	label.text = "Python path"

	var line_edit := LineEdit.new()
	_h_fill_expand(line_edit)
	line_edit.placeholder_text = "/path/to/python/binary"

	r.add_child(label)
	r.add_child(line_edit)

	return r
