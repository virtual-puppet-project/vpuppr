class_name VRMMappings
extends Reference

# enum EyeSide { NONE = 0, LEFT, RIGHT }

var dirty: bool = true

class VRMExpression:
	var expression_data: Dictionary = {} # String: Array[String]
	
	func create_mapping(mesh_name: String, morph_name: String) -> void:
		if not expression_data.has(mesh_name):
			expression_data[mesh_name] = []

		expression_data[mesh_name].append(morph_name)

# class EyeData:
# 	var bone_name: String
# 	var x_movement: Vector2
# 	var y_movement: Vector2

# 	func _init(p_bone_name: String, p_x_movement: Vector2, p_y_movement: Vector2) -> void:
# 		self.bone_name = p_bone_name
# 		self.x_movement = p_x_movement
# 		self.y_movement = p_y_movement

# Bone names
var head: String
var left_eye: String
var right_eye: String
# var left_eye: EyeData
# var right_eye: EyeData

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
