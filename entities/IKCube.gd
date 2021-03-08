class_name IKCube
extends MeshInstance

onready var initial_transform: Transform = self.transform
var allow_transform: bool = false

###############################################################################
# Builtin functions                                                           #
###############################################################################

func _enter_tree() -> void:
	allow_transform = true

func _input(event: InputEvent) -> void:
	if event.is_action_pressed("toggle_gui"):
		self.visible = not self.visible

###############################################################################
# Connections                                                                 #
###############################################################################

###############################################################################
# Private functions                                                           #
###############################################################################

###############################################################################
# Public functions                                                            #
###############################################################################

func move_cube(translation: Vector3, rotation: Vector3) -> void:
	if allow_transform:
		var new_transform: Transform = initial_transform
		new_transform = new_transform.translated(translation)
		new_transform = new_transform.rotated(Vector3.RIGHT, rotation.x)
		new_transform = new_transform.rotated(Vector3.UP, rotation.y)
		new_transform = new_transform.rotated(Vector3.BACK, rotation.z)
		self.transform = new_transform
