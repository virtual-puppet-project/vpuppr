class_name VRMMappings
extends Reference

var dirty: bool = true

class VRMExpression:
	# Stores
	var expression_data: Dictionary = {} # String: Array[String]
	
	func create_mapping(mesh_name: String, morph_name: String) -> void:
		if not expression_data.has(mesh_name):
			expression_data[mesh_name] = []

		expression_data[mesh_name].append(morph_name)

	func get_meshes() -> Array:
		return expression_data.keys()

# Blend shapes
var a := VRMExpression.new()
var angry := VRMExpression.new()
var blink := VRMExpression.new()
var blink_l := VRMExpression.new()
var blink_r := VRMExpression.new()
var e := VRMExpression.new()
var fun := VRMExpression.new()
var i := VRMExpression.new()
var joy := VRMExpression.new()
# TODO look* unused and unmapped since we are tracking your eyes
var lookdown := VRMExpression.new()
var lookleft := VRMExpression.new()
var lookright := VRMExpression.new()
var lookup := VRMExpression.new()
var o := VRMExpression.new()
var sorrow := VRMExpression.new()
var u := VRMExpression.new()

# Perfect Sync Shapes
var BrowInnerUp := VRMExpression.new()
var BrowDownLeft := VRMExpression.new()
var BrowDownRight := VRMExpression.new()
var BrowOuterUpLeft := VRMExpression.new()
var BrowOuterUpRight := VRMExpression.new()
var EyeLookUpLeft := VRMExpression.new()
var EyeLookUpRight := VRMExpression.new()
var EyeLookDownLeft := VRMExpression.new()
var EyeLookDownRight := VRMExpression.new()
var EyeLookInLeft := VRMExpression.new()
var EyeLookInRight := VRMExpression.new()
var EyeLookOutLeft := VRMExpression.new()
var EyeLookOutRight := VRMExpression.new()
var EyeBlinkLeft := VRMExpression.new()
var EyeBlinkRight := VRMExpression.new()
var EyeSquintRight := VRMExpression.new()
var EyeSquintLeft := VRMExpression.new()
var EyeWideLeft := VRMExpression.new()
var EyeWideRight := VRMExpression.new()
var CheekPuff := VRMExpression.new()
var CheekSquintLeft := VRMExpression.new()
var CheekSquintRight := VRMExpression.new()
var NoseSneerLeft := VRMExpression.new()
var NoseSneerRight := VRMExpression.new()
var JawOpen := VRMExpression.new()
var JawForward := VRMExpression.new()
var JawLeft := VRMExpression.new()
var JawRight := VRMExpression.new()
var MouthFunnel := VRMExpression.new()
var MouthPucker := VRMExpression.new()
var MouthLeft := VRMExpression.new()
var MouthRight := VRMExpression.new()
var MouthRollUpper := VRMExpression.new()
var MouthRollLower := VRMExpression.new()
var MouthShrugUpper := VRMExpression.new()
var MouthShrugLower := VRMExpression.new()
var MouthClose := VRMExpression.new()
var MouthSmileLeft := VRMExpression.new()
var MouthSmileRight := VRMExpression.new()
var MouthFrownLeft := VRMExpression.new()
var MouthFrownRight := VRMExpression.new()
var MouthDimpleLeft := VRMExpression.new()
var MouthDimpleRight := VRMExpression.new()
var MouthUpperUpLeft := VRMExpression.new()
var MouthUpperUpRight := VRMExpression.new()
var MouthLowerDownLeft := VRMExpression.new()
var MouthLowerDownRight := VRMExpression.new()
var MouthPressLeft := VRMExpression.new()
var MouthPressRight := VRMExpression.new()
var MouthStretchLeft := VRMExpression.new()
var MouthStretchRight := VRMExpression.new()
var TongueOut := VRMExpression.new()

var meshes_used: Array = [] # String

###############################################################################
# Builtin functions                                                           #
###############################################################################

func _init() -> void:
	pass

###############################################################################
# Connections                                                                 #
###############################################################################

###############################################################################
# Private functions                                                           #
###############################################################################

###############################################################################
# Public functions                                                            #
###############################################################################

func create_expression_data(expression_name: String, mesh_name: String, morph_name: String) -> void:
	var expression: VRMExpression = self.get(expression_name)
	if expression:
		expression.create_mapping(mesh_name, morph_name)
		if not meshes_used.has(mesh_name):
			meshes_used.append(mesh_name)
	else:
		AppManager.log_message("Skipping unhandled expression name %s" % expression_name)

# func create_eye_data(eye_side: int, eye_name: String, x_data: Vector2, y_data: Vector2) -> void:
# 	match eye_side:
# 		EyeSide.LEFT:
# 			left_eye = EyeData.new(eye_name, x_data, y_data)
# 		EyeSide.RIGHT:
# 			right_eye = EyeData.new(eye_name, x_data, y_data)
# 		EyeSide.NONE:
# 			AppManager.log_message("Invalid EyeSide in %s" % self.name)
