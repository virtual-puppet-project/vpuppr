extends HBoxContainer

const Actions: PackedScene = preload("res://screens/gui/actions/actions.tscn")

onready var register_hotkeys := $RegisterHotkeys
onready var register_action := $RegisterAction

var logger: Logger

var blend_shape_name := ""

#-----------------------------------------------------------------------------#
# Builtin functions                                                           #
#-----------------------------------------------------------------------------#

func _ready() -> void:
	register_hotkeys.connect("pressed", self, "_on_add_sequence")
	register_action.connect("pressed", self, "_on_add_action")

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

func _on_add_action() -> void:
	var actions: Node = Actions.instance()
	actions.managed_key = blend_shape_name
	
	var popup := BasePopup.new(actions, "Actions")
	add_child(popup)
	
	popup.popup_centered_ratio()

#-----------------------------------------------------------------------------#
# Private functions                                                           #
#-----------------------------------------------------------------------------#

#-----------------------------------------------------------------------------#
# Public functions                                                            #
#-----------------------------------------------------------------------------#
