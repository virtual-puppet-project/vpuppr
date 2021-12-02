extends CanvasLayer

onready var popup: AcceptDialog = $AcceptDialog

var popup_text: String

###############################################################################
# Builtin functions                                                           #
###############################################################################

func _ready() -> void:
	popup.dialog_text = popup_text
	var label: Label = popup.get_label()
	label.align = Label.ALIGN_CENTER
	label.valign = Label.VALIGN_CENTER
	popup.popup_centered_ratio(0.7)
	popup.connect("confirmed", self, "_on_close")
	popup.connect("popup_hide", self, "_on_close")

###############################################################################
# Connections                                                                 #
###############################################################################

func _on_close() -> void:
	queue_free()

###############################################################################
# Private functions                                                           #
###############################################################################

###############################################################################
# Public functions                                                            #
###############################################################################
