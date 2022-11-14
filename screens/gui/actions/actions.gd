extends VBoxContainer

signal confirmed(action)

# TODO translate these
const Types := {
	"DEFAULT": "DEFAULT_GUI_ACTIONS_POPUP_DEFAULT_ACTION_DROPDOWN_OPTION",
	"BOOMERANG": "DEFAULT_GUI_ACTIONS_POPUP_BOOMERANG_ACTION_DROPDOWN_OPTION",
	"LOCK": "DEFAULT_GUI_ACTIONS_POPUP_LOCK_ACTION_DROPDOWN_OPTION",
	"GOTO_AND_LOCK": "DEFAULT_GUI_ACTIONS_POPUP_GOTO_LOCK_ACTION_DROPDOWN_OPTION"
}

onready var default := $ScrollContainer/List/Default
onready var boomerang := $ScrollContainer/List/Boomerang
onready var lock := $ScrollContainer/List/Lock
onready var goto_lock := $ScrollContainer/List/GotoLock
var page_list := {}
onready var current_selection: Control = default

#-----------------------------------------------------------------------------#
# Builtin functions                                                           #
#-----------------------------------------------------------------------------#

func _ready() -> void:
	$ConfirmCancel/Confirm.connect("pressed", self, "_on_confirm")
	$ConfirmCancel/Cancel.connect("pressed", self, "_on_cancel")
	
	var types_button := $Types
	for v in Types.values():
		types_button.add_item(v)
	types_button.connect("item_selected", self, "_on_type_selected", [types_button])
	
	# TODO this is gross
	page_list[Types.DEFAULT] = $ScrollContainer/List/Default
	page_list[Types.BOOMERANG] = $ScrollContainer/List/Boomerang
	page_list[Types.BOOMERANG].action.type = Action.Type.BOOMERANG
	page_list[Types.LOCK] = $ScrollContainer/List/Lock
	page_list[Types.LOCK].action.type = Action.Type.LOCK
	page_list[Types.GOTO_AND_LOCK] = $ScrollContainer/List/GotoLock
	page_list[Types.GOTO_AND_LOCK].action.type = Action.Type.GOTO_LOCK
	
	_on_type_selected(0, types_button)

#-----------------------------------------------------------------------------#
# Connections                                                                 #
#-----------------------------------------------------------------------------#

func _on_confirm() -> void:
	emit_signal("confirmed", current_selection.get_action())
	_on_cancel()

func _on_cancel() -> void:
	get_parent().get_parent().queue_free()

func _on_type_selected(idx: int, option_button: OptionButton) -> void:
	for i in page_list.values():
		i.hide()
	current_selection = page_list[option_button.get_item_text(idx)]
	current_selection.show()

#-----------------------------------------------------------------------------#
# Private functions                                                           #
#-----------------------------------------------------------------------------#

#-----------------------------------------------------------------------------#
# Public functions                                                            #
#-----------------------------------------------------------------------------#
