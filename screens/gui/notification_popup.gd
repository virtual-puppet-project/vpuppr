extends WindowDialog

# Choice is true/false
signal confirm_choice_selected(choice)

var text := ""
var is_confirmation := false

#-----------------------------------------------------------------------------#
# Builtin functions                                                           #
#-----------------------------------------------------------------------------#

func _ready() -> void:
	$VBoxContainer/Label.text = text
	
	var buttons: HBoxContainer = $VBoxContainer/Buttons
	if is_confirmation:
		var okay := Button.new()
		okay.text = tr("NOTIFICATION_POPUP_OKAY_BUTTON")
		okay.connect("pressed", self, "_on_okay_pressed")
		ControlUtil.h_expand_shrink_center(okay)
		buttons.add_child(okay)
		
		var cancel := Button.new()
		cancel.text = tr("NOTIFICATION_POPUP_CANCEL_BUTTON")
		cancel.connect("pressed", self, "_on_cancel_pressed")
		ControlUtil.h_expand_shrink_center(cancel)
		buttons.add_child(cancel)
		
		connect("hide", self, "_on_cancel_pressed")
	else:
		connect("hide", NodeUtil, "try_queue_free", [self])
		
		var close := Button.new()
		close.text = tr("NOTIFICATION_POPUP_CLOSE_BUTTON")
		close.connect("pressed", self, "_on_close_pressed")
		buttons.add_child(close)
	
	popup_centered()
	
	var new_size := Vector2.ZERO
	for c in get_children():
		if not c is Control:
			continue
		new_size += c.rect_size
	
	rect_size = new_size
	rect_min_size = new_size

#-----------------------------------------------------------------------------#
# Connections                                                                 #
#-----------------------------------------------------------------------------#

func _on_okay_pressed() -> void:
	emit_signal("confirm_choice_selected", true)
	_on_close_pressed()

func _on_cancel_pressed() -> void:
	emit_signal("confirm_choice_selected", false)
	_on_close_pressed()

func _on_close_pressed() -> void:
	queue_free()

#-----------------------------------------------------------------------------#
# Private functions                                                           #
#-----------------------------------------------------------------------------#

#-----------------------------------------------------------------------------#
# Public functions                                                            #
#-----------------------------------------------------------------------------#

func on_choice_selected(caller: Object, callback: String) -> void:
	is_confirmation = true
	connect("confirm_choice_selected", caller, callback)
