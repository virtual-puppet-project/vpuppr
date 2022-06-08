class_name LandingScreen
extends CanvasLayer

const ExtensionItem = preload("res://screens/landing_screen_extension_item.tscn")

onready var extensions: VBoxContainer = $RootControl/TabContainer/Extensions/ScrollContainer/ExtensionsList

#-----------------------------------------------------------------------------#
# Builtin functions                                                           #
#-----------------------------------------------------------------------------#

func _ready() -> void:
	while not AM.is_manager_ready("em"):
		yield(get_tree(), "idle_frame")

	for key in AM.em.extensions.keys():
		var extension_item := ExtensionItem.instance()
		extension_item.extension_data = AM.em.extensions[key].as_data()
		extensions.add_child(extension_item)

#-----------------------------------------------------------------------------#
# Connections                                                                 #
#-----------------------------------------------------------------------------#

#-----------------------------------------------------------------------------#
# Private functions                                                           #
#-----------------------------------------------------------------------------#

#-----------------------------------------------------------------------------#
# Public functions                                                            #
#-----------------------------------------------------------------------------#
