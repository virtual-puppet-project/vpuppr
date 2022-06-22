extends BaseTreeLayout

# TODO this needs to be reworked

const BONE_SIGNALS := [
	"additional_bones",
	"bones_to_interpolate",
	"bone_interpolation_rates"
]

const BoneDisplay = preload("res://screens/gui/popups/bone_display.gd")

const INFO_PAGE := "Info"

var info: ScrollContainer

var model: Node

#-----------------------------------------------------------------------------#
# Builtin functions                                                           #
#-----------------------------------------------------------------------------#

func _setup() -> Result:
	info = $Info
	_set_tree($Tree)

	pages[INFO_PAGE] = info
	
	_initial_page = INFO_PAGE
	
	tree.hide_root = true
	var root: TreeItem = tree.create_item()
	
	var info_item: TreeItem = tree.create_item(root)
	info_item.set_text(TREE_COLUMN, INFO_PAGE)
	info_item.select(TREE_COLUMN)
	_toggle_page(INFO_PAGE)

	tree.connect("item_selected", self, "_on_item_selected")

	model = get_tree().current_scene.get("model")
	if model == null:
		return Result.err(Error.Code.GUI_SETUP_ERROR, "No model found, no bone functionality will be available")

	var model_skeleton = model.get("skeleton")
	if model_skeleton == null:
		printerr("No model skeleton found, no bone functionality will be available")
		return Result.err(Error.Code.GUI_SETUP_ERROR, "No model skeleton found, no bone functionality will be available")

	# Store all references to TreeItems, discard afterwards
	var known_bones := {}

	for bone_idx in model_skeleton.get_bone_count():
		var bone_name: String = model_skeleton.get_bone_name(bone_idx)
		var bone_parent_id: int = model_skeleton.get_bone_parent(bone_idx)

		var parent_item: TreeItem = root if bone_parent_id < 0 else known_bones[model_skeleton.get_bone_name(bone_parent_id)]

		var item: TreeItem = tree.create_item(parent_item)
		item.set_text(TREE_COLUMN, bone_name)

		known_bones[bone_name] = item
		
		var bone_display := BoneDisplay.new(bone_name, logger)
		pages[bone_name] = bone_display
		
		add_child(bone_display)

		_connect_element(bone_display.is_tracking_button, _generate_connect_args("additional_bones", bone_name))
		bone_display.should_pose_button.connect("toggled", self, "_on_should_pose", [bone_name])
		_connect_element(bone_display.should_use_custom_interpolation, _generate_connect_args("bones_to_interpolate", bone_name))
		_connect_element(bone_display.interpolation_rate, _generate_connect_args("bone_interpolation_rates", bone_name))
		bone_display.reset_bone.connect("pressed", self, "_on_reset_bone", [bone_name])

		for signal_name in BONE_SIGNALS:
			AM.ps.subscribe(bone_display, signal_name, {
				"args": [signal_name],
				"callback": "_on_bone_updated"
			})

		AM.ps.subscribe(bone_display, GlobalConstants.EVENT_PUBLISHED)

	return Result.ok()

#-----------------------------------------------------------------------------#
# Connections                                                                 #
#-----------------------------------------------------------------------------#

func _on_is_tracking(state: bool, bone_name: String) -> void:
	var additional_bones = AM.cm.get_data("additional_bones")
	if additional_bones == null:
		# TODO might not be an error
		return

	var bone_id: int = model.skeleton.find_bone(bone_name)
	if bone_id < 0:
		logger.error("Bone %s not found, aborting config modification" % bone_name)
		return
	
	if state:
		additional_bones[bone_name] = bone_id
	else:
		additional_bones.erase(bone_name)

	AM.ps.publish("additional_bones", additional_bones, bone_name)

func _on_should_pose(state: bool, bone_name: String) -> void:
	AM.ps.publish(GlobalConstants.POSE_BONE, state, bone_name)

func _on_should_use_custom_interpolation(state: bool, bone_name: String) -> void:
	var bones_to_interpolate = AM.cm.get_data("bones_to_interpolate")
	if bones_to_interpolate == null:
		# TODO might not be an error
		return

	var bone_id: int = model.skeleton.find_bone(bone_name)
	if bone_id < 0:
		logger.error("Bone %s not found, aborting config modification" % bone_name)
		return
	
	if state:
		bones_to_interpolate[bone_name] = bone_id
	else:
		bones_to_interpolate.erase(bone_name)

	AM.ps.publish("bones_to_interpolate", bones_to_interpolate, bone_name)

func _on_interpolation_rate_entered(text: String, bone_name: String) -> void:
	_on_interpolation_rate_changed(text, bone_name)

func _on_interpolation_rate_changed(text: String, bone_name: String) -> void:
	if not text.is_valid_float():
		return

	var rate: float = text.to_float()

	var bone_interpolation_rate_dict = AM.cm.get_data("bone_interpolation_rates")
	if bone_interpolation_rate_dict == null:
		# TODO maybe this shouldn't be an error
		return

	bone_interpolation_rate_dict[bone_name] = rate

	AM.ps.publish("bone_interpolation_rates", bone_interpolation_rate_dict, bone_name)

func _on_reset_bone(bone_name: String) -> void:
	var bone_transforms: Dictionary = AM.cm.get_data(GlobalConstants.BONE_TRANSFORMS)
	bone_transforms[bone_name] = Transform.IDENTITY

	AM.ps.publish(GlobalConstants.BONE_TRANSFORMS, bone_transforms, bone_name)

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
