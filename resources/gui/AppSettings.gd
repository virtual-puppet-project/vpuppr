extends Control

const MAX_LOGS: int = 26

var console: VBoxContainer

func setup_console(element: Control) -> void:
    if console:
        return
    
    console = VBoxContainer.new()
    element.vbox.add_child(console)

    AppManager.connect("console_log", self, "_on_console_log")

func _on_console_log(message: String) -> void:
    var label := Label.new()
    label.text = message

    console.add_child(label)

    console.move_child(label, 0)

    if console.get_child_count() > MAX_LOGS:
        console.get_child(MAX_LOGS).free()
