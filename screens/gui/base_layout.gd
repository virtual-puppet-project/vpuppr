class_name BaseLayout
extends Control

var logger: Logger

#-----------------------------------------------------------------------------#
# Builtin functions                                                           #
#-----------------------------------------------------------------------------#

## DO NOT OVERRIDE
func _ready() -> void:
	_setup_logger()
	
	var res: Result

	# This is gross but we do need to wait for the parent popup to finish setting up
	res = Safely.wrap(_pre_setup())
	if res.is_err():
		logger.error(res)
		return
	if res.unwrap() is GDScriptFunctionState:
		res = Safely.wrap(yield(res.unwrap(), "completed"))
	if res.is_err():
		logger.error(res)
		return

	res = Safely.wrap(_setup())
	if res.is_err():
		logger.error(res)
		return
	if res.unwrap() is GDScriptFunctionState:
		res = Safely.wrap(yield(res.unwrap(), "completed"))
	if res.is_err():
		logger.error(res)
		return
	
	res = Safely.wrap(_post_setup())
	if res.is_err():
		logger.error(res)
		return
	if res.unwrap() is GDScriptFunctionState:
		res = Safely.wrap(yield(res.unwrap(), "completed"))
	if res.is_err():
		logger.error(res)
		return

## DO NOT OVERRIDE
func _exit_tree() -> void:
	_teardown()

func _setup_logger() -> void:
	pass

func _pre_setup() -> Result:
	yield(get_tree(), "idle_frame")

	return Safely.ok()

func _setup() -> Result:
	yield(get_tree(), "idle_frame")

	return Safely.ok()

func _post_setup() -> Result:
	yield(get_tree(), "idle_frame")

	return Safely.ok()

func _teardown() -> void:
	pass

#-----------------------------------------------------------------------------#
# Connections                                                                 #
#-----------------------------------------------------------------------------#

#region UI element callbacks

func _on_button_pressed(signal_name: String, _button: Button) -> void:
	match signal_name:
		_:
			_log_unhandled_signal(signal_name)

func _on_check_button_toggled(state: bool, signal_name: String, _check_button: CheckButton) -> void:
	AM.ps.publish(signal_name, state)

func _on_line_edit_text_changed(text: String, signal_name: String, _line_edit: LineEdit) -> void:
	if text.empty():
		return
	
	match signal_name:
		_:
			_log_unhandled_signal(signal_name)

func _on_line_edit_text_entered(text: String, signal_name: String, line_edit: LineEdit) -> void:
	_on_line_edit_text_changed(text, signal_name, line_edit)

func _on_text_edit_text_changed(text: String, signal_name: String, _text_edit: TextEdit) -> void:
	if text.empty():
		return
	
	match signal_name:
		_:
			_log_unhandled_signal(signal_name)

func _on_color_picker_button_color_changed(color: Color, signal_name: String, _color_picker_button: ColorPickerButton) -> void:
	AM.ps.publish(signal_name, color)

func _on_config_updated(payload: SignalPayload, control: Control) -> void:
	match control.get_class():
		"Button":
			logger.debug("_on_config_updated for Button not yet implemented")
		"CheckButton":
			control.pressed = bool(payload.data)
		"LineEdit":
			if control.text.is_valid_float() and payload.data == control.text.to_float():
				return
			control.text = str(payload.data)
			control.caret_position = control.text.length()
		"ColorPickerButton":
			control.color = payload.data

#endregion

#-----------------------------------------------------------------------------#
# Private functions                                                           #
#-----------------------------------------------------------------------------#

#region Handle UI elements

## Converts a given string to snake case
static func _to_snake_case(text: String) -> String:
	var builder := PoolStringArray()

	for i in text.capitalize().split(" ", false):
		builder.append("%s%s" % [i[0].to_lower(), i.substr(1)])

	return builder.join("_")

## Generic method for connecting all types of Controls
##
## @param: control: Control - The Control to be connected
## @param: args: Variant - By default, is the signal name as a String
func _connect_element(control: Control, args = null) -> void:
	call("_connect_%s" % _to_snake_case(control.get_class()), control, args)

## Connects a Button to the default callback. Does not listen for config updates by default
##
## @param: button: Button - The Button to be connected
## @param: args: Variant - By default, is the signal name as a String
func _connect_button(button: Button, args = null) -> void:
	# TODO Most things don't use the button
	button.connect("pressed", self, "_on_button_pressed", [args, button])

## Connects a CheckButton to the default callback. Listens for config updates by default by
## subscribing to the given args parameter
##
## Also sets its initial value by pulling the args value from the ConfigManager
##
## @param: check_button: CheckButton - The CheckButton to be connected
## @param: args: Variant - By default, is the signal name as a String
func _connect_check_button(check_button: CheckButton, args = null) -> void:
	check_button.connect("toggled", self, "_on_check_button_toggled", [args, check_button])
	
	if AM.cm.has_data(args):
		check_button.set_pressed_no_signal(AM.cm.get_data(args))
		AM.ps.subscribe(self, args, {
			"args": [check_button],
			"callback": "_on_config_updated"
		})

## Connects a LineEdit to the default callback. Listens for config updates by default by
## subscribing to the given args parameter
##
## Also sets its initial value by pulling the args value from the ConfigManager
##
## @param: line_edit: LineEdit - The LineEdit to be connected
## @param: args: Variant - By default, is the signal name as a String
func _connect_line_edit(line_edit: LineEdit, args = null) -> void:
	line_edit.connect("text_changed", self, "_on_line_edit_text_changed", [args, line_edit])
	line_edit.connect("text_entered", self, "_on_line_edit_text_entered", [args, line_edit])
	
	if AM.cm.has_data(args):
		line_edit.text = str(AM.cm.get_data(args))
		AM.ps.subscribe(self, args, {
			"args": [line_edit],
			"callback": "_on_config_updated"
		})

## Connects a TextEdit to the default callback. Listens for config updates by default by
## subscribing to the given args parameter
##
## Also sets its initial value by pulling the args value from the ConfigManager
##
## @param: text_edit: TextEdit - The TextEdit to be connected
## @param: args: Variant - By default, is the signal name as a String
func _connect_text_edit(text_edit: TextEdit, args = null) -> void:
	text_edit.connect("text_changed", self, "_on_text_edit_text_changed", [args, text_edit])

	if AM.cm.has_data(args):
		text_edit.text = str(AM.cm.get_data(args))
		AM.ps.subscribe(self, args, {
			"args": [text_edit],
			"callback": "_on_config_updated"
		})

func _connect_color_picker_button(color_picker_button: ColorPickerButton, args = null) -> void:
	color_picker_button.connect("color_changed", self, "_on_color_picker_button_color_changed", [args, color_picker_button])
	
	if AM.cm.has_data(args):
		color_picker_button.color = AM.cm.get_data(args, Color(Globals.CHROMAKEY_GREEN_HEX))
		AM.ps.subscribe(self, args, {
			"args": [color_picker_button],
			"callback": "_on_config_updated"
		})

func _set_config_float_amount(signal_name: String, value: String) -> void:
	if not value.is_valid_float():
		return
	AM.ps.publish(signal_name, value.to_float())

#endregion

func _log_unhandled_signal(signal_name: String) -> void:
	logger.error("Unhandled signal %s for %s" % [signal_name, name])

#-----------------------------------------------------------------------------#
# Public functions                                                            #
#-----------------------------------------------------------------------------#
