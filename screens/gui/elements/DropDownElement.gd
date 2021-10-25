extends BaseElement

onready var menu_button: MenuButton = $VBoxContainer/PanelContainer/MenuButton

var popup_menu: PopupMenu

###############################################################################
# Builtin functions                                                           #
###############################################################################

func _ready() -> void:
	menu_button.text = label_text
	
	popup_menu = menu_button.get_popup()

	# popup_menu.connect("index_pressed", self, "_on_index_pressed")

###############################################################################
# Connections                                                                 #
###############################################################################

# TODO figure out how to do this better
# func _on_index_pressed(idx: int) -> void:
# 	_handle_event([event_name, popup_menu.get_item_text(idx)[0]])

###############################################################################
# Private functions                                                           #
###############################################################################

###############################################################################
# Public functions                                                            #
###############################################################################
