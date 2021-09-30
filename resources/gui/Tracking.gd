extends Control

var camera_options: Array = []

func setup() -> void:
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
        camera_options.append_array((output[0] as String).split("\n"))
        camera_options.pop_back() # First output is 'Available cameras'
        camera_options.pop_front() # Last output is an empty string
    else:
        camera_options.append("Default camera")

# func 
