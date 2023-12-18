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

var _logger := Logger.create("SettingsOption:{n}".format({n = name}))

## Value used for stepping if a child control supports stepping.
@export
var step: float = 1.0
## The index path to use when modifying a [RunnerData].
@export
var config_path := &""
@export
## The key used for updating settings. Will be automatically generated from the node name or
## child [Label] if not set.
var key := &""

## The parent of this node. This is used for message callbacks.
var _parent: Node = null
## The control managed by this node.
var control: Control = null

#-----------------------------------------------------------------------------#
# Builtin functions
#-----------------------------------------------------------------------------#

func _init(p_name: String = "", control: Control = null) -> void:
	if p_name.is_empty() or control == null:
		return
	
	name = p_name
	_logger.set_name("SettingsOption:{n}".format({n = name}))
	
	_create_implicit_name_label()
	add_child(control)

func _ready() -> void:
	_parent = get_parent()
	if _parent == null:
		_logger.error("No parent found")
		return
	if config_path.is_empty():
		_logger.error("config_path must be set")
		return
	
	match get_child_count():
		0:
			_logger.error("At least 1 child node must be specified")
			return
		1:
			if get_child(0) is Label:
				_logger.error("Must have at least 1 child node that isn't a Label")
				return
			_create_implicit_name_label()
		_:
			if not get_child(0) is Label:
				_create_implicit_name_label()
	
	# Safe since we verify the amount of children before this
	key = get_child(0).text.to_snake_case()
	
	control = get_child(1)
	if get_child(1).is_queued_for_deletion():
		_logger.error("Second child is queued for deletion, bailing out")
		return
	
	if control.has_signal(message_received.get_name()):
		control.message_received.connect(func(message: GUIMessage) -> void:
			message_received.emit(message)
		)
	else:
		match get_child_count():
			2:
				_setup_single()
			3:
				_setup_double()
			4:
				_setup_triple()
			_:
				_logger.error("Unhandled setup child count {n}".format({n = get_child_count()}))
				return
	
	size_flags_horizontal = Control.SIZE_EXPAND_FILL
	for child in get_children():
		child.size_flags_horizontal = Control.SIZE_EXPAND_FILL

#-----------------------------------------------------------------------------#
# Private functions
#-----------------------------------------------------------------------------#

func _create_implicit_name_label() -> void:
	_logger.debug("Creating label using node name")
	
	var label := Label.new()
	label.text = name.capitalize()
	
	add_child(label)
	move_child(label, 0)

func _create_payload(key: String, value: Variant) -> Dictionary:
	return {
		key = key,
		value = value
	}

## Setup a single control node managed by the [SettingsOption].
func _setup_single() -> Error:
	if get_child_count() != 2:
		_logger.error("Expected exactly 2 children, got {n}".format({n = get_child_count()}))
		return ERR_UNCONFIGURED
	
	var control: Control = get_child(1)
	match control.get_class():
		"LineEdit":
			_setup_text_field(control)
		"CheckButton":
			_setup_toggle_button(control)
		"OptionButton":
			_setup_drop_down(control)
		"ColorPickerButton":
			_setup_color_picker_button(control)
		_:
			_logger.error("Unhandled setup class {clazz}".format({clazz = control.get_class()}))
			return ERR_UNCONFIGURED
	
	return OK

## A [LineEdit] by itself is interpreted to be a [String] field.
func _setup_text_field(line_edit: LineEdit) -> void:
	var text_received := func(text: String) -> void:
		message_received.emit(GUIMessage.new(
			_parent, GUIMessage.DATA_UPDATE, config_path, _create_payload(key, text)))
	
	line_edit.text_changed.connect(text_received)
	line_edit.text_submitted.connect(text_received)

## A [CheckButton] is a togglable field.
func _setup_toggle_button(check_button: CheckButton) -> void:
	check_button.toggled.connect(func(state: bool) -> void:
		message_received.emit(GUIMessage.new(
			_parent, GUIMessage.DATA_UPDATE, config_path, _create_payload(key, state)))
	)

## An [OptionButton] is a drop-down field.
func _setup_drop_down(option_button: OptionButton) -> void:
	option_button.item_selected.connect(func(idx: int) -> void:
		var text := option_button.get_item_text(idx)
		
		message_received.emit(GUIMessage.new(
			_parent, GUIMessage.DATA_UPDATE, config_path, _create_payload(key, text)))
	)

## A [ColorPickerButton] that hides a [ColorPicker].
func _setup_color_picker_button(color_picker_button: ColorPickerButton) -> void:
	color_picker_button.get_picker().color_changed.connect(func(color: Color) -> void:
		message_received.emit(GUIMessage.new(
			_parent, GUIMessage.DATA_UPDATE, config_path, _create_payload(key, color)))
	)

## Setup two control nodes managed by the [SettingsOption].
func _setup_double() -> Error:
	if get_child_count() != 3:
		_logger.error("Expected exactly 3 children, got {n}".format({n = get_child_count()}))
		return ERR_UNCONFIGURED
	
	var control_1: Control = get_child(1)
	var control_2: Control = get_child(2)
	
	match [control_1.get_class(), control_2.get_class()]:
		["LineEdit", "HSlider"]: # Bounded number field
			_setup_bounded_number_field(control_1, control_2)
		_:
			_logger.error(
				"Unhandled setup classes {clazz_1} and {clazz_2}".format({
					clazz_1 = control_1.get_class(),
					clazz_2 = control_2.get_class()
				})
			)
			return ERR_UNCONFIGURED
	
	return OK

## A [LineEdit] and [HSlider] that represent a bounded-number value.
func _setup_bounded_number_field(line_edit: LineEdit, h_slider: HSlider) -> void:
	var text_received := func(text: String) -> void:
		if not text.is_valid_float():
			return
		
		message_received.emit(GUIMessage.new(
			_parent, GUIMessage.DATA_UPDATE, config_path, _create_payload(
				key, text.to_float())))
	
	line_edit.text_changed.connect(text_received)
	line_edit.text_submitted.connect(text_received)
	
	h_slider.drag_ended.connect(func(changed: bool) -> void:
		if not changed:
			return
		
		var string_value := str(h_slider.value)
		line_edit.text = string_value
		text_received.call(string_value)
	)
	
	remove_child(line_edit)
	remove_child(h_slider)
	
	var vbox := VBoxContainer.new()
	vbox.size_flags_horizontal = Control.SIZE_EXPAND_FILL
	vbox.add_child(line_edit)
	vbox.add_child(h_slider)
	
	add_child(vbox)

## Setup three control nodes managed by the [SettingsOption].
func _setup_triple() -> Error:
	if get_child_count() != 4:
		_logger.error("Expected exactly 4 children, got {n}".format({n = get_child_count()}))
		return ERR_UNCONFIGURED
	
	var control_1: Control = get_child(1)
	var control_2: Control = get_child(2)
	var control_3: Control = get_child(3)
	
	match [control_1.get_class(), control_2.get_class(), control_3.get_class()]:
		["Button", "LineEdit", "Button"]: # Unbounded number field
			_setup_unbounded_number_field(control_1, control_2, control_3)
		_:
			_logger.error(
				"Unhandled setup classes {clazz_1}, {clazz_2}, and {clazz_3}".format({
					clazz_1 = control_1.get_class(),
					clazz_2 = control_2.get_class(),
					clazz_3 = control_3.get_class()
				})
			)
			return ERR_UNCONFIGURED
	
	return OK

## A [Button], [LineEdit], and [Button] that represent an unbounded number. Numbers are stepped
## according to [member step].
func _setup_unbounded_number_field(dec_button: Button, line_edit: LineEdit, inc_button: Button) -> void:
	var text_received := func(text: String) -> void:
		if not text.is_valid_float():
			return
		
		message_received.emit(GUIMessage.new(
			_parent, GUIMessage.DATA_UPDATE, config_path, _create_payload(
				key, text.to_float())))
	
	line_edit.text_changed.connect(text_received)
	line_edit.text_submitted.connect(text_received)
	line_edit.size_flags_horizontal = Control.SIZE_EXPAND_FILL
	
	# TODO you-win (dec 3, 2023) add ability to drag mouse on line edit to set value
	
	var button_pressed := func(val: float) -> void:
		if not line_edit.text.is_valid_float():
			line_edit.text = "0"
		
		var string_value = str(float(line_edit.text) + val)
		line_edit.text = string_value
		text_received.call(string_value)
	
	dec_button.pressed.connect(button_pressed.bind(-step))
	inc_button.pressed.connect(button_pressed.bind(step))
	
	remove_child(dec_button)
	remove_child(line_edit)
	remove_child(inc_button)
	
	var hbox := HBoxContainer.new()
	hbox.size_flags_horizontal = Control.SIZE_EXPAND_FILL
	hbox.add_child(dec_button)
	hbox.add_child(line_edit)
	hbox.add_child(inc_button)
	
	add_child(hbox)

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
