extends Node3D

var mf: MeowFace = null
var puppet: Puppet3d = null

#-----------------------------------------------------------------------------#
# Builtin functions
#-----------------------------------------------------------------------------#

func _init() -> void:
	pass

func _ready() -> void:
	for child in get_children():
		if child is Puppet3d:
			puppet = child
			break
	
	mf = MeowFace.create({
		bind_port = 21412,
		connect_address = "192.168.88.51",
		connect_port = 21412,
		puppet = puppet
	})
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

