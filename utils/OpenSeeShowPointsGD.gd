extends Spatial

const VIS_SPHERE: Resource = preload("res://entities/VisualizationSphere.tscn")
const VIS_CYLINDER: Resource = preload("res://entities/VisualizationCylinder.tscn")
const VIS_RECTANGLE: Resource = preload("res://entities/VisualizationRectangle.tscn")

const OPEN_SEE: Resource = preload("res://utils/OpenSeeGD.tscn")
const IFACIAL: Resource = preload("res://utils/iFacialGD.tscn")
const DEV_UI: Resource = preload("res://utils/gui/DevUI.tscn")

#var open_see: OpenSeeGD = null

export var face_id: int = 0

export var only_30_points: bool = false
export var show_3d_points: bool = true

export var apply_translation: bool = true
export var apply_rotation: bool = true
# Expose these values so they can be viewed in the editor
var current_translation
var current_rotation
var current_quat
class StoredOffsets:
	var translation_offset: Vector3
	var rotation_offset: Vector3
	var quat_offset: Quat
var stored_offsets: StoredOffsets = StoredOffsets.new()

export var min_confidence: float = 0.2

export var show_gaze: bool = true

export var material: Material

export var show_lines: bool = false
export var line_width: float = 0.01
export var line_material: Material

export var receive_shadows: bool = false

var open_see_data: OpenSeeGD.OpenSeeData
var game_objects: Array
var line_renderers: Array # TODO probably don't need this
var center_ball

var updated: float = 0.0
var total: int = 70

var lines: PoolIntArray = [
	# Contour
	1, 2, 3, 4, 5, 6, 7, 8, 9, 10, 11, 12, 13, 14, 15, 16, -1,
	# Eyebrows
	18, 19, 20, 21, -1, 23, 24, 25, 26, -1,
	# Noses
	28, 29, 30, 33, 32, 33, 34, 35, -1,
	# Eye
	37, 38, 39, 40, 41, 36,
	# Eye
	43, 44, 45, 46, 47, 42,
	# Mouth
	49, 50, 51, 52, 62, 54, 55, 56, 57, 58, 59, 60, 61, 62, 63, 64, 65, 58, 58, 62
]

var point_30_set: PoolIntArray = [
	0, 2, 5, 8, 11, 14, 16, 17, 19, 21, 22, 24, 26, 27, 30, 33, 36, 37, 39, 40, 42, 43, 45, 46, 50, 55, 58, 60, 62, 64
]
var point_30_lines: PoolIntArray = [
	# Contour
	2, -1, 5, -1, -1, 8, -1, -1, 11, -1, -1, 14, -1, -1, 16, -1, -1,
	# Eyebrows
	19, -1, 21, -1, -1, 24, -1, 26, -1, -1,
	# Nose
	30, -1, -1, 33, -1, -1, -1, -1, -1,
	# Eye
	37, 39, -1, 40, 36, -1,
	# Eye
	43, 45, -1, 46, 42, -1,
	# Mouth
	-1, -1, 62, -1, -1, -1, -1, 58, -1, -1, 60, -1, 62, -1, 64, -1, 58, -1, 58, 62

]

###############################################################################
# Builtin functions                                                           #
###############################################################################

# TODO move magic numbers to top of file
func _ready() -> void:
	self.open_see = OPEN_SEE.instance()
	self.call_deferred("add_child", open_see)

	game_objects.resize(70)
	line_renderers.resize(68)
	
	if not line_material:
		show_lines = false
	
	if not show_gaze:
		total = 66

	for i in range(total):
		var sphere = VIS_SPHERE.instance()
		sphere.name = "Point " + str(i + 1)
		if material:
			# TODO might just need to use property access
			sphere.set_surface_material(material)
		sphere.transform = Transform()
		sphere.scale_object_local(Vector3(0.025, 0.025, 0.025))
		
		game_objects[i] = sphere
		self.call_deferred("add_child", sphere)
		if i >= 68:
			var cylinder = VIS_CYLINDER.instance()
			if material:
				# TODO might just need to use property access
				cylinder.set_surface_material(material)
			cylinder.transform = Transform()
			cylinder.transform.origin = Vector3(0.0, 0.0, -4.0)
			cylinder.scale_object_local(Vector3(1.0, 4.0, 1.0))
			sphere.call_deferred("add_child", cylinder)
	
	# TODO need to figure out what exactly a line renderer is
	# Original code references a 'LineRenderer' type/component
	# so this is incomplete
	for i in range(68):
		if i == 66:
			var rectangle = VIS_RECTANGLE.instance()
			if only_30_points:
				game_objects[50].call_deferred("add_child", rectangle)
			else:
				game_objects[48].call_deferred("add_child", rectangle)
		elif i == 67:
			var rectangle = VIS_RECTANGLE.instance()
			if only_30_points:
				game_objects[55].call_deferred("add_child", rectangle)
			else:
				game_objects[53].call_deferred("add_child", rectangle)

	self.center_ball = VIS_SPHERE.instance()
	center_ball.name = "Center"
	center_ball.transform = Transform()
	center_ball.scale_object_local(Vector3(0.1, 0.1, 0.1))
	self.call_deferred("add_child", center_ball)
	
	var dev_ui: Control = DEV_UI.instance()
	self.add_child(dev_ui)

func _process(_delta: float) -> void:
	if not open_see:
		return

	self.open_see_data = open_see.get_open_see_data(face_id)
	if(not open_see_data or (show_3d_points and open_see_data.fit_3d_error > open_see.max_fit_3d_error)):
		return
	
	if open_see_data.time > updated:
		updated = open_see_data.time
	else:
		return

	# self.look_at(get_parent().get_node("Camera").transform.origin, Vector3.UP)

	if self.show_3d_points:
		center_ball.visible = false
		for i in range(self.total):
			if(open_see_data.got_3d_points and (i >= 68 or open_see_data.confidence[i] > min_confidence)):
				var pt: Vector3 = open_see_data.points_3d[i]
				pt.x = -pt.x
				game_objects[i].transform.origin = pt
				if i < 68:
					var red_color_data: Vector3 = Vector3(Color.red.r, Color.red.g, Color.red.b)
					var green_color_data: Vector3 = Vector3(Color.green.r, Color.green.g, Color.green.b)
					var lerped_color: Vector3 = lerp(red_color_data, green_color_data, open_see_data.confidence[i])
					var color: Color = Color(lerped_color.x, lerped_color.y, lerped_color.z)
					game_objects[i].color = color
				# else:
				# 	if i == 68:
				# 		# game_objects[i].transform = game_objects[i].transform.looking_at(open_see_data.right_gaze, Vector3.UP)
				# 		# game_objects[i].transform.basis = Basis(game_objects[i].transform.basis.slerp(open_see_data.right_gaze, 0.1))
				# 		var quat_a: Quat = Quat(game_objects[i].transform.basis)
				# 		var quat_b: Quat = open_see_data.right_gaze
				# 		game_objects[i].transform = Transform(quat_a.slerp(quat_b, .01))
				# 	else:
				# 		# game_objects[i].transform = game_objects[i].transform.looking_at(open_see_data.left_gaze, Vector3.UP)
				# 		# game_objects[i].transform.basis = Basis(game_objects[i].transform.basis.slerp(open_see_data.left_gaze, 0.1))
				# 		var quat_a: Quat = Quat(game_objects[i].transform.basis)
				# 		var quat_b: Quat = open_see_data.left_gaze
				# 		game_objects[i].transform = Transform(quat_a.slerp(quat_b, .01))
			else:
				game_objects[i].color = Color.cyan
		if apply_translation:
			self.current_translation = open_see_data.translation
			var v: Vector3
			if stored_offsets.translation_offset:
				v = stored_offsets.translation_offset - open_see_data.translation
			else:
				v = open_see_data.translation
			# v.x = -v.x
			# v.y = -v.y
			# v.z = -v.z
			self.transform.origin = v
		if apply_rotation:
			self.current_quat = open_see_data.raw_quaternion
			self.current_rotation = open_see_data.rotation
			# var rotation: Vector3
			# if stored_offsets.rotation_offset:
			# 	rotation = stored_offsets.rotation_offset - open_see_data.rotation
			# else:
			# 	rotation = open_see_data.rotation
			# self.transform.basis = Basis(rotation.normalized())
			var offset: Quat = Quat(Vector3(0.0, 0.0, -90.0))
			# var offset: Quat = Quat(Vector3(0.0, 0.0, 0.0))
			# var converted_quat: Quat = Quat(-open_see_data.raw_quaternion.y, -open_see_data.raw_quaternion.x, open_see_data.raw_quaternion.z, open_see_data.raw_quaternion.w) * offset
			var converted_quat: Quat = _to_godot_quat(open_see_data.raw_quaternion) * offset

			if stored_offsets.quat_offset:
				# converted_quat = stored_offsets.quat_offset + Quat(-open_see_data.raw_quaternion.y, -open_see_data.raw_quaternion.x, open_see_data.raw_quaternion.z, open_see_data.raw_quaternion.w)
				converted_quat = stored_offsets.quat_offset - _to_godot_quat(open_see_data.raw_quaternion)

			self.transform.basis = Basis(converted_quat.normalized())
			
			# self.rotate_z(deg2rad(-22.5))
	else:
		# center_ball.visible = false
		var center: Vector3 = Vector3.ZERO
		# TODO fill out the rest?

	for i in range(68):
		if((not only_30_points and lines[i] == -1) or (only_30_points and point_30_lines[i] == -1)):
			continue
		if(not show_lines or not line_material):
			pass
		else:
			var a: int = i
			var b: int = lines[i]
			if only_30_points:
				b = point_30_lines[i]
				if i == 66:
					a = 50
				if i == 67:
					a = 55
			else:
				if i == 66:
					a = 48
				if i == 67:
					a = 53
			var red_color_data: Vector3 = Vector3(Color.red.r, Color.red.g, Color.red.b)
			var green_color_data: Vector3 = Vector3(Color.green.r, Color.green.g, Color.green.b)
			var confidence_lerp: float = lerp(open_see_data.confidence[a], open_see_data.confidence[b], 0.5)
			var lerped_color: Vector3 = lerp(red_color_data, green_color_data, confidence_lerp)
			var color: Color = Color(lerped_color.x, lerped_color.y, lerped_color.z)
			# TODO finish this later?

func _input(event: InputEvent) -> void:
	if event.is_action_pressed("ui_accept"):
		_save_offsets()

###############################################################################
# Connections                                                                 #
###############################################################################

###############################################################################
# Private functions                                                           #
###############################################################################

func _to_godot_quat(v: Quat) -> Quat:
	return Quat(v.x, -v.y, v.z, v.w)

func _save_offsets() -> void:
	stored_offsets.translation_offset = open_see_data.translation
	stored_offsets.rotation_offset = open_see_data.rotation
	var offset: Quat = Quat(Vector3(0.0, 0.0, -90.0))
	# var offset: Quat = Quat(Vector3(0.0, 0.0, 0.0))
	# stored_offsets.quat_offset = Quat(-open_see_data.raw_quaternion.y, -open_see_data.raw_quaternion.x, open_see_data.raw_quaternion.z, open_see_data.raw_quaternion.w) * offset
	stored_offsets.quat_offset = _to_godot_quat(open_see_data.raw_quaternion) * offset

###############################################################################
# Public functions                                                            #
###############################################################################


