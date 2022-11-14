extends HBoxContainer

const Actions: PackedScene = preload("res://screens/gui/actions/actions.tscn")

onready var register_hotkeys := $RegisterHotkeys
onready var register_action := $RegisterAction

var logger: Logger

var blend_shape_name := ""

# TODO pull this from config
var action := Action.new()

#-----------------------------------------------------------------------------#
# Builtin functions                                                           #
#-----------------------------------------------------------------------------#

func _ready() -> void:
	register_hotkeys.connect("pressed", self, "_on_add_sequence")
	register_action.connect("pressed", self, "_on_add_action")
	
	action.name = blend_shape_name
	action.pub_sub_key = Globals.HOTKEY_ACTION_RECEIVED

#-----------------------------------------------------------------------------#
# Connections                                                                 #
#-----------------------------------------------------------------------------#

func _on_add_sequence() -> void:
	var res: Result = AM.hp.get_hotkey_input_popup()
	if res.is_err():
		logger.error("Unable to get hotkey input popup")
		return
	
	var popup: WindowDialog = res.unwrap()
	popup.connect("popup_hide", NodeUtil, "try_queue_free", [popup])
	popup.connect("dialog_complete", self, "_on_dialog_complete")
	
	add_child(popup)
	popup.popup_centered_ratio()

func _on_dialog_complete(data: Array) -> void:
	register_hotkeys.text = str(data)
	action.hotkeys.append_array(data)
	
	_try_update_config()

func _on_add_action() -> void:
	var actions: Node = Actions.instance()
	
	var popup := BasePopup.new(actions, "Actions")
	add_child(popup)
	
	popup.popup_centered_ratio()
	
	actions.connect("confirmed", self, "_on_actions_changed")

func _on_actions_changed(new_action: Action) -> void:
	new_action.hotkeys = action.hotkeys
	action = new_action

	# TODO move this to a global?
	match action.type:
		Action.Type.NONE:
			register_action.text = "DEFAULT_GUI_ACTIONS_POPUP_DEFAULT_ACTION_DROPDOWN_OPTION"
		Action.Type.BOOMERANG:
			register_action.text = "DEFAULT_GUI_ACTIONS_POPUP_BOOMERANG_ACTION_DROPDOWN_OPTION"
		Action.Type.LOCK:
			register_action.text = "DEFAULT_GUI_ACTIONS_POPUP_LOCK_ACTION_DROPDOWN_OPTION"
		Action.Type.GOTO_LOCK:
			register_action.text = "DEFAULT_GUI_ACTIONS_POPUP_GOTO_LOCK_ACTION_DROPDOWN_OPTION"
	
	_try_update_config()

#-----------------------------------------------------------------------------#
# Private functions                                                           #
#-----------------------------------------------------------------------------#

func _try_update_config() -> void:
	if not action.is_complete():
		return

	AM.ps.publish("blend_shape_actions", action, blend_shape_name)

#-----------------------------------------------------------------------------#
# Public functions                                                            #
#-----------------------------------------------------------------------------#
