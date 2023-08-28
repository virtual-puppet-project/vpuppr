extends Node3D

var mf: MeowFace = null
var puppet: VrmPuppet = null

#-----------------------------------------------------------------------------#
# Builtin functions
#-----------------------------------------------------------------------------#

func _init() -> void:
	pass

func _ready() -> void:
	for child in get_children():
		if child is VrmPuppet:
			puppet = child
			break
	
	puppet.a_pose()
	
	mf = MeowFace.create({
		bind_port = 21412,
		connect_address = "192.168.88.51",
		connect_port = 21412,
		puppet = puppet
	})
	mf.data_received.connect(func(data: MeowFaceData) -> void:
		puppet.handle_meow_face(data)
	)
	if mf.start() != OK:
		printerr("asdf")

func _process(delta: float) -> void:
	pass

#-----------------------------------------------------------------------------#
# Private functions
#-----------------------------------------------------------------------------#

#-----------------------------------------------------------------------------#
# Public functions
#-----------------------------------------------------------------------------#

