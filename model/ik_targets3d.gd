class_name IKTargets3D
extends Resource

## Initial Inverse Kinematic (IK) transforms in 3D.

## The [Transform3D] used for the head IK target.
@export
var head := Transform3D.IDENTITY
## The [Transform3D] used for the left hand IK target.
@export
var left_hand := Transform3D.IDENTITY
## The [Transform3D] used for the right hand IK target.
@export
var right_hand := Transform3D.IDENTITY
## The [Transform3D] used for the hips IK target.
@export
var hips := Transform3D.IDENTITY
## The [Transform3D] used for the left foot IK target.
@export
var left_foot := Transform3D.IDENTITY
## The [Transform3D] used for the right foot IK target.
@export
var right_foot := Transform3D.IDENTITY

#-----------------------------------------------------------------------------#
# Builtin functions
#-----------------------------------------------------------------------------#

#-----------------------------------------------------------------------------#
# Private functions
#-----------------------------------------------------------------------------#

#-----------------------------------------------------------------------------#
# Public functions
#-----------------------------------------------------------------------------#
