extends Control

var camera_element
var blend_shape_element

func setup() -> void:
    pass

func setup_cameras(element: Control) -> void:
    camera_element = element

    var popup_menu = element.menu_button.get_popup()
    if not popup_menu.is_connected("index_pressed", self, "_on_camera_pressed"):
        popup_menu.connect("index_pressed", self, "_on_camera_pressed")

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

# TODO this is bad
func _on_camera_pressed(idx: int) -> void:
    camera_element._handle_event([camera_element.event_name, camera_element.menu_button.get_popup().get_item_text(idx)[0]])

func setup_blend_shapes(element: Control) -> void:
    blend_shape_element = element

    var popup_menu = element.menu_button.get_popup()
    if not popup_menu.is_connected("index_pressed", self, "_on_blend_shape_pressed"):
        popup_menu.connect("index_pressed", self, "_on_blend_shape_pressed")

    if not element.parent.model is VRMModel:
        return

    for i in ["angry", "fun", "joy", "sorrow"]:
        popup_menu.add_item(i)

# TODO this is bad
func _on_blend_shape_pressed(idx: int) -> void:
    blend_shape_element._handle_event([blend_shape_element.event_name, blend_shape_element.menu_button.get_popup().get_item_text(idx)])
