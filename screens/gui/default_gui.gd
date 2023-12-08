class_name DefaultGui
extends CanvasLayer

const Home := preload("res://screens/home/home.tscn")
const Licenses := preload("res://screens/gui/licenses.tscn")

const GITHUB_REPO := "https://github.com/virtual-puppet-project/vpuppr"
const DISCORD_URL := "https://discord.gg/6mcdWWBkrr"

const SPACER := &"__spacer__"
const MESSAGE_RECEIVED := &"message_received"

const AppMenu := {
	HOME = "Home",
	s0 = SPACER,
	LOGS = "Logs",
	SETTINGS = "Settings",
	s1 = SPACER,
	QUIT = "Quit"
}

const DebugMenu := {
	TERMINAL = "Terminal",
	s0 = SPACER,
	DEBUG_CHECKS = "Debug Checks"
}

const HelpMenu := {
	ABOUT = "About",
	s0 = SPACER,
	GITHUB = "GitHub",
	DISCORD = "Discord",
	s1 = SPACER,
	LICENSES = "Licenses"
}

var _logger := Logger.create("DefaultGui")

var context: Context = null

@onready
var _side_bar: VBoxContainer = %SideBar

# TODO you-win (nov 19 2023): restrict to 1 popup per type? or somehow update all popup
# windows of a specific type
var _active_popups: Array[PopupWindow] = []

#-----------------------------------------------------------------------------#
# Builtin functions
#-----------------------------------------------------------------------------#

func _ready() -> void:
	var app_menu := %App.get_popup() as PopupMenu
	for val in AppMenu.values():
		if val == SPACER:
			app_menu.add_separator()
		else:
			app_menu.add_item(val)
	app_menu.index_pressed.connect(func(idx: int) -> void:
		match app_menu.get_item_text(idx):
			AppMenu.HOME:
				get_tree().change_scene_to_packed(Home)
				return
			AppMenu.LOGS:
				_logger.error("Not yet implemented!")
				pass
			AppMenu.SETTINGS:
				_logger.error("Not yet implemented!")
				pass
			AppMenu.QUIT:
				get_tree().quit()
				return
	)
	
	var debug_menu := %Debug.get_popup() as PopupMenu
	for val in DebugMenu.values():
		match val:
			SPACER:
				debug_menu.add_separator()
			DebugMenu.DEBUG_CHECKS:
				debug_menu.add_check_item(val)
			_:
				debug_menu.add_item(val)
	debug_menu.index_pressed.connect(func(idx: int) -> void:
		match debug_menu.get_item_text(idx):
			DebugMenu.TERMINAL:
				_logger.error("Not yet implemented!")
				pass
			DebugMenu.DEBUG_CHECKS:
				var new_checked_state := not debug_menu.is_item_checked(idx)
				# TODO maybe move this logic elsewhere?
				debug_menu.set_item_checked(idx, new_checked_state)
				AM.debug_mode = new_checked_state
	)
	
	var help_menu := %Help.get_popup() as PopupMenu
	for val in HelpMenu.values():
		if val == SPACER:
			help_menu.add_separator()
		else:
			help_menu.add_item(val)
	help_menu.index_pressed.connect(func(idx: int) -> void:
		match help_menu.get_item_text(idx):
			HelpMenu.ABOUT:
				_logger.error("Not yet implemented!")
				pass
			HelpMenu.GITHUB:
				if OS.shell_open(GITHUB_REPO) != OK:
					_logger.error("Unable to open link to GitHub")
				return
			HelpMenu.DISCORD:
				if OS.shell_open(DISCORD_URL) != OK:
					_logger.error("Unable to open link to Discord")
				return
			HelpMenu.LICENSES:
				var popup := PopupWindow.new("Licenses", Licenses.instantiate())
				
				add_child(popup)
				popup.popup_centered_ratio(0.5)
				return
	)
	
	var h_split_container := $VBoxContainer/HSplitContainer
	h_split_container.split_offset = get_viewport().size.x * 0.15
	
	for child in _side_bar.get_children():
		if not child is Button:
			_logger.error("Side bar item {item_name} was not a button, skipping".format({
				item_name = child.name
			}))
			continue
		child.focus_mode = Control.FOCUS_NONE

func _input(event: InputEvent) -> void:
	if event is InputEventKey:
		if not event.pressed:
			return
		if event.keycode == KEY_ESCAPE:
			visible = not visible
	elif event is InputEventMouseMotion:
		pass

#-----------------------------------------------------------------------------#
# Private functions
#-----------------------------------------------------------------------------#

## Main message handler. May or may not request that popups update themselves.
func _handle_message_received(message: GUIMessage) -> void:
	if message == null:
		_logger.error("An error occurred while handling GUI message")
		return
	
	match message.action:
		GUIMessage.DATA_UPDATE:
			var data = context.runner_data.get_indexed(message.key)
			if data == null:
				_logger.error("Tried to update invalid key {key}".format({key = message.key}))
				return
			
			data.set_indexed(message.value.key, message.value.value)
			
			var split_key: PackedStringArray = message.key.split(":")
			
			match split_key[split_key.size() - 1]:
				&"puppet_data":
					context.model.update_from_config(context.runner_data.puppet_data)
				&"environment_options":
					context.runner.update_from_config()
				_:
					_logger.debug("Unhandled data update key for updating {key}".format({
						key = split_key[split_key.size() -1]
					}))
		GUIMessage.TRACKER_START:
			context.start_tracker(message.key)
			message.caller.update(context)
		GUIMessage.TRACKER_STOP:
			context.stop_tracker(message.key)
			message.caller.update(context)
		GUIMessage.TRACKER_STOP_ALL:
			pass
		GUIMessage.REQUEST_UPDATE:
			message.caller.update(context)
		GUIMessage.FLY_CAMERA:
			if not message.value is bool:
				_logger.error("Fly camera value should be a boolean")
				return
			
			context.runner.fly_camera(message.value)
		GUIMessage.CUSTOM:
			pass

#-----------------------------------------------------------------------------#
# Public functions
#-----------------------------------------------------------------------------#

## Add a button to the side bar that will display the contents stored at
## [param button_resource_path] in a popup window.
func add_side_bar_item(button_name: StringName, button_resource_path: StringName) -> Error:
	_logger.debug("Adding side bar item {0} for {1}".format([button_name, button_resource_path]))
	
	if not ResourceLoader.exists(button_resource_path):
		_logger.error("Resource does not exist for {0} at path {1}".format([
			button_name, button_resource_path]))
		return ERR_DOES_NOT_EXIST
	if _side_bar.has_node(NodePath(button_name)):
		_logger.error("Side bar item {0} already exists".format([button_name]))
		return ERR_ALREADY_EXISTS
	
	var button := Button.new()
	button.name = button_name
	button.text = button_name
	button.focus_mode = Control.FOCUS_NONE
	button.pressed.connect(add_popup.bind(String(button_name), String(button_resource_path)))
	
	_side_bar.add_child(button)
	
	return OK

## Add a popup to the scene.
func add_popup(popup_name: String, file_path: String) -> Error:
	for popup in _active_popups:
		if popup.name == popup_name:
			popup.move_to_foreground()
			return OK
	
	var resource: Resource = load(file_path)
	if resource == null:
		_logger.error("Unable to load resource at path {file_path}".format({file_path = file_path}))
		return ERR_FILE_NOT_FOUND
	
	# TODO add more checks
	var instance: Node = null
	if resource is PackedScene:
		instance = resource.instantiate()
	elif resource is GDScript:
		instance = resource.new()
	else:
		_logger.error("Unhandled resource type at {0}".format({file_path = file_path}))
		return ERR_FILE_UNRECOGNIZED
	
	if AM.debug_mode:
		if not instance.has_signal(MESSAGE_RECEIVED):
			_logger.error("Popup does not expose signal {signal_name}, bailing out".format({
				signal_name = MESSAGE_RECEIVED
			}))
			return ERR_UNCONFIGURED
		
		var update_method_found := false
		for method in instance.get_method_list():
			if method.get("name", "") != "update":
				continue
			
			var args: Array[Dictionary] = method.get("args", [])
			if args.size() != 1:
				_logger.error("Invalid update method for {gui_name}, must take exactly 1 argument of type Context".format({
					gui_name = instance.name
				}))
				return ERR_UNCONFIGURED
			
			update_method_found = true
		
		if not update_method_found:
			_logger.error("Update method not found for {gui_name}".format({
				gui_name = instance.name
			}))
			return ERR_UNCONFIGURED
	instance.message_received.connect(_handle_message_received)
	
	var popup := PopupWindow.new(popup_name, instance)
	popup.name = popup_name
	popup.close_requested.connect(func() -> void:
		_active_popups.erase(popup)
	)
	
	add_child(popup)
	# TODO configure size somehow?
	popup.popup_centered_ratio(0.5)
	
	instance.update(context)
	
	_active_popups.push_back(popup)
	
	return OK

## Close all popups that are currently open.
func close_popups() -> void:
	for popup in _active_popups:
		popup.queue_free()
	
	_active_popups.clear()

## Update the content in all popups that are currently open.
func update_popups() -> void:
	for popup in _active_popups:
		popup.gui.update(context)
