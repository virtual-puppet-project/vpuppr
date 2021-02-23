extends Spatial

export var spring_bones: Array
export var collider_groups: Array

# Props
var secondary_gizmo: SecondaryGizmo

# Called when the node enters the scene tree for the first time.
func _ready():
	secondary_gizmo = SecondaryGizmo.new(self)
	add_child(secondary_gizmo)
	
	if not Engine.editor_hint:
		for collider_group in collider_groups:
			collider_group._ready(get_node(collider_group.skeleton_or_node))
		for bg in spring_bones:
			bg._ready(get_node(bg.skeleton))
	return

# Called every frame. 'delta' is the elapsed time since the previous frame.
func _process(delta):
	if not get_parent():
		return
	if(get_parent() && not get_parent().get("update_secondary_fixed")):
		if not Engine.editor_hint:
			# HACK: Force update skeleton before call "ALL" springbones process
			for bg in spring_bones: # HACK
				var skeleton = get_node(bg.skeleton) # HACK
				skeleton.set_bone_rest(0, skeleton.get_bone_rest(0)) # HACK
	
			for collider_group in collider_groups:
				collider_group._process()
	
			for bg in spring_bones:
				bg._process(delta, bg.skeleton)
	
			if secondary_gizmo != null:
				secondary_gizmo.draw_in_game()
	
		if Engine.editor_hint:
			if secondary_gizmo != null:
				secondary_gizmo.draw_in_editor()
	return

# All animations to the Node need to be done in the _physics_process.
func _physics_process(delta):
	if not get_parent():
		return
	if(get_parent() and get_parent().get("update_secondary_fixed")):
		if not Engine.editor_hint:
			# HACK: Force update skeleton before call "ALL" springbones process
			for bg in spring_bones: # HACK
				var skeleton = get_node(bg.skeleton) # HACK
				skeleton.set_bone_rest(0, skeleton.get_bone_rest(0)) # HACK
	
			for collider_group in collider_groups:
				collider_group._process()
	
			for bg in spring_bones:
				bg._process(delta, bg.skeleton)
	
			if secondary_gizmo != null:
				secondary_gizmo.draw_in_game()
	
		if Engine.editor_hint:
			if secondary_gizmo != null:
				secondary_gizmo.draw_in_editor()





class SecondaryGizmo:
	extends ImmediateGeometry
	
	var secondary_node
	var m: SpatialMaterial = SpatialMaterial.new()
	
	func _init(parent):
		secondary_node = parent
		set_material()
		return
	
	func set_material():
		m.flags_unshaded = true
		m.flags_use_point_size = true
		m.flags_no_depth_test = true
		m.vertex_color_use_as_albedo = true

	func draw_in_editor():
		clear()
		var selected: Array = EditorPlugin.new().get_editor_interface().get_selection().get_selected_nodes()
		if selected.has(secondary_node.get_parent()) || selected.has(secondary_node):
			draw_collider_groups()
	
	func draw_in_game():
		clear()
		if secondary_node.get_parent().get("gizmo_spring_bone"):
			draw_spring_bones(secondary_node.get_parent().gizmo_spring_bone_color)
	
	func draw_spring_bones(color: Color):
		set_material_override(m)
		# Spring bones
		for spring_bone in secondary_node.spring_bones:
			for v in spring_bone.verlets:
				var s_sk: Skeleton = v.skeleton
				var s_tr: Transform = s_sk.get_bone_global_pose(v.bone_idx)
				draw_line(
					s_tr.origin,
					VRMTopLevel.VRMUtil.inv_transform_point(s_sk.global_transform, v.current_tail),
					color
				)
				draw_sphere(
					s_tr,
					VRMTopLevel.VRMUtil.inv_transform_point(s_sk.global_transform, v.current_tail),
					spring_bone.hit_radius,
					color
				)
		return
	
	func draw_collider_groups():
		set_material_override(m)						
		for collider_group in secondary_node.collider_groups:
			var c_sk: Skeleton = secondary_node.get_node(collider_group.skeleton_or_node)
			var c_tr: Transform = c_sk.get_bone_global_pose(c_sk.find_bone(collider_group.bone))
			for collider in collider_group.sphere_colliders:
				var c_ps: Vector3 = VRMTopLevel.VRMUtil.coordinate_u2g(collider.normal)
				draw_sphere(c_tr, VRMTopLevel.VRMUtil.transform_point(c_tr, c_ps), collider.d, collider_group.gizmo_color)
		return
	
	func draw_line(begin_pos: Vector3, end_pos: Vector3, color: Color):
		begin(Mesh.PRIMITIVE_LINES)
		set_color(color)
		add_vertex(begin_pos)
		add_vertex(end_pos)
		end()
		return
	
	func draw_sphere(tr: Transform, center: Vector3, radius: float, color: Color):
		var step: int = 16
		var sppi: float = 2 * PI / step
		begin(Mesh.PRIMITIVE_LINE_LOOP)
		set_color(color)
		for i in range(step):
			add_vertex(center + (tr.basis * Vector3.UP * radius).rotated(tr.basis * Vector3.RIGHT, sppi * i))
		end()
		begin(Mesh.PRIMITIVE_LINE_LOOP)
		set_color(color)
		for i in range(step):
			add_vertex(center + (tr.basis * Vector3.RIGHT * radius).rotated(tr.basis * Vector3.FORWARD, sppi * i))
		end()
		begin(Mesh.PRIMITIVE_LINE_LOOP)
		set_color(color)
		for i in range(step):
			add_vertex(center + (tr.basis * Vector3.FORWARD * radius).rotated(tr.basis * Vector3.UP, sppi * i))
		end()
		return
