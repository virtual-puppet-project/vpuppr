extends VBoxContainer

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

var automation: Automation

var managed_key := ""
var managed_value

#-----------------------------------------------------------------------------#
# Builtin functions                                                           #
#-----------------------------------------------------------------------------#

func _ready() -> void:
	var types_button := $Types
	for v in Types.values():
		types_button.add_item(v)
	types_button.connect("item_selected", self, "_on_type_selected", [types_button])
	
	page_list[Types.DEFAULT] = $ScrollContainer/List/Default
	page_list[Types.BOOMERANG] = $ScrollContainer/List/Boomerang
	page_list[Types.LOCK] = $ScrollContainer/List/Lock
	page_list[Types.GOTO_AND_LOCK] = $ScrollContainer/List/GotoLock
	
	_on_type_selected(0, types_button)

#-----------------------------------------------------------------------------#
# Connections                                                                 #
#-----------------------------------------------------------------------------#

func _on_type_selected(idx: int, option_button: OptionButton) -> void:
	for i in page_list.values():
		i.hide()
	page_list[option_button.get_item_text(idx)].show()

#-----------------------------------------------------------------------------#
# Private functions                                                           #
#-----------------------------------------------------------------------------#

#-----------------------------------------------------------------------------#
# Public functions                                                            #
#-----------------------------------------------------------------------------#
