class_name SettingsOption
extends HBoxContainer

## A settings option that consists of a (implied) [Label] and one other [Control].
##
## An [HBoxContainer] with an optional [Label] (one will be created using the name of the node
## if not provided) along with a [Control]. If using a custom control, that custom control
## must be configued here or expose its own [signal message_received] signal. [br]
## [br]
## The name of this node or the child [Label] will be used as the settings key. [br]
## [br]
## The following controls are supported: [br]
##
## [codeblock]
## LineEdit:
## A text field.
##
## LineEdit with a child HSlider:
## A number field.
##
## CheckButton:
## A toggleable option.
##
## OptionButton:
## A pickable option.
##
## ColorPickerButton:
## A pickable color.
## [/codeblock]

signal message_received(message: GUIMessage)

var _logger := Logger.create("SettingsOption")

## The parent of this node. This is used for message callbacks.
var _parent: Node = null
## The key used for updating settings.
var key := ""
## The control managed by this node.
var control: Control = null

#-----------------------------------------------------------------------------#
# Builtin functions
#-----------------------------------------------------------------------------#

func _init(p_name: String = "", control: Control = null) -> void:
	if p_name.is_empty() or control == null:
		return
	
	name = p_name
	
	add_child(_create_name_label())
	add_child(control)

func _ready() -> void:
	_parent = get_parent()
	if _parent == null:
		_logger.error("No parent found")
		return
	
	match get_child_count():
		1:
			_logger.debug("Creating label using node name")
			
			var name_label := _create_name_label()
			add_child(name_label)
			move_child(name_label, 0)
		2:
			if not get_child(0) is Label:
				_logger.error("First child must be a Label, bailing out")
				return
		_:
			_logger.error("Must contain either 1 or 2 child nodes, bailing out")
			return
	
	# Safe since we verify the amount of children before this
	var name_label: Label = get_child(0)
	key = name_label.text.to_snake_case()
	
	control = get_child(1)
	if get_child(1).is_queued_for_deletion():
		_logger.error("Second child is queued for deletion, bailing out")
		return
	
	if control.has_signal(message_received.get_name()):
		control.message_received.connect(func(message: GUIMessage) -> void:
			message_received.emit(message)
		)
	else:
		match control.get_class():
			"LineEdit":
				_setup_line_edit(control)
			"CheckButton":
				_setup_check_button(control)
			"OptionButton":
				_setup_option_button(control)
			"ColorPickerButton":
				_setup_color_picker_button(control)
			_:
				_logger.error("Unhandled control {c_name}, bailing out".format({
					c_name = control.get_class()
				}))
				return
	
	size_flags_horizontal = Control.SIZE_EXPAND_FILL
	for child in get_children():
		child.size_flags_horizontal = Control.SIZE_EXPAND_FILL

#-----------------------------------------------------------------------------#
# Private functions
#-----------------------------------------------------------------------------#

func _create_name_label() -> Label:
	var label := Label.new()
	label.text = name.capitalize()
	
	return label

func _setup_line_edit(line_edit: LineEdit) -> void:
	var text_received := func(text: String) -> void:
		message_received.emit(GUIMessage.new(_parent, GUIMessage.SETTING_CHANGED, key, text))
	
	var child_count := line_edit.get_child_count()
	if child_count > 0:
		if child_count != 1:
			_logger.error("Invalid amount of children for LineEdit, expected 1 got {num}".format({
				num = child_count
			}))
			return
		
		var line_edit_child: Node = line_edit.get_child(0)
		match line_edit_child.get_class():
			"HSlider":
				text_received = func(text: String) -> void:
					if not text.is_valid_float():
						return
					
					message_received.emit(
						GUIMessage.new(_parent, GUIMessage.SETTING_CHANGED, key, text.to_float())
					)
				line_edit.remove_child(line_edit_child)
				line_edit_child.drag_ended.connect(func(changed: bool) -> void:
					if not changed:
						return
					
					var string_value := String(line_edit_child.value)
					line_edit.text = String(string_value)
					text_received.call(string_value)
				)
			_:
				_logger.error("Unhandled LineEdit child {clazz}".format({
					clazz = line_edit_child.get_class()
				}))
				return
		
		remove_child(line_edit)
		
		var vbox := VBoxContainer.new()
		vbox.add_child(line_edit)
		vbox.add_child(line_edit_child)
		
		add_child(vbox)
	
	line_edit.text_changed.connect(text_received)
	line_edit.text_submitted.connect(text_received)

func _setup_check_button(check_button: CheckButton) -> void:
	check_button.toggled.connect(func(state: bool) -> void:
		message_received.emit(GUIMessage.new(_parent, GUIMessage.SETTING_CHANGED, key, state))
	)

func _setup_option_button(option_button: OptionButton) -> void:
	option_button.item_selected.connect(func(idx: int) -> void:
		var text := option_button.get_item_text(idx)
		
		message_received.emit(GUIMessage.new(_parent, GUIMessage.SETTING_CHANGED, key, text))
	)

func _setup_color_picker_button(color_picker_button: ColorPickerButton) -> void:
	color_picker_button.get_picker().color_changed.connect(func(color: Color) -> void:
		message_received.emit(GUIMessage.new(_parent, GUIMessage.SETTING_CHANGED, key, color))
	)

func _update_type_mismatch_log(expected: String) -> void:
	_logger.error("Tried to update {expected} but control was actually {actual}".format({
		expected = expected,
		actual = control.get_class()
	}))

#-----------------------------------------------------------------------------#
# Public functions
#-----------------------------------------------------------------------------#

func update_line_edit(text: String) -> void:
	if not control is LineEdit:
		_update_type_mismatch_log("LineEdit")
		return
	
	control.text = text

func update_check_button(state: bool) -> void:
	if not control is CheckButton:
		_update_type_mismatch_log("CheckButton")
		return
	
	control.button_pressed = state

func update_option_button(value: String, options: Array = []) -> void:
	if not control is OptionButton:
		_update_type_mismatch_log("OptionButton")
		return
	
	if not options.is_empty():
		control.clear()
		
		for i in options:
			control.add_item(i)
	
	var found := false
	for idx in control.item_count:
		if control.get_item_text(idx) == value:
			found = true
			control.select(idx)
			break
	
	if not found:
		_logger.error("Tried to select option {value} but it did not exist".format({
			value = value
		}))
		return

func update_color_picker_button(color: Color) -> void:
	if not control is ColorPickerButton:
		_update_type_mismatch_log("ColorPickerButton")
		return
	
	control.color = color
