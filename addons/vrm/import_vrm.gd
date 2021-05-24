class_name ImportVRM
extends Reference

enum DebugMode {
	None = 0,
	Normal = 1,
	LitShadeRate = 2,
}

enum OutlineColorMode {
	FixedColor = 0,
	MixedLighting = 1,
}

enum OutlineWidthMode {
	None = 0,
	WorldCoordinates = 1,
	ScreenCoordinates = 2,
}

enum RenderMode {
	Opaque = 0,
	Cutout = 1,
	Transparent = 2,
	TransparentWithZWrite = 3,
}

enum CullMode {
	Off = 0,
	Front = 1,
	Back = 2,
}

enum FirstPersonFlag {
	Auto, # Create headlessModel
	Both, # Default layer
	ThirdPersonOnly,
	FirstPersonOnly,
}
const FirstPersonParser: Dictionary = {
	"Auto": FirstPersonFlag.Auto,
	"Both": FirstPersonFlag.Both,
	"FirstPersonOnly": FirstPersonFlag.FirstPersonOnly,
	"ThirdPersonOnly": FirstPersonFlag.ThirdPersonOnly,
}

const USE_COMPAT_SHADER = false

var vrm_mappings: VRMMappings = VRMMappings.new()


func _get_extensions():
	return ["vrm"]


#func _get_import_flags():
#	return EditorSceneImporter.IMPORT_SCENE


func _import_animation(path: String, flags: int, bake_fps: int) -> Animation:
	return Animation.new()


func _process_khr_material(orig_mat: SpatialMaterial, gltf_mat_props: Dictionary) -> Material:
	# VRM spec requires support for the KHR_materials_unlit extension.
	if gltf_mat_props.has("extensions"):
		# TODO: Implement this extension upstream.
		if gltf_mat_props["extensions"].has("KHR_materials_unlit"):
			# TODO: validate that this is sufficient.
			orig_mat.flags_unshaded = true
	return orig_mat


func _vrm_get_texture_info(gltf_images: Array, vrm_mat_props: Dictionary, unity_tex_name: String):
	var texture_info: Dictionary = {}
	texture_info["tex"] = null
	texture_info["offset"] = Vector3(0.0, 0.0, 0.0)
	texture_info["scale"] = Vector3(1.0, 1.0, 1.0)
	if vrm_mat_props["textureProperties"].has(unity_tex_name):
		var mainTexId: int = vrm_mat_props["textureProperties"][unity_tex_name]
		var mainTexImage: ImageTexture = gltf_images[mainTexId]
		texture_info["tex"] = mainTexImage
	if vrm_mat_props["vectorProperties"].has(unity_tex_name):
		var offsetScale: Array = vrm_mat_props["vectorProperties"][unity_tex_name]
		texture_info["offset"] = Vector3(offsetScale[0], offsetScale[1], 0.0)
		texture_info["scale"] = Vector3(offsetScale[2], offsetScale[3], 1.0)
	return texture_info


func _vrm_get_float(vrm_mat_props: Dictionary, key: String, def: float) -> float:
	return vrm_mat_props["floatProperties"].get(key, def)

 
func _process_vrm_material(orig_mat: SpatialMaterial, gltf_images: Array, vrm_mat_props: Dictionary) -> Material:
	var vrm_shader_name:String = vrm_mat_props["shader"]
	if vrm_shader_name == "VRM_USE_GLTFSHADER":
		return orig_mat # It's already correct!
	
	if (vrm_shader_name == "Standard" or
		vrm_shader_name == "UniGLTF/UniUnlit" or
		vrm_shader_name == "VRM/UnlitTexture" or
		vrm_shader_name == "VRM/UnlitCutout" or
		vrm_shader_name == "VRM/UnlitTransparent"):
		printerr("Unsupported legacy VRM shader " + vrm_shader_name + " on material " + orig_mat.resource_name)
		return orig_mat

	var maintex_info: Dictionary = _vrm_get_texture_info(gltf_images, vrm_mat_props, "_MainTex")

	if vrm_shader_name == "VRM/UnlitTransparentZWrite":
		if maintex_info["tex"] != null:
			orig_mat.albedo_texture = maintex_info["tex"]
			orig_mat.uv1_offset = maintex_info["offset"]
			orig_mat.uv1_scale = maintex_info["scale"]
		orig_mat.flags_unshaded = true
		orig_mat.params_depth_draw_mode = SpatialMaterial.DEPTH_DRAW_ALWAYS
		orig_mat.flags_no_depth_test = false
		orig_mat.params_blend_mode = SpatialMaterial.BLEND_MODE_MIX
		return orig_mat

	if vrm_shader_name != "VRM/MToon":
		printerr("Unknown VRM shader " + vrm_shader_name + " on material " + orig_mat.resource_name)
		return orig_mat


	# Enum(Off,0,Front,1,Back,2) _CullMode

	var outline_width_mode = int(vrm_mat_props["floatProperties"].get("_OutlineWidthMode", 0))
	var blend_mode = int(vrm_mat_props["floatProperties"].get("_BlendMode", 0))
	var cull_mode = int(vrm_mat_props["floatProperties"].get("_CullMode", 2))
	var outl_cull_mode = int(vrm_mat_props["floatProperties"].get("_OutlineCullMode", 1))
	if cull_mode == CullMode.Front || (outl_cull_mode != CullMode.Front && outline_width_mode != OutlineWidthMode.None):
		printerr("VRM Material " + orig_mat.resource_name + " has unsupported front-face culling mode: " +
			str(cull_mode) + "/" + str(outl_cull_mode))
	if outline_width_mode == OutlineWidthMode.ScreenCoordinates:
		printerr("VRM Material " + orig_mat.resource_name + " uses screenspace outlines.")


	var mtooncompat_shader_base_path = "res://addons/MToonCompat/mtooncompat"
	var mtoon_shader_base_path = "res://addons/Godot-MToon-Shader/mtoon"
	if USE_COMPAT_SHADER:
		mtoon_shader_base_path = mtooncompat_shader_base_path

	var godot_outline_shader_name = null
	if outline_width_mode != OutlineWidthMode.None:
		godot_outline_shader_name = mtoon_shader_base_path + "_outline"

	var godot_shader_name = mtoon_shader_base_path
	if blend_mode == RenderMode.Opaque or blend_mode == RenderMode.Cutout:
		# NOTE: Cutout is not separately implemented due to code duplication.
		if cull_mode == CullMode.Off:
			godot_shader_name = mtoon_shader_base_path + "_cull_off"
	elif blend_mode == RenderMode.Transparent:
		godot_shader_name = mtoon_shader_base_path + "_trans"
		if cull_mode == CullMode.Off:
			godot_shader_name = mtoon_shader_base_path + "_trans_cull_off"
	elif blend_mode == RenderMode.TransparentWithZWrite:
		godot_shader_name = mtoon_shader_base_path + "_trans_zwrite"
		if cull_mode == CullMode.Off:
			godot_shader_name = mtoon_shader_base_path + "_trans_zwrite_cull_off"

	var godot_shader: Shader = ResourceLoader.load(godot_shader_name + ".shader")
	var godot_shader_outline: Shader = null
	if godot_outline_shader_name:
		godot_shader_outline = ResourceLoader.load(godot_outline_shader_name + ".shader")

	var new_mat = ShaderMaterial.new()
	new_mat.resource_name = orig_mat.resource_name
	new_mat.shader = godot_shader
	if maintex_info.get("tex", null) != null:
		new_mat.set_shader_param("_MainTex", maintex_info["tex"])

	new_mat.set_shader_param("_MainTex_ST", Plane(
		maintex_info["scale"].x, maintex_info["scale"].y,
		maintex_info["offset"].x, maintex_info["offset"].y))

	for param_name in ["_MainTex", "_ShadeTexture", "_BumpMap", "_RimTexture", "_SphereAdd", "_EmissionMap", "_OutlineWidthTexture", "_UvAnimMaskTexture"]:
		var tex_info: Dictionary = _vrm_get_texture_info(gltf_images, vrm_mat_props, param_name)
		if tex_info.get("tex", null) != null:
			new_mat.set_shader_param(param_name, tex_info["tex"])

	for param_name in vrm_mat_props["floatProperties"]:
		new_mat.set_shader_param(param_name, vrm_mat_props["floatProperties"][param_name])
		
	for param_name in ["_Color", "_ShadeColor", "_RimColor", "_EmissionColor", "_OutlineColor"]:
		if param_name in vrm_mat_props["vectorProperties"]:
			var param_val = vrm_mat_props["vectorProperties"][param_name]
			#### TODO: Use Color
			### But we want to keep 4.0 compat which does not gamma correct color.
			var color_param: Plane = Plane(param_val[0], param_val[1], param_val[2], param_val[3])
			new_mat.set_shader_param(param_name, color_param)

	# FIXME: setting _Cutoff to disable cutoff is a bit unusual.
	if blend_mode == RenderMode.Cutout:
		new_mat.set_shader_param("_EnableAlphaCutout", 1.0)
	
	if godot_shader_outline != null:
		var outline_mat = new_mat.duplicate()
		outline_mat.shader = godot_shader_outline
		
		new_mat.next_pass = outline_mat
		
	# TODO: render queue -> new_mat.render_priority

	return new_mat


func _update_materials(vrm_extension: Dictionary, gstate: GLTFState):
	var images = gstate.get_images()
	#print(images)
	var materials : Array = gstate.get_materials();
	var spatial_to_shader_mat : Dictionary = {}
	for i in range(materials.size()):
		var oldmat: Material = materials[i]
		if (oldmat is ShaderMaterial):
			print("Material " + str(i) + ": " + oldmat.resource_name + " already is shader.")
			continue
		var newmat: Material = _process_khr_material(oldmat, gstate.json["materials"][i])
		newmat = _process_vrm_material(newmat, images, vrm_extension["materialProperties"][i])
		spatial_to_shader_mat[oldmat] = newmat
		spatial_to_shader_mat[newmat] = newmat
		#print("Replacing shader " + str(oldmat) + "/" + oldmat.resource_name + " with " + str(newmat) + "/" + newmat.resource_name)
		materials[i] = newmat
		var oldpath = oldmat.resource_path
		oldmat.resource_path = ""
		newmat.take_over_path(oldpath)
		ResourceSaver.save(oldpath, newmat)
	gstate.set_materials(materials)

	var meshes = gstate.get_meshes()
	for i in range(meshes.size()):
		var gltfmesh: GLTFMesh = meshes[i]
		var mesh: ArrayMesh = gltfmesh.mesh
		mesh.blend_shape_mode = ArrayMesh.BLEND_SHAPE_MODE_NORMALIZED
		for surf_idx in range(mesh.get_surface_count()):
			var surfmat = mesh.surface_get_material(surf_idx)
			if spatial_to_shader_mat.has(surfmat):
				mesh.surface_set_material(surf_idx, spatial_to_shader_mat[surfmat])
			else:
				printerr("Mesh " + str(i) + " material " + str(surf_idx) + " name " + surfmat.resource_name + " has no replacement material.")


func _get_skel_godot_node(gstate: GLTFState, nodes: Array, skeletons: Array, skel_id: int) -> Node:
	# There's no working direct way to convert from skeleton_id to node_id.
	# Bugs:
	# GLTFNode.parent is -1 if skeleton bone.
	# skeleton_to_node is empty
	# get_scene_node(skeleton bone) works though might maybe return an attachment.
	# var skel_node_idx = nodes[gltfskel.roots[0]]
	# return gstate.get_scene_node(skel_node_idx) # as Skeleton
	for i in range(nodes.size()):
		if nodes[i].skeleton == skel_id:
			return gstate.get_scene_node(i)
	return null

class SkelBone:
	var skel: Skeleton
	var bone_name: String
	

# https://github.com/vrm-c/vrm-specification/blob/master/specification/0.0/schema/vrm.humanoid.bone.schema.json
# vrm_extension["humanoid"]["bone"]:
#"enum": ["hips","leftUpperLeg","rightUpperLeg","leftLowerLeg","rightLowerLeg","leftFoot","rightFoot",
# "spine","chest","neck","head","leftShoulder","rightShoulder","leftUpperArm","rightUpperArm",
# "leftLowerArm","rightLowerArm","leftHand","rightHand","leftToes","rightToes","leftEye","rightEye","jaw",
# "leftThumbProximal","leftThumbIntermediate","leftThumbDistal",
# "leftIndexProximal","leftIndexIntermediate","leftIndexDistal",
# "leftMiddleProximal","leftMiddleIntermediate","leftMiddleDistal",
# "leftRingProximal","leftRingIntermediate","leftRingDistal",
# "leftLittleProximal","leftLittleIntermediate","leftLittleDistal",
# "rightThumbProximal","rightThumbIntermediate","rightThumbDistal",
# "rightIndexProximal","rightIndexIntermediate","rightIndexDistal",
# "rightMiddleProximal","rightMiddleIntermediate","rightMiddleDistal",
# "rightRingProximal","rightRingIntermediate","rightRingDistal",
# "rightLittleProximal","rightLittleIntermediate","rightLittleDistal", "upperChest"]


func _create_meta(root_node: Node, animplayer: AnimationPlayer, vrm_extension: Dictionary, gstate: GLTFState, human_bone_to_idx: Dictionary) -> Resource:
	var nodes = gstate.get_nodes()
	var skeletons = gstate.get_skeletons()
	var hipsNode: GLTFNode = nodes[human_bone_to_idx["hips"]]
	var skeleton: Skeleton = _get_skel_godot_node(gstate, nodes, skeletons, hipsNode.skeleton)
	var skeletonPath: NodePath = root_node.get_path_to(skeleton)
	root_node.set("vrm_skeleton", skeletonPath)

	var animPath: NodePath = root_node.get_path_to(animplayer)
	root_node.set("vrm_animplayer", animPath)

	var firstperson = vrm_extension.get("firstPerson", null)
	var eyeOffset: Vector3;

	if firstperson:
		# FIXME: Technically this is supposed to be offset relative to the "firstPersonBone"
		# However, firstPersonBone defaults to Head...
		# and the semantics of a VR player having their viewpoint out of something which does
		# not rotate with their head is unclear.
		# Additionally, the spec schema says this:
		# "It is assumed that an offset from the head bone to the VR headset is added."
		# Which implies that the Head bone is used, not the firstPersonBone.
		var fpboneoffsetxyz = firstperson["firstPersonBoneOffset"] # example: 0,0.06,0
		eyeOffset = Vector3(fpboneoffsetxyz["x"], fpboneoffsetxyz["y"], fpboneoffsetxyz["z"])

	var gltfnodes: Array = gstate.nodes

	var humanBoneDictionary: Dictionary = {}
	for humanBoneName in human_bone_to_idx:
		humanBoneDictionary[humanBoneName] = gltfnodes[human_bone_to_idx[humanBoneName]].resource_name

	var vrm_meta: Resource = load("res://addons/vrm/vrm_meta.gd").new()

	vrm_meta.resource_name = "CLICK TO SEE METADATA"
	vrm_meta.exporter_version = vrm_extension.get("exporterVersion", "")
	vrm_meta.spec_version = vrm_extension.get("specVersion", "")
	var vrm_extension_meta = vrm_extension.get("meta")
	if vrm_extension_meta:
		vrm_meta.title = vrm_extension["meta"].get("title", "")
		vrm_meta.version = vrm_extension["meta"].get("version", "")
		vrm_meta.author = vrm_extension["meta"].get("author", "")
		vrm_meta.contact_information = vrm_extension["meta"].get("contactInformation", "")
		vrm_meta.reference_information = vrm_extension["meta"].get("reference", "")
		var tex: int = vrm_extension["meta"].get("texture", -1)
		if tex >= 0:
			var gltftex: GLTFTexture = gstate.get_textures()[tex]
			vrm_meta.texture = gstate.get_images()[gltftex.src_image]
		vrm_meta.allowed_user_name = vrm_extension["meta"].get("allowedUserName", "")
		vrm_meta.violent_usage = vrm_extension["meta"].get("violentUssageName", "") # Ussage (sic.) in VRM spec
		vrm_meta.sexual_usage = vrm_extension["meta"].get("sexualUssageName", "") # Ussage (sic.) in VRM spec
		vrm_meta.commercial_usage = vrm_extension["meta"].get("commercialUssageName", "") # Ussage (sic.) in VRM spec
		vrm_meta.other_permission_url = vrm_extension["meta"].get("otherPermissionUrl", "")
		vrm_meta.license_name = vrm_extension["meta"].get("licenseName", "")
		vrm_meta.other_license_url = vrm_extension["meta"].get("otherLicenseUrl", "")

	vrm_meta.eye_offset = eyeOffset
	vrm_meta.humanoid_bone_mapping = humanBoneDictionary
	return vrm_meta.duplicate(true)


func _create_animation_player(animplayer: AnimationPlayer, vrm_extension: Dictionary, gstate: GLTFState, human_bone_to_idx: Dictionary) -> AnimationPlayer:
	# Remove all glTF animation players for safety.
	# VRM does not support animation import in this way.
	for i in range(gstate.get_animation_players_count(0)):
		var node: AnimationPlayer = gstate.get_animation_player(i)
		node.get_parent().remove_child(node)

	var meshes = gstate.get_meshes()
	var nodes = gstate.get_nodes()
	var blend_shape_groups = vrm_extension["blendShapeMaster"]["blendShapeGroups"]
	# FIXME: Do we need to handle multiple references to the same mesh???
	var mesh_idx_to_meshinstance : Dictionary = {}
	var material_name_to_mesh_and_surface_idx: Dictionary = {}
	for i in range(meshes.size()):
		var gltfmesh : GLTFMesh = meshes[i]
		for j in range(gltfmesh.mesh.get_surface_count()):
			material_name_to_mesh_and_surface_idx[gltfmesh.mesh.surface_get_material(j).resource_name] = [i, j]
			
	for i in range(nodes.size()):
		var gltfnode: GLTFNode = nodes[i]
		var mesh_idx: int = gltfnode.mesh
		#print("node idx " + str(i) + " node name " + gltfnode.resource_name + " mesh idx " + str(mesh_idx))
		if (mesh_idx != -1):
			var scenenode: MeshInstance = gstate.get_scene_node(i)
			mesh_idx_to_meshinstance[mesh_idx] = scenenode
			#print("insert " + str(mesh_idx) + " node name " + scenenode.name)

	for shape in blend_shape_groups:
		#print("Blend shape group: " + shape["name"])
		var anim = Animation.new()
		
		for matbind in shape["materialValues"]:
			var mesh_and_surface_idx = material_name_to_mesh_and_surface_idx[matbind["materialName"]]
			var node: MeshInstance = mesh_idx_to_meshinstance[mesh_and_surface_idx[0]]
			var surface_idx = mesh_and_surface_idx[1]

			var mat: Material = node.get_surface_material(surface_idx)
			var paramprop = "shader_param/" + matbind["parameterName"]
			var origvalue = null
			var tv = matbind["targetValue"]
			var newvalue = tv[0]
				
			if (mat is ShaderMaterial):
				var smat: ShaderMaterial = mat
				var param = smat.get_shader_param(matbind["parameterName"])
				if param is Color:
					origvalue = param
					newvalue = Color(tv[0], tv[1], tv[2], tv[3])
				elif matbind["parameterName"] == "_MainTex" or matbind["parameterName"] == "_MainTex_ST":
					origvalue = param
					newvalue = Plane(tv[2], tv[3], tv[0], tv[1]) if matbind["parameterName"] == "_MainTex" else Plane(tv[0], tv[1], tv[2], tv[3])
				elif param is float:
					origvalue = param
					newvalue = tv[0]
				else:
					printerr("Unknown type for parameter " + matbind["parameterName"] + " surface " + node.name + "/" + str(surface_idx))

			if origvalue != null:
				var animtrack: int = anim.add_track(Animation.TYPE_VALUE)
				anim.track_set_path(animtrack, str(animplayer.get_parent().get_path_to(node)) + ":mesh:surface_" + str(surface_idx) + "/material:" + paramprop)
				anim.track_set_interpolation_type(animtrack, Animation.INTERPOLATION_NEAREST if bool(shape["isBinary"]) else Animation.INTERPOLATION_LINEAR)
				anim.track_insert_key(animtrack, 0.0, origvalue)
				anim.track_insert_key(animtrack, 0.0, newvalue)
		for bind in shape["binds"]:
			# FIXME: Is this a mesh_idx or a node_idx???
			var node: MeshInstance = mesh_idx_to_meshinstance[int(bind["mesh"])]
			var nodeMesh: ArrayMesh = node.mesh;
			
			if (bind["index"] < 0 || bind["index"] >= nodeMesh.get_blend_shape_count()):
				printerr("Invalid blend shape index in bind " + str(shape) + " for mesh " + node.name)
				continue
			var animtrack: int = anim.add_track(Animation.TYPE_VALUE)
			# nodeMesh.set_blend_shape_name(int(bind["index"]), shape["name"] + "_" + str(bind["index"]))
			anim.track_set_path(animtrack, str(animplayer.get_parent().get_path_to(node)) + ":blend_shapes/" + nodeMesh.get_blend_shape_name(int(bind["index"])))
			var interpolation: int = Animation.INTERPOLATION_LINEAR
			if shape.has("isBinary") and bool(shape["isBinary"]):
				interpolation = Animation.INTERPOLATION_NEAREST
			anim.track_set_interpolation_type(animtrack, interpolation)
			anim.track_insert_key(animtrack, 0.0, float(0.0))
			# FIXME: Godot has weird normal/tangent singularities at weight=1.0 or weight=0.5
			# So we multiply by 0.99999 to produce roughly the same output, avoiding these singularities.
			anim.track_insert_key(animtrack, 1.0, 0.99999 * float(bind["weight"]) / 100.0)
			#var mesh:ArrayMesh = meshes[bind["mesh"]].mesh
			#print("Mesh name: " + mesh.resource_name)
			#print("Bind index: " + str(bind["index"]))
			#print("Bind weight: " + str(float(bind["weight"]) / 100.0))

			vrm_mappings.create_expression_data(
				shape["presetName"].to_lower(),
				mesh_idx_to_meshinstance[int(bind["mesh"])].name,
				nodeMesh.get_blend_shape_name(int(bind["index"]))
			)

		# https://github.com/vrm-c/vrm-specification/tree/master/specification/0.0#blendshape-name-identifier
		animplayer.add_animation(shape["name"].to_upper() if shape["presetName"] == "unknown" else shape["presetName"].to_upper(), anim)

	var firstperson = vrm_extension["firstPerson"]
	
	var firstpersanim: Animation = Animation.new()
	animplayer.add_animation("FirstPerson", firstpersanim)

	var thirdpersanim: Animation = Animation.new()
	animplayer.add_animation("ThirdPerson", thirdpersanim)

	var skeletons:Array = gstate.get_skeletons()

	var head_bone_idx = firstperson.get("firstPersonBone", -1)
	if (head_bone_idx >= 0):
		var headNode: GLTFNode = nodes[head_bone_idx]
		var skeletonPath:NodePath = animplayer.get_parent().get_path_to(_get_skel_godot_node(gstate, nodes, skeletons, headNode.skeleton))
		var headBone: String = headNode.resource_name

		vrm_mappings.head = headBone

		var firstperstrack = firstpersanim.add_track(Animation.TYPE_METHOD)
		firstpersanim.track_set_path(firstperstrack, ".")
		firstpersanim.track_insert_key(firstperstrack, 0.0, {"method": "TODO_scale_bone", "args": [skeletonPath, headBone, 0.0]})
		var thirdperstrack = thirdpersanim.add_track(Animation.TYPE_METHOD)
		thirdpersanim.track_set_path(thirdperstrack, ".")
		thirdpersanim.track_insert_key(thirdperstrack, 0.0, {"method": "TODO_scale_bone", "args": [skeletonPath, headBone, 1.0]})

	for meshannotation in firstperson["meshAnnotations"]:

		var flag = FirstPersonParser.get(meshannotation["firstPersonFlag"], -1)
		var first_person_visibility;
		var third_person_visibility;
		if flag == FirstPersonFlag.ThirdPersonOnly:
			first_person_visibility = 0.0
			third_person_visibility = 1.0
		elif flag == FirstPersonFlag.FirstPersonOnly:
			first_person_visibility = 1.0
			third_person_visibility = 0.0
		else:
			continue
		var node: MeshInstance = mesh_idx_to_meshinstance[int(meshannotation["mesh"])]
		var firstperstrack = firstpersanim.add_track(Animation.TYPE_VALUE)
		firstpersanim.track_set_path(firstperstrack, str(animplayer.get_parent().get_path_to(node)) + ":visible")
		firstpersanim.track_insert_key(firstperstrack, 0.0, first_person_visibility)
		var thirdperstrack = thirdpersanim.add_track(Animation.TYPE_VALUE)
		thirdpersanim.track_set_path(thirdperstrack, str(animplayer.get_parent().get_path_to(node)) + ":visible")
		thirdpersanim.track_insert_key(thirdperstrack, 0.0, third_person_visibility)

	if firstperson.get("lookAtTypeName", "") == "Bone":
		var horizout = firstperson["lookAtHorizontalOuter"]
		var horizin = firstperson["lookAtHorizontalInner"]
		var vertup = firstperson["lookAtVerticalUp"]
		var vertdown = firstperson["lookAtVerticalDown"]
		var leftEyeNode: GLTFNode = nodes[human_bone_to_idx["leftEye"]]
		var skeleton:Skeleton = _get_skel_godot_node(gstate, nodes, skeletons,leftEyeNode.skeleton)
		var skeletonPath:NodePath = animplayer.get_parent().get_path_to(skeleton)
		var leftEyePath:String = str(skeletonPath) + ":" + nodes[human_bone_to_idx["leftEye"]].resource_name
		var rightEyeNode: GLTFNode = nodes[human_bone_to_idx["rightEye"]]
		skeleton = _get_skel_godot_node(gstate, nodes, skeletons,rightEyeNode.skeleton)
		skeletonPath = animplayer.get_parent().get_path_to(skeleton)
		var rightEyePath:String = str(skeletonPath) + ":" + nodes[human_bone_to_idx["rightEye"]].resource_name

		vrm_mappings.left_eye = nodes[human_bone_to_idx["leftEye"]].resource_name
		vrm_mappings.right_eye = nodes[human_bone_to_idx["rightEye"]].resource_name

		var anim = animplayer.get_animation("LOOKLEFT")
		if anim:
			var animtrack = anim.add_track(Animation.TYPE_TRANSFORM)
			anim.track_set_path(animtrack, leftEyePath)
			anim.track_set_interpolation_type(animtrack, Animation.INTERPOLATION_LINEAR)
			anim.transform_track_insert_key(animtrack, 0.0, Vector3.ZERO, Quat.IDENTITY, Vector3.ONE)
			anim.transform_track_insert_key(animtrack, horizout["xRange"] / 90.0, Vector3.ZERO, Basis(Vector3(0,1,0), horizout["yRange"] * 3.14159/180.0).get_rotation_quat(), Vector3.ONE)
			animtrack = anim.add_track(Animation.TYPE_TRANSFORM)
			anim.track_set_path(animtrack, rightEyePath)
			anim.track_set_interpolation_type(animtrack, Animation.INTERPOLATION_LINEAR)
			anim.transform_track_insert_key(animtrack, 0.0, Vector3.ZERO, Quat.IDENTITY, Vector3.ONE)
			anim.transform_track_insert_key(animtrack, horizin["xRange"] / 90.0, Vector3.ZERO, Basis(Vector3(0,1,0), horizin["yRange"] * 3.14159/180.0).get_rotation_quat(), Vector3.ONE)

		anim = animplayer.get_animation("LOOKRIGHT")
		if anim:
			var animtrack = anim.add_track(Animation.TYPE_TRANSFORM)
			anim.track_set_path(animtrack, leftEyePath)
			anim.track_set_interpolation_type(animtrack, Animation.INTERPOLATION_LINEAR)
			anim.transform_track_insert_key(animtrack, 0.0, Vector3.ZERO, Quat.IDENTITY, Vector3.ONE)
			anim.transform_track_insert_key(animtrack, horizin["xRange"] / 90.0, Vector3.ZERO, Basis(Vector3(0,1,0), -horizin["yRange"] * 3.14159/180.0).get_rotation_quat(), Vector3.ONE)
			animtrack = anim.add_track(Animation.TYPE_TRANSFORM)
			anim.track_set_path(animtrack, rightEyePath)
			anim.track_set_interpolation_type(animtrack, Animation.INTERPOLATION_LINEAR)
			anim.transform_track_insert_key(animtrack, 0.0, Vector3.ZERO, Quat.IDENTITY, Vector3.ONE)
			anim.transform_track_insert_key(animtrack, horizout["xRange"] / 90.0, Vector3.ZERO, Basis(Vector3(0,1,0), -horizout["yRange"] * 3.14159/180.0).get_rotation_quat(), Vector3.ONE)

		anim = animplayer.get_animation("LOOKUP")
		if anim:
			var animtrack = anim.add_track(Animation.TYPE_TRANSFORM)
			anim.track_set_path(animtrack, leftEyePath)
			anim.track_set_interpolation_type(animtrack, Animation.INTERPOLATION_LINEAR)
			anim.transform_track_insert_key(animtrack, 0.0, Vector3.ZERO, Quat.IDENTITY, Vector3.ONE)
			anim.transform_track_insert_key(animtrack, vertup["xRange"] / 90.0, Vector3.ZERO, Basis(Vector3(1,0,0), vertup["yRange"] * 3.14159/180.0).get_rotation_quat(), Vector3.ONE)
			animtrack = anim.add_track(Animation.TYPE_TRANSFORM)
			anim.track_set_path(animtrack, rightEyePath)
			anim.track_set_interpolation_type(animtrack, Animation.INTERPOLATION_LINEAR)
			anim.transform_track_insert_key(animtrack, 0.0, Vector3.ZERO, Quat.IDENTITY, Vector3.ONE)
			anim.transform_track_insert_key(animtrack, vertup["xRange"] / 90.0, Vector3.ZERO, Basis(Vector3(1,0,0), vertup["yRange"] * 3.14159/180.0).get_rotation_quat(), Vector3.ONE)

		anim = animplayer.get_animation("LOOKDOWN")
		if anim:
			var animtrack = anim.add_track(Animation.TYPE_TRANSFORM)
			anim.track_set_path(animtrack, leftEyePath)
			anim.track_set_interpolation_type(animtrack, Animation.INTERPOLATION_LINEAR)
			anim.transform_track_insert_key(animtrack, 0.0, Vector3.ZERO, Quat.IDENTITY, Vector3.ONE)
			anim.transform_track_insert_key(animtrack, vertdown["xRange"] / 90.0, Vector3.ZERO, Basis(Vector3(1,0,0), -vertdown["yRange"] * 3.14159/180.0).get_rotation_quat(), Vector3.ONE)
			animtrack = anim.add_track(Animation.TYPE_TRANSFORM)
			anim.track_set_path(animtrack, rightEyePath)
			anim.track_set_interpolation_type(animtrack, Animation.INTERPOLATION_LINEAR)
			anim.transform_track_insert_key(animtrack, 0.0, Vector3.ZERO, Quat.IDENTITY, Vector3.ONE)
			anim.transform_track_insert_key(animtrack, vertdown["xRange"] / 90.0, Vector3.ZERO, Basis(Vector3(1,0,0), -vertdown["yRange"] * 3.14159/180.0).get_rotation_quat(), Vector3.ONE)
	return animplayer


func _parse_secondary_node(secondary_node: Node, vrm_extension: Dictionary, gstate: GLTFState):
	var nodes = gstate.get_nodes()
	var skeletons = gstate.get_skeletons()

	var vrm_secondary:GDScript = load("res://addons/vrm/vrm_secondary.gd")
	var vrm_collidergroup:GDScript = load("res://addons/vrm/vrm_collidergroup.gd")
	var vrm_springbone:GDScript = load("res://addons/vrm/vrm_springbone.gd")

	var collider_groups: Array = Array()
	for cgroup in vrm_extension["secondaryAnimation"]["colliderGroups"]:
		var gltfnode: GLTFNode = nodes[int(cgroup["node"])]
		var collider_group = vrm_collidergroup.new()
		collider_group.sphere_colliders = Array() # HACK HACK HACK
		if gltfnode.skeleton == -1:
			var found_node: Node = gstate.get_scene_node(int(cgroup["node"]))
			collider_group.skeleton_or_node = secondary_node.get_path_to(found_node)
			collider_group.bone = ""
			collider_group.resource_name = found_node.name
		else:
			var skeleton: Skeleton = _get_skel_godot_node(gstate, nodes, skeletons,gltfnode.skeleton)
			collider_group.skeleton_or_node = secondary_node.get_path_to(skeleton)
			collider_group.bone = nodes[int(cgroup["node"])].resource_name
			collider_group.resource_name = collider_group.bone
		
		for collider_info in cgroup["colliders"]:
			var offset_obj = collider_info.get("offset", {"x": 0.0, "y": 0.0, "z": 0.0})
			var local_pos: Vector3 = Vector3(offset_obj["x"], offset_obj["y"], offset_obj["z"])
			var radius: float = collider_info.get("radius", 0.0)
			collider_group.sphere_colliders.append(Plane(local_pos, radius))
		collider_groups.append(collider_group)

	var spring_bones: Array = Array()
	for sbone in vrm_extension["secondaryAnimation"]["boneGroups"]:
		if sbone.get("bones", []).size() == 0:
			continue
		var first_bone_node: int = sbone["bones"][0]
		var gltfnode: GLTFNode = nodes[int(first_bone_node)]
		var skeleton: Skeleton = _get_skel_godot_node(gstate, nodes, skeletons,gltfnode.skeleton)

		var spring_bone = vrm_springbone.new()
		spring_bone.skeleton = secondary_node.get_path_to(skeleton)
		spring_bone.comment = sbone.get("comment", "")
		spring_bone.stiffness_force = float(sbone.get("stiffiness", 1.0))
		spring_bone.gravity_power = float(sbone.get("gravityPower", 0.0))
		var gravity_dir = sbone.get("gravity_dir", {"x": 0.0, "y": -1.0, "z": 0.0})
		spring_bone.gravity_dir = Vector3(gravity_dir["x"], gravity_dir["y"], gravity_dir["z"])
		spring_bone.drag_force = float(sbone.get("drag_force", 0.4))
		spring_bone.hit_radius = float(sbone.get("hitRadius", 0.02))
		
		if spring_bone.comment != "":
			spring_bone.resource_name = spring_bone.comment.split("\n")[0]
		else:
			var tmpname: String = ""
			if sbone["bones"].size() > 1:
				tmpname += " + " + str(sbone["bones"].size() - 1) + " roots"
			tmpname = nodes[int(first_bone_node)].resource_name + tmpname
			spring_bone.resource_name = tmpname
		
		spring_bone.collider_groups = Array() # HACK HACK HACK
		for cgroup_idx in sbone.get("colliderGroups", []):
			spring_bone.collider_groups.append(collider_groups[int(cgroup_idx)])

		spring_bone.root_bones = Array() # HACK HACK HACK
		for bone_node in sbone["bones"]:
			var bone_name:String = nodes[int(bone_node)].resource_name
			if skeleton.find_bone(bone_name) == -1:
				# Note that we make an assumption that a given SpringBone object is
				# only part of a single Skeleton*. This error might print if a given
				# SpringBone references bones from multiple Skeleton's.
				printerr("Failed to find node " + str(bone_node) + " in skel " + str(skeleton))
			else:
				spring_bone.root_bones.append(bone_name)

		# Center commonly points outside of the glTF Skeleton, such as the root node.
		spring_bone.center_node = secondary_node.get_path_to(secondary_node)
		spring_bone.center_bone = ""
		var center_node_idx = sbone.get("center", -1)
		if center_node_idx != -1:
			var center_gltfnode: GLTFNode = nodes[int(center_node_idx)]
			var bone_name:String = center_gltfnode.resource_name
			if center_gltfnode.skeleton == gltfnode.skeleton and skeleton.find_bone(bone_name) != -1:
				spring_bone.center_bone = bone_name
				spring_bone.center_node = NodePath()
			else:
				spring_bone.center_bone = ""
				spring_bone.center_node = secondary_node.get_path_to(gstate.get_scene_node(int(center_node_idx)))
				if spring_bone.center_node == NodePath():
					printerr("Failed to find center scene node " + str(center_node_idx))
					spring_bone.center_node = secondary_node.get_path_to(secondary_node) # Fallback

		spring_bones.append(spring_bone)

	secondary_node.set_script(vrm_secondary)
	secondary_node.set("spring_bones", spring_bones)
	secondary_node.set("collider_groups", collider_groups)


func import_scene(path: String, flags: int = 1, bake_fps: int = 1):
	var f = File.new()
	if f.open(path, File.READ) != OK:
		return FAILED

	var magic = f.get_32()
	if magic != 0x46546C67:
		return ERR_FILE_UNRECOGNIZED
	f.get_32() # version
	f.get_32() # length

	var chunk_length = f.get_32();
	var chunk_type = f.get_32();

	if chunk_type != 0x4E4F534A:
		return ERR_PARSE_ERROR
	var json_data : PoolByteArray = f.get_buffer(chunk_length)
	f.close()

	var text : String = json_data.get_string_from_utf8()
	read_vrm(text)
	var gstate : GLTFState = GLTFState.new()
	var gltf : PackedSceneGLTF = PackedSceneGLTF.new()
	
	var root_node : Node = gltf.import_gltf_scene(path, 0, 1000.0, gstate)

	var gltf_json : Dictionary = gstate.json
	var vrm_extension : Dictionary = gltf_json["extensions"]["VRM"]

	var human_bone_to_idx: Dictionary = {}
	# Ignoring in ["humanoid"]: armStretch, legStretch, upperArmTwist
	# lowerArmTwist, upperLegTwist, lowerLegTwist, feetSpacing,
	# and hasTranslationDoF
	for human_bone in vrm_extension["humanoid"]["humanBones"]:
		human_bone_to_idx[human_bone["bone"]] = int(human_bone["node"])
		# Unity Mecanim properties:
		# Ignoring: useDefaultValues
		# Ignoring: min
		# Ignoring: max
		# Ignoring: center
		# Ingoring: axisLength

	_update_materials(vrm_extension, gstate)

	var animplayer = AnimationPlayer.new()
	animplayer.name = "anim"
	root_node.add_child(animplayer)
	animplayer.owner = root_node
	_create_animation_player(animplayer, vrm_extension, gstate, human_bone_to_idx)

	var vrm_top_level:GDScript = load("res://addons/vrm/vrm_toplevel.gd")
	root_node.set_script(vrm_top_level)

	var vrm_meta: Resource = _create_meta(root_node, animplayer, vrm_extension, gstate, human_bone_to_idx)
	root_node.set("vrm_meta", vrm_meta)
	root_node.set("vrm_secondary", NodePath())

	if (vrm_extension.has("secondaryAnimation") and \
			(vrm_extension["secondaryAnimation"].get("colliderGroups", []).size() > 0 or \
			vrm_extension["secondaryAnimation"].get("boneGroups", []).size() > 0)):

		var secondary_node: Node = root_node.get_node("secondary")
		if secondary_node == null:
			secondary_node = Spatial.new()
			root_node.add_child(secondary_node)
			secondary_node.set_owner(root_node)
			secondary_node.set_name("secondary")
		
		var secondary_path: NodePath = root_node.get_path_to(secondary_node)
		root_node.set("vrm_secondary", secondary_path)

		_parse_secondary_node(secondary_node, vrm_extension, gstate)

	# for anim_name in animplayer.get_animation_list():
	# 	var anim: Animation = animplayer.get_animation(anim_name)
	# 	for track_index in anim.get_track_count():
	# 		for key_index in anim.track_get_key_count(track_index):
	# 			pass
				# print(anim_name)
				# print(anim.track_get_key_value(track_index, key_index))
				# print(anim.track_get_path(track_index))

	animplayer.queue_free()
	
	AppManager.vrm_mappings = self.vrm_mappings

	return root_node

	# if (!ResourceLoader.exists(path + ".res")):
	# 	ResourceSaver.save(path + ".res", gstate)
	# Remove references
	# var packed_scene: PackedScene = PackedScene.new()
	# packed_scene.pack(root_node)
	# return packed_scene.instance()
#	return packed_scene.instance(PackedScene.GEN_EDIT_STATE_INSTANCE)

func _convert_sql_to_material_param(column_name: String, value):
	if "color" in column_name:
		pass
	return value

func _to_dict(columns: Array, values: Array):
	var dict : Dictionary = {}
	for i in range(columns.size()):
		dict[columns[i]] = values[i]
	return dict

func _to_material_param_dict(columns: Array, values: Array):
	var dict : Dictionary = {}
	print("Col size=" + str(columns.size()) + " val size=" + str(values.size()))
	for i in range(min(columns.size(), values.size())):
		dict[columns[i]] = _convert_sql_to_material_param(columns[i], values[i])
	return dict

class MaterialAccess:
	enum Props { FP, VP, TP }
	var fp: Dictionary
	var vp: Dictionary
	var tp: Dictionary

	func _init(p_fp: Dictionary, p_vp: Dictionary, p_tp: Dictionary) -> void:
		fp = p_fp
		vp = p_vp
		tp = p_tp

	func try_get(k: String, prop_dict: int):
		match prop_dict:
			Props.FP:
				if fp.has(k):
					return fp[k]
			Props.VP:
				if vp.has(k):
					return vp[k]
			Props.TP:
				if tp.has(k):
					return tp[k]
		return null

func read_vrm(json: String):
	var model_data
	
	var db: Dictionary = {} # The best kind of db

	var query = "";
	var result = null;

	db["vrm"] = JSON.parse(json).result

	db["vrm_bone"] = {}
	for b in db["vrm"]["extensions"]["VRM"]["humanoid"]["humanBones"]:
		db["vrm_bone"][b["bone"]] = b["node"]

	# db["vrm_def"] = {}
	# for k in db["vrm"].keys():
	# 	db["vrm_def"][k] = db["vrm"][k]

	db["vrm_meta"] = {}
	for k in db["vrm"]["extensions"]["VRM"]["meta"].keys():
		db["vrm_meta"][k] = db["vrm"]["extensions"]["VRM"]["meta"][k]

	db["vrm_material"] = {}
	for i in db["vrm"]["extensions"]["VRM"]["materialProperties"]:
		var m_name = i["name"]
		var m_shader = i["shader"]
		var m_render_queue = i["renderQueue"]
		var m_float_properties = i["floatProperties"]
		var m_vector_properties = i["vectorProperties"]
		var m_texture_properties = i["textureProperties"]
		var m_keyword_map = i["keywordMap"]
		var material_access: MaterialAccess = MaterialAccess.new(m_float_properties, m_vector_properties, m_texture_properties)

		db["vrm_material"][m_name] = {
			# Leave out the name since it's redunddant
			# "name": m_name,
			"shader": m_shader,
			"render_queue": m_render_queue,
			"keyword_map": m_keyword_map,
			"cutoff": material_access.try_get("_Cutoff", MaterialAccess.Props.FP),
			"bump_scale": material_access.try_get("_BumpScale", MaterialAccess.Props.FP),
			"receive_shadow_rate": material_access.try_get("_ReceiveShadowRate", MaterialAccess.Props.FP),
			"shading_grade_rate": material_access.try_get("_ShadingGradeRate", MaterialAccess.Props.FP),
			"shade_shift": material_access.try_get("_ShadeShift", MaterialAccess.Props.FP),
			"shade_toony": material_access.try_get("_ShadeToony", MaterialAccess.Props.FP),
			"light_color_attenuation": material_access.try_get("_LightColorAttenuation", MaterialAccess.Props.FP),
			"indirect_light_intensity": material_access.try_get("_IndirectLightIntensity", MaterialAccess.Props.FP),
			"outline_width": material_access.try_get("_OutlineWidth", MaterialAccess.Props.FP),
			"outline_scaled_max_distance": material_access.try_get("_OutlineScaledMaxDistance", MaterialAccess.Props.FP),
			"outline_lighting_mix": material_access.try_get("_OutlineLightingMix", MaterialAccess.Props.FP),
			"debug_mode": material_access.try_get("_DebugMode", MaterialAccess.Props.FP),
			"blend_mode": material_access.try_get("_BlendMode", MaterialAccess.Props.FP),
			"outline_width_mode": material_access.try_get("_OutlineWidthMode", MaterialAccess.Props.FP),
			"outline_color_mode": material_access.try_get("_OutlineColorMode", MaterialAccess.Props.FP),
			"cull_mode": material_access.try_get("_CullMode", MaterialAccess.Props.FP),
			"src_blend": material_access.try_get("_SrcBlend", MaterialAccess.Props.FP),
			"dst_blend": material_access.try_get("_DstBlend", MaterialAccess.Props.FP),
			"z_write": material_access.try_get("_ZWrite", MaterialAccess.Props.FP),
			"color": material_access.try_get("_Color", MaterialAccess.Props.VP),
			"shade_color": material_access.try_get("_ShadeColor", MaterialAccess.Props.VP),
			"bump_map": material_access.try_get("_BumpMap", MaterialAccess.Props.TP),
			"receive_shadow_texture": material_access.try_get("_ReceiveShadowTexture", MaterialAccess.Props.TP),
			"shading_grade_texture": material_access.try_get("_ShadingGradeTexture", MaterialAccess.Props.TP),
			"sphere_add_v": material_access.try_get("_SphereAdd", MaterialAccess.Props.VP),
			"emission_color": material_access.try_get("_EmissionColor", MaterialAccess.Props.VP),
			"emission_map": material_access.try_get("_EmissionMap", MaterialAccess.Props.TP),
			"outline_width_texture": material_access.try_get("_OutlineWidthTexture", MaterialAccess.Props.VP),
			"outline_color": material_access.try_get("_OutlineColor", MaterialAccess.Props.VP),
			"main_tex": material_access.try_get("_MainTex", MaterialAccess.Props.TP),
			"shade_texture": material_access.try_get("_ShadeTexture", MaterialAccess.Props.TP),
			"sphere_add_t": material_access.try_get("_SphereAdd", MaterialAccess.Props.TP)
		}

#	var vrm_data : SQLiteQuery = db.create_query("SELECT * FROM vrm_material")
#	var columns: Array = vrm_data.get_columns()
#	var list_of_materials: Array = vrm_data.execute()

	#for material in list_of_materials:
	#	var param_dict = _to_material_param_dict(columns, material)
	#	#print(param_dict)

	#var dict = make_dict(
	#print(vrm_data.get_columns())
	#print()

	#vrm_data = db.create_query("SELECT * FROM vrm_meta")
	#print(vrm_data.get_columns())
	#print(vrm_data.execute())

	#vrm_data = db.create_query("SELECT * FROM vrm_bone LIMIT 1")
	#print(vrm_data.get_columns())
	#print(vrm_data.execute())

	# Close database
#	db.close()
