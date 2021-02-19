extends Node

enum ModelType { GENERIC, VRM }

signal file_to_load_changed(file_path, file_type)
#warning-ignore:unused_signal
signal model_loaded(model_reference)
#warning-ignore:unused_signal
signal properties_applied(property_data)

var is_face_tracker_running: bool
var face_tracker_pid: int

###############################################################################
# Builtin functions                                                           #
###############################################################################

func _ready() -> void:
	self.connect("tree_exiting", self, "_on_tree_exiting")

###############################################################################
# Connections                                                                 #
###############################################################################

func _on_tree_exiting() -> void:
	if is_face_tracker_running:
		OS.kill(face_tracker_pid)

###############################################################################
# Private functions                                                           #
###############################################################################

###############################################################################
# Public functions                                                            #
###############################################################################

func set_file_to_load(file_path: String, file_type: int) -> void:
	emit_signal("file_to_load_changed", file_path, file_type)
