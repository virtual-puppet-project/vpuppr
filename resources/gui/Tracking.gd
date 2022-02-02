extends Control

func setup() -> void:
	pass

# Camera select

var camera_element

func setup_cameras(element: Control) -> void:
	if camera_element:
		return
	
	camera_element = element

	var popup_menu = element.menu_button.get_popup()
	if not popup_menu.is_connected("index_pressed", self, "_on_camera_pressed"):
		popup_menu.connect("index_pressed", self, "_on_camera_pressed")

	var os_name := OS.get_name().to_lower()

	var result: Array = []

	var output: Array = []
	match os_name:
		"windows":
			var exe_path: String = "%s%s" % [OS.get_executable_path().get_base_dir(), "/OpenSeeFaceFolder/OpenSeeFace/facetracker.exe"]
			if OS.is_debug_build():
				exe_path = "%s%s" % [ProjectSettings.globalize_path("res://export"), "/OpenSeeFaceFolder/OpenSeeFace/facetracker.exe"]
			OS.execute(exe_path, ["-l", "1"], true, output)
		"osx", "x11":
			var exe_path := "%s%s" % [OS.get_executable_path().get_base_dir(), "/resources/scripts/get_video_devices.sh"]
			if OS.is_debug_build():
				exe_path = "%s%s" % [ProjectSettings.globalize_path("res://export"), "/resources/scripts/get_video_devices.sh"]
			OS.execute(exe_path, [], true, output)

	if not output.empty():
		result.append_array((output[0] as String).split("\n"))
		match os_name:
			"windows":
				result.pop_back() # Last output is an empty string
				result.pop_front() # First output is 'Available cameras'
			"osx", "x11":
				result.pop_back() # Last output is an empty string
	else:
		result.append("Unable to list cameras")
		popup_menu.disconnect("index_pressed", self, "_on_camera_pressed")

	for option in result:
		popup_menu.add_item(option)

# TODO this is bad
func _on_camera_pressed(idx: int) -> void:
	match OS.get_name().to_lower():
		"windows":
			camera_element._handle_event([camera_element.event_name, camera_element.menu_button.get_popup().get_item_text(idx)[0]])
		"osx", "x11":
			camera_element._handle_event([camera_element.event_name, "/dev/%s" % camera_element.menu_button.get_popup().get_item_text(idx)])

# Blend shapes

var blend_shape_element

func setup_blend_shapes(element: Control) -> void:
	blend_shape_element = element

	var popup_menu = element.menu_button.get_popup()
	if not popup_menu.is_connected("index_pressed", self, "_on_blend_shape_pressed"):
		popup_menu.connect("index_pressed", self, "_on_blend_shape_pressed")

	if not element.parent.model is VRMModel:
		return

	popup_menu.clear()

	yield(get_tree(), "idle_frame")

	for i in element.parent.model.all_expressions.keys():
		var expression_name: String = i.to_lower()
		if expression_name in ["firstperson", "thirdperson", "lookup", "lookdown", "lookleft", "lookright"]:
			continue
		popup_menu.add_item(expression_name)

# TODO this is bad
func _on_blend_shape_pressed(idx: int) -> void:
	blend_shape_element._handle_event([blend_shape_element.event_name, blend_shape_element.menu_button.get_popup().get_item_text(idx)])

func python_path(element: Control) -> void:
	if OS.get_name().to_lower() == "windows":
		element.hide()
