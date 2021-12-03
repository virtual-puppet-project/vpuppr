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
		"lookup": VRM_MODEL.ExpressionData.new(),
		"lookdown": VRM_MODEL.ExpressionData.new(),
		"lookleft": VRM_MODEL.ExpressionData.new(),
		"lookright": VRM_MODEL.ExpressionData.new(),
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

	expression_data_dict["lookup"].morphs = [
		_create_morph_data('eye_L', []), 
	]
	expression_data_dict["lookdown"].morphs = [
		_create_morph_data('eye_L', [{"rotation": Quat(Vector3())}]), 
	]
	expression_data_dict["lookleft"].morphs = [
		_create_morph_data('eye_L', [{"rotation": Quat(Vector3(0.5, 0.5, 0.5))}]), 
	]
	expression_data_dict["lookright"].morphs = [
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
	
	expression_data_dict["lookup"].morphs = [
		_create_morph_data('eye_L', []), 
		_create_morph_data('eye_R', []),
	]
	expression_data_dict["lookdown"].morphs = [
		_create_morph_data('eye_L', [{"rotation": Quat(Vector3())}]), 
		_create_morph_data('eye_R', [{"rotation": Quat(Vector3())}]),
	]
	expression_data_dict["lookleft"].morphs = [
		_create_morph_data('eye_L', [{"rotation": Quat(Vector3(0.5, 0.5, 0.5))}]), 
		_create_morph_data('eye_R', [{"rotation": Quat(Vector3(0.5, 0.5, 0.5))}]),
	]
	expression_data_dict["lookright"].morphs = [
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
	
func test_map_bones() -> void:
	var vrm_model: VRM_MODEL = VRM_MODEL.new()
	vrm_model.vrm_meta = {
		"humanoid_bone_mapping": {
			"head" : "bone_19",
			"leftEye" : "bone_1",
			"rightEye": "bone_2",
			"neck": "bone_3",
			"spine": "bone_4",
			"leftShoulder": "bone_5",
			"rightShoulder": "bone_6",
			"leftUpperArm": "bone_7",
			"rightUpperArm": "bone_8",
		}
	}
	
	var skeleton = Skeleton.new()
	for i in 20:
		skeleton.add_bone("bone_%s" % i)
		
	vrm_model.skeleton = skeleton
	
	assert_eq(vrm_model.additional_bones_to_pose_names, [])
	
	assert_true(vrm_model.head_bone == "head")
	
	vrm_model._map_bones()
	
	assert_eq(vrm_model.head_bone, "bone_19")
	assert_eq(vrm_model.head_bone_id, 19)
	assert_eq(vrm_model.left_eye_id, 1)
	assert_eq(vrm_model.right_eye_id, 2)
	assert_eq(vrm_model.neck_bone_id, 3)
	assert_eq(vrm_model.spine_bone_id, 4)
	assert_eq(vrm_model.additional_bones_to_pose_names, ["bone_3", "bone_4"])
	
	assert_eq(skeleton.get_bone_pose(5), Transform(Quat(0, 0, 0.1, 0.85)))
	assert_eq(skeleton.get_bone_pose(6), Transform(Quat(0, 0, -0.1, 0.85)))
	assert_eq(skeleton.get_bone_pose(7), Transform(Quat(0, 0, 0.4, 0.85)))
	assert_eq(skeleton.get_bone_pose(8), Transform(Quat(0, 0, -0.4, 0.85)))

	# model with some bone_mapping missing
	vrm_model = VRM_MODEL.new()
	vrm_model.vrm_meta = {
		"humanoid_bone_mapping": {
			"rightEye": "bone_2",
			"neck": "bone_3",
			"leftShoulder": "bone_5",
			"leftUpperArm": "bone_7",
			"rightUpperArm": "bone_8",
		}
	}
	
	skeleton = Skeleton.new()
	for i in 20:
		skeleton.add_bone("bone_%s" % i)
		
	vrm_model.skeleton = skeleton
	
	assert_eq(vrm_model.additional_bones_to_pose_names, [])
	
	assert_true(vrm_model.head_bone == "head")
	
	vrm_model._map_bones()
	
	assert_eq(vrm_model.head_bone, "head")
	assert_eq(vrm_model.head_bone_id, null)
	assert_eq(vrm_model.left_eye_id, 0)
	assert_eq(vrm_model.right_eye_id, 2)
	assert_eq(vrm_model.neck_bone_id, 3)
	assert_eq(vrm_model.spine_bone_id, 0)
	assert_eq(vrm_model.additional_bones_to_pose_names, ["bone_3"])
	
	assert_eq(skeleton.get_bone_pose(5), Transform(Quat(0, 0, 0.1, 0.85)))
	assert_eq(skeleton.get_bone_pose(6), Transform())
	assert_eq(skeleton.get_bone_pose(7), Transform(Quat(0, 0, 0.4, 0.85)))
	assert_eq(skeleton.get_bone_pose(8), Transform(Quat(0, 0, -0.4, 0.85)))
