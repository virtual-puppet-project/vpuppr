extends "res://tests/base_test.gd"

const VRM_MODEL: Resource = preload("res://entities/vrm/VRMModel.gd")

###############################################################################
# Builtin functions                                                           #
###############################################################################

func _ready() -> void:
	pass

###############################################################################
# Utils                                                                       #
###############################################################################
func _create_morph_data(name, values):
	var md = VRM_MODEL.MorphData.new()
	md.morph = name
	md.values = values
	return md

###############################################################################
# Tests                                                                       #
###############################################################################

func test_map_eye_expressions() -> void:
	var vrm_model: VRM_MODEL = VRM_MODEL.new()
	vrm_model.vrm_meta = { "humanoid_bone_mapping": { "leftEye" : "eye_L", "rightEye": "eye_R" } }
	
	assert_true(vrm_model.left_eye == null)
	assert_true(vrm_model.right_eye == null)
	
	var expression_data_dict: Dictionary
	expression_data_dict = {
		"LOOKUP": VRM_MODEL.ExpressionData.new(),
		"LOOKDOWN": VRM_MODEL.ExpressionData.new(),
		"LOOKLEFT": VRM_MODEL.ExpressionData.new(),
		"LOOKRIGHT": VRM_MODEL.ExpressionData.new(),
	}
	
	vrm_model._map_eye_expressions(expression_data_dict)
	assert_eq(vrm_model.left_eye.up, Vector3(360, 0, 0))
	assert_eq(vrm_model.left_eye.down, Vector3(-360, 0, 0))
	assert_eq(vrm_model.left_eye.left, Vector3(0, 360, 0))
	assert_eq(vrm_model.left_eye.right, Vector3(0, -360, 0))
	assert_eq(vrm_model.right_eye.up, Vector3(360, 0, 0))
	assert_eq(vrm_model.right_eye.down, Vector3(-360, 0, 0))
	assert_eq(vrm_model.right_eye.left, Vector3(0, 360, 0))
	assert_eq(vrm_model.right_eye.right, Vector3(0, -360, 0))

	expression_data_dict["LOOKUP"].morphs = [
		_create_morph_data('eye_L', []), 
	]
	expression_data_dict["LOOKDOWN"].morphs = [
		_create_morph_data('eye_L', [{"rotation": Quat(Vector3())}]), 
	]
	expression_data_dict["LOOKLEFT"].morphs = [
		_create_morph_data('eye_L', [{"rotation": Quat(Vector3(0.5, 0.5, 0.5))}]), 
	]
	expression_data_dict["LOOKRIGHT"].morphs = [
		_create_morph_data('eye_L', [{"rotation": Quat(Vector3(0.5, 0.5, 0.5))}]), 
	]
	vrm_model._map_eye_expressions(expression_data_dict)
	assert_eq(vrm_model.left_eye.up, Vector3(360, 0, 0))
	assert_eq(vrm_model.left_eye.down, Vector3(-360, 0, 0))
	assert_eq(vrm_model.left_eye.left, Vector3(0.5, 0.5, 0.5))
	assert_eq(vrm_model.left_eye.right, Vector3(0.5, 0.5, 0.5))
	assert_eq(vrm_model.right_eye.up, Vector3(360, 0, 0))
	assert_eq(vrm_model.right_eye.down, Vector3(-360, 0, 0))
	assert_eq(vrm_model.right_eye.left, Vector3(0, 360, 0))
	assert_eq(vrm_model.right_eye.right, Vector3(0, -360, 0))
	
	expression_data_dict["LOOKUP"].morphs = [
		_create_morph_data('eye_L', []), 
		_create_morph_data('eye_R', []),
	]
	expression_data_dict["LOOKDOWN"].morphs = [
		_create_morph_data('eye_L', [{"rotation": Quat(Vector3())}]), 
		_create_morph_data('eye_R', [{"rotation": Quat(Vector3())}]),
	]
	expression_data_dict["LOOKLEFT"].morphs = [
		_create_morph_data('eye_L', [{"rotation": Quat(Vector3(0.5, 0.5, 0.5))}]), 
		_create_morph_data('eye_R', [{"rotation": Quat(Vector3(0.5, 0.5, 0.5))}]),
	]
	expression_data_dict["LOOKRIGHT"].morphs = [
		_create_morph_data('eye_L', [{"rotation": Quat(Vector3(0.5, 0.5, 0.5))}]), 
		_create_morph_data('eye_R', [{"rotation": Quat(Vector3(0.5, 0.5, 0.5))}]),
	]
	vrm_model._map_eye_expressions(expression_data_dict)
	assert_eq(vrm_model.left_eye.up, Vector3(360, 0, 0))
	assert_eq(vrm_model.left_eye.down, Vector3(-360, 0, 0))
	assert_eq(vrm_model.left_eye.left, Vector3(0.5, 0.5, 0.5))
	assert_eq(vrm_model.left_eye.right, Vector3(0.5, 0.5, 0.5))
	assert_eq(vrm_model.right_eye.up, Vector3(360, 0, 0))
	assert_eq(vrm_model.right_eye.down, Vector3(-360, 0, 0))
	assert_eq(vrm_model.right_eye.left, Vector3(0.5, 0.5, 0.5))
	assert_eq(vrm_model.right_eye.right, Vector3(0.5, 0.5, 0.5))
	
