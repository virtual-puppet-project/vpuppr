extends BaseTreeLayout

# TODO this needs to be reworked

class View extends ScrollContainer:
	var logger: Logger

	## Whether or not to apply tracking data to the bone
	var is_tracking := CheckButton.new()
	## Whether or not to consider user input as bone-pose input
	var should_pose := CheckButton.new()
	## When tracking the bone, whether or not to use the global interpolation rate
	var should_use_custom_interpolation := CheckButton.new()
	## Interpolation rate to use when applying tracking data
	var interpolation_rate := LineEdit.new()
	## Resets the pose of the bone
	var reset_bone := Button.new()

	func _init(bone_name: String, p_logger: Logger) -> void:
		name = bone_name
		visible = false
		logger = p_logger

		var options_list := VBoxContainer.new()
		ControlUtil.all_expand_fill(options_list)

		var bone_name_label := Label.new()
		bone_name_label.text = bone_name
		bone_name_label.align = Label.ALIGN_CENTER

		options_list.add_child(bone_name_label)

		is_tracking.text = tr("DEFAULT_GUI_BONES_IS_TRACKING_TOGGLE")
		options_list.add_child(is_tracking)

		should_pose.text = tr("DEFAULT_GUI_BONES_SHOULD_POSE_TOGGLE")
		options_list.add_child(should_pose)

		#region Interpolation rate

		should_use_custom_interpolation.text = tr("DEFAULT_GUI_BONES_SHOULD_USE_CUSTOM_INTERPOLATION_TOGGLE")
		options_list.add_child(should_use_custom_interpolation)

		var hbox := HBoxContainer.new()
		ControlUtil.h_expand_fill(hbox)

		var interpolation_label := Label.new()
		interpolation_label.text = tr("DEFAULT_GUI_BONES_INTERPOLATION_RATE_LABEL")
		ControlUtil.h_expand_fill(interpolation_label)

		hbox.add_child(interpolation_label)

		ControlUtil.h_expand_fill(interpolation_rate)

		hbox.add_child(interpolation_rate)

		options_list.add_child(hbox)

		#endregion

		reset_bone.text = tr("DEFAULT_GUI_BONES_RESET_BONE_POSE_BUTTON")

		options_list.add_child(reset_bone)

		add_child(options_list)

	func _on_bone_updated(payload: SignalPayload) -> void:
		if not payload is SignalPayload:
			logger.error("Unexpected callback value %s" % str(payload))
			return
		if name != payload.id:
			return

		match payload.signal_name:
			"additional_bones":
				is_tracking.set_pressed_no_signal(payload.id in payload.data)
			"bones_to_interpolate":
				should_use_custom_interpolation.set_pressed_no_signal(payload.id in payload.data)
			"bone_interpolation_rates":
				var current_text := interpolation_rate.text
				# TODO we might be comparing floats here, so will need to fuzzy compare instead
				if current_text.is_valid_float() and current_text.to_float() == payload.get_changed():
					return
				interpolation_rate.text = str(payload.get_changed())
				interpolation_rate.caret_position = interpolation_rate.text.length()

	func _on_event_published(payload: SignalPayload) -> void:
		if payload.signal_name != Globals.POSE_BONE or payload.id != name:
			return

		should_pose.set_pressed_no_signal(payload.data)

const BONE_SIGNALS := [
	"additional_bones",
	"bones_to_interpolate",
	"bone_interpolation_rates"
]

const INFO_PAGE := "DEFAULT_GUI_BONES_INFO_PAGE"

var info: ScrollContainer

var model: Node

#-----------------------------------------------------------------------------#
# Builtin functions                                                           #
#-----------------------------------------------------------------------------#

func _setup() -> Result:
	info = $Info
	_initial_page = tr(INFO_PAGE)

	_set_tree($Tree)

	tree.hide_root = true
	var root: TreeItem = tree.create_item()

	var info_item: TreeItem = tree.create_item(root)
	info_item.set_text(TREE_COLUMN, _initial_page)
	info_item.select(TREE_COLUMN)

	pages[_initial_page] = Page.new(info, info_item)
	
	_toggle_page(_initial_page)

	tree.connect("item_selected", self, "_on_item_selected")

	model = get_tree().current_scene.get("model")
	if model == null:
		return Safely.err(Error.Code.GUI_SETUP_ERROR, "No model found, no bone functionality will be available")

	var model_skeleton = model.get("skeleton")
	if model_skeleton == null:
		return Safely.err(Error.Code.GUI_SETUP_ERROR, "No model skeleton found, no bone functionality will be available")

	# Store all references to TreeItems, discard afterwards
	var known_bones := {}

	for bone_idx in model_skeleton.get_bone_count():
		var bone_name: String = model_skeleton.get_bone_name(bone_idx)
		var bone_parent_id: int = model_skeleton.get_bone_parent(bone_idx)

		var parent_item: TreeItem = root if bone_parent_id < 0 else known_bones[model_skeleton.get_bone_name(bone_parent_id)]

		var item: TreeItem = tree.create_item(parent_item)
		item.set_text(TREE_COLUMN, bone_name)

		known_bones[bone_name] = item
		
		var bone_display := View.new(bone_name, logger)
		pages[bone_name] = Page.new(bone_display, item)
		
		add_child(bone_display)

		_connect_element(bone_display.is_tracking, _generate_connect_args("additional_bones", bone_name))
		bone_display.should_pose.connect("toggled", self, "_on_should_pose", [bone_name])
		_connect_element(bone_display.should_use_custom_interpolation, _generate_connect_args("bones_to_interpolate", bone_name))
		_connect_element(bone_display.interpolation_rate, _generate_connect_args("bone_interpolation_rates", bone_name))
		bone_display.reset_bone.connect("pressed", self, "_on_reset_bone", [bone_name])

		for signal_name in BONE_SIGNALS:
			AM.ps.subscribe(bone_display, signal_name, "_on_bone_updated")

		AM.ps.subscribe(bone_display, Globals.EVENT_PUBLISHED)

	return Safely.ok()

#-----------------------------------------------------------------------------#
# Connections                                                                 #
#-----------------------------------------------------------------------------#

func _on_is_tracking(state: bool, bone_name: String) -> void:
	var bone_id: int = model.skeleton.find_bone(bone_name)
	if bone_id < 0:
		logger.error("Bone %s not found, aborting config modification" % bone_name)
		return

	AM.ps.publish("additional_bones", bone_id if state else null, bone_name)

func _on_should_pose(state: bool, bone_name: String) -> void:
	AM.ps.publish(Globals.POSE_BONE, state, bone_name)

func _on_should_use_custom_interpolation(state: bool, bone_name: String) -> void:
	var bone_id: int = model.skeleton.find_bone(bone_name)
	if bone_id < 0:
		logger.error("Bone %s not found, aborting config modification" % bone_name)
		return

	AM.ps.publish("bones_to_interpolate", bone_id if state else null, bone_name)

func _on_interpolation_rate_entered(text: String, bone_name: String) -> void:
	_on_interpolation_rate_changed(text, bone_name)

func _on_interpolation_rate_changed(text: String, bone_name: String) -> void:
	if not text.is_valid_float():
		return

	AM.ps.publish("bone_interpolation_rates", text.to_float(), bone_name)

func _on_reset_bone(bone_name: String) -> void:
	AM.ps.publish(Globals.BONE_TRANSFORMS, Transform.IDENTITY, bone_name)

#-----------------------------------------------------------------------------#
# Private functions                                                           #
#-----------------------------------------------------------------------------#

## Creates connection args specifically for bones
func _generate_connect_args(signal_name: String, bone_name: String) -> Dictionary:
	return {
		"signal_name": signal_name,
		"bone_name": bone_name
	}

func _connect_check_button(check_button: CheckButton, args = null) -> void:
	"""
	Params:
		check_button: CheckButton - The CheckButton to connect
		args: Dictionary - The args used
			- signal_name: The name of the signal
			- bone_name: The name of the bone
	"""
	var data = AM.cm.get_data(args["signal_name"])
	if data == null:
		logger.error("Unable to find config data for %s" % args["signal_name"])
		return
	
	match args.signal_name:
		"additional_bones":
			check_button.pressed = args["bone_name"] in data
			check_button.connect("toggled", self, "_on_is_tracking", [args.bone_name])
		"bones_to_interpolate":
			check_button.pressed = args["bone_name"] in data
			check_button.connect("toggled", self, "_on_should_use_custom_interpolation", [args.bone_name])
		_:
			logger.error("Unhandled signal name: %s" % args.signal_name)
			return

func _connect_line_edit(line_edit: LineEdit, args = null) -> void:
	var data = AM.cm.get_data(args["signal_name"])
	if data == null:
		logger.error("Unable to find config data for %s" % args["signal_name"])
		return
	
	match args.signal_name:
		"bone_interpolation_rates":
			line_edit.text = str(data[args["bone_name"]]) if args["bone_name"] in data else "0.0"
			line_edit.connect("text_changed", self, "_on_interpolation_rate_changed", [args.bone_name])
			line_edit.connect("text_entered", self, "_on_interpolation_rate_entered", [args.bone_name])
		_:
			logger.error("Unhandled signal name: %s" % args.signal_name)
			return

#-----------------------------------------------------------------------------#
# Public functions                                                            #
#-----------------------------------------------------------------------------#
