extends MarginContainer

const CHECK_BOX_LABEL: Resource = preload("res://screens/gui/elements/CheckBoxLabel.tscn")

var model_bones: Dictionary = {}

###############################################################################
# Builtin functions                                                           #
###############################################################################

func _ready() -> void:
	connect("visibility_changed", self, "_on_visibility_changed")
	
	AppManager.connect("model_loaded", self, "_on_model_loaded")

###############################################################################
# Connections                                                                 #
###############################################################################

func _on_visibility_changed() -> void:
	match self.visible:
		true:
			pass
		false:
			pass

func _on_model_loaded() -> void:
	pass

###############################################################################
# Private functions                                                           #
###############################################################################

###############################################################################
# Public functions                                                            #
###############################################################################


