class_name BaseLayout
extends Control

var logger: Logger

#-----------------------------------------------------------------------------#
# Builtin functions                                                           #
#-----------------------------------------------------------------------------#

## DO NOT OVERRIDE
func _ready() -> void:
	_setup_logger()
	
	var ret

	ret = _pre_setup()
	if ret is GDScriptFunctionState:
		ret = yield(ret, "completed")
	if ret == null or ret.is_err():
		logger.error(ret.to_string() if ret != null else "Something is super wrong")
		return

	ret = _setup()
	if ret is GDScriptFunctionState:
		ret = yield(ret, "completed")
	if ret == null or ret.is_err():
		logger.error(ret.to_string() if ret != null else "Something is super wrong")
		return
	
	ret = _post_setup()
	if ret is GDScriptFunctionState:
		ret = yield(ret, "completed")
	if ret == null or ret.is_err():
		logger.error(ret.to_string() if ret != null else "Something is super wrong")
		return

func _setup_logger() -> void:
	pass

func _pre_setup() -> Result:
	yield(get_tree(), "idle_frame")

	return Result.ok()

func _setup() -> Result:
	yield(get_tree(), "idle_frame")

	return Result.ok()

func _post_setup() -> Result:
	yield(get_tree(), "idle_frame")

	return Result.ok()

#-----------------------------------------------------------------------------#
# Connections                                                                 #
#-----------------------------------------------------------------------------#

#region UI element callbacks

func _on_button_pressed(signal_name: String, _button: Button) -> void:
	match signal_name:
		_:
			_log_unhandled_signal(signal_name)

func _on_check_button_toggled(state: bool, signal_name: String, _check_button: CheckButton) -> void:
	# AM.ps.emit_signal(signal_name, state)
	AM.ps.publish(signal_name, state)

func _on_line_edit_text_changed(text: String, signal_name: String, _line_edit: LineEdit) -> void:
	if text.empty():
		return
	
	match signal_name:
		_:
			_log_unhandled_signal(signal_name)

func _on_line_edit_text_entered(text: String, signal_name: String, line_edit: LineEdit) -> void:
	_on_line_edit_text_changed(text, signal_name, line_edit)

func _on_config_updated(value, control: Control) -> void:
	match control.get_class():
		"Button":
			logger.debug("_on_config_updated for Button not yet implemented")
		"CheckButton":
			control.pressed = bool(value)
		"LineEdit":
			if control.text.is_valid_float() and value == control.text.to_float():
				return
			control.text = str(value)
			control.caret_position = control.text.length()

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

func _set_config_float_amount(signal_name: String, value: String) -> void:
	if not value.is_valid_float():
		return
	AM.ps.emit_signal(signal_name, value.to_float())

#endregion

func _log_unhandled_signal(signal_name: String) -> void:
	logger.error("Unhandled signal %s for %s" % [signal_name, name])

#-----------------------------------------------------------------------------#
# Public functions                                                            #
#-----------------------------------------------------------------------------#
