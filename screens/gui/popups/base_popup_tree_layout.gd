class_name BasePopupTreeLayout
extends Control

const TREE_COLUMN: int = 0

var logger: Logger

onready var tree = $Tree as Tree

var pages := {}

var current_page: Control
var _initial_page := ""

#-----------------------------------------------------------------------------#
# Builtin functions                                                           #
#-----------------------------------------------------------------------------#

func _ready() -> void:
	_setup()

func _setup() -> void:
	for child in get_children():
		if child == tree:
			continue
		pages[child.name] = child
		child.hide()
	
	tree.hide_root = true
	var root: TreeItem = tree.create_item()
	
	for page_name in pages.keys():
		var item: TreeItem = tree.create_item(root)
		item.set_text(TREE_COLUMN, page_name)
		
		if page_name == _initial_page:
			item.select(TREE_COLUMN)
			_toggle_page(page_name)
	
	tree.connect("item_selected", self, "_on_item_selected")

#-----------------------------------------------------------------------------#
# Connections                                                                 #
#-----------------------------------------------------------------------------#

func _on_item_selected() -> void:
	var page_name: String = tree.get_selected().get_text(tree.get_selected_column())
	
	_toggle_page(page_name)

#region UI element callbacks

func _on_button_pressed(_signal_name: String, _button: Button) -> void:
	logger.error("_on_pressed not yet implemented for %s" % name)

func _on_check_button_toggled(_state: bool, _signal_name: String, _check_button: CheckButton) -> void:
	logger.error("_on_toggled not yet implemented for %s" % name)

func _on_line_edit_text_changed(_text: String, _signal_name: String, _line_edit: LineEdit) -> void:
	logger.error("_on_text_changed not yet implemented for %s" % name)

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

func _toggle_page(page_name: String) -> void:
	if page_name.empty():
		return
	if current_page != null:
		current_page.hide()
	
	current_page = pages[page_name]
	current_page.show()

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
	
	var initial_value = AM.cm.get_data(args)
	if initial_value != null:
		check_button.set_pressed_no_signal(initial_value)
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

#-----------------------------------------------------------------------------#
# Public functions                                                            #
#-----------------------------------------------------------------------------#
