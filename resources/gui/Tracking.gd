extends Control

func setup() -> void:
    pass

func setup_cameras(element: Control) -> void:
    var popup_menu = element.menu_button.get_popup()

    var result: Array = []

    var output: Array = []
    match OS.get_name().to_lower():
        "windows":
            var exe_path: String = "%s%s" % [OS.get_executable_path().get_base_dir(), "/OpenSeeFaceFolder/OpenSeeFace/facetracker.exe"]
            if OS.is_debug_build():
                exe_path = "%s%s" % [ProjectSettings.globalize_path("res://export"), "/OpenSeeFaceFolder/OpenSeeFace/facetracker.exe"]
            OS.execute(exe_path, ["-l", "1"], true, output)
        "osx", "x11":
            pass

    if not output.empty():
        result.append_array((output[0] as String).split("\n"))
        result.pop_back() # First output is 'Available cameras'
        result.pop_front() # Last output is an empty string
    else:
        result.append("Default camera")

    for option in result:
        popup_menu.add_item(option)
