extends BasePopupTreeLayout

const BONE_SIGNALS := [
	"additional_bones",
	"bones_to_interpolate",
	"bone_interpolation_rates"
]

const BoneDisplay = preload("res://screens/gui/popups/bone_display.gd")

const INFO_PAGE := "Info"

var info: ScrollContainer

var model: Node

###############################################################################
# Builtin functions                                                           #
###############################################################################

func _setup() -> void:
	info = $Info
	
	_initial_page = INFO_PAGE
	
	tree.hide_root = true
	var root: TreeItem = tree.create_item()
	
	pages[INFO_PAGE] = info
	
	var info_item: TreeItem = tree.create_item(root)
	info_item.set_text(TREE_COLUMN, INFO_PAGE)
	info_item.select(TREE_COLUMN)
	_toggle_page(INFO_PAGE)

	tree.connect("item_selected", self, "_on_item_selected")

	model = get_tree().current_scene.get("model")
	if model == null:
		printerr("No model found, no bone functionality will be available")
		return

	var model_skeleton = model.get("skeleton")
	if model_skeleton == null:
		printerr("No model skeleton found, no bone functionality will be available")
		return

	# Store all references to TreeItems, discard afterwards
	var known_bones := {}

	for bone_idx in model_skeleton.get_bone_count():
		var bone_name: String = model_skeleton.get_bone_name(bone_idx)
		var bone_parent_id: int = model_skeleton.get_bone_parent(bone_idx)

		var parent_item: TreeItem = root if bone_parent_id < 0 else known_bones[model_skeleton.get_bone_name(bone_parent_id)]

		var item: TreeItem = tree.create_item(parent_item)
		item.set_text(TREE_COLUMN, bone_name)

		known_bones[bone_name] = item
		
		var bone_page := BoneDisplay.new(bone_name)
		pages[bone_name] = bone_page
		
		add_child(bone_page)

		_connect_element(bone_page.is_tracking_button, _generate_connect_args("additional_bones", bone_name))
		# _connect_element(bone_page.should_pose_button)
		bone_page.should_pose_button.connect("toggled", self, "_on_should_pose")
		_connect_element(bone_page.should_use_custom_interpolation, _generate_connect_args("bones_to_interpolate", bone_name))
		_connect_element(bone_page.interpolation_rate, _generate_connect_args("bone_interpolation_rates", bone_name))

		# TODO this is bad and will not work
		"""
		What I need to do is process dictionaries differently
		
		When changing a value that is stored as a collection, that value must be wrapped in an outer Dictionary
		that contains information about the specific bone stuff
		"""
		for signal_name in BONE_SIGNALS:
			AM.ps.register(bone_page, signal_name, PubSubPayload.new({
				"args": [signal_name, bone_name],
				"callback": "_on_bone_updated"
			}))

###############################################################################
# Connections                                                                 #
###############################################################################

func _on_bone_updated(value, control: Control, bone_name: String) -> void:
	"""
	Value can possibly be a collection, so we need to account for that
	"""
	
	match control.get_class():
		"Button":
			logger.debug("_on_config_updated for Button not yet implemented")
		"CheckButton":

			control.pressed = bool(value)
		"LineEdit":
			control.text = str(value)

# func _on_config_updated(value, control: Control) -> void:
# 	match control.get_class():
# 		"Button":
# 			logger.debug("_on_config_updated for Button not yet implemented")
# 		"CheckButton":
# 			control.pressed = bool(value)
# 		"LineEdit":
# 			control.text = str(value)

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
		additional_bones[bone_name].erase(bone_id)

	AM.ps.emit_signal("additional_bones", additional_bones)

func _on_should_pose(state: bool, bone_name: String) -> void:
	# TODO nothing needs to be set in model config from here, only after posing
	pass

func _on_should_use_custom_interpolation(state: bool, bone_name: String) -> void:
	var bones_to_interpolate = AM.cm.get_data("bones_to_interpolate")
	if bones_to_interpolate == null:
		# TODO might not be an error
		return

	var bone_id: int = model.skeleton.find_bone(bone_name)
	if bone_id < 0:
		logger.error("Bone %s not found, aborting config modification" % bone_name)
		return
	
	if state and not bones_to_interpolate.has(bone_id):
		bones_to_interpolate.append(bone_id)
	else:
		bones_to_interpolate.erase(bone_id)

	AM.ps.emit_signal("bones_to_interpolate", bones_to_interpolate)

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

	AM.ps.emit_signal("bone_interpolation_rates", bone_interpolation_rate_dict)

###############################################################################
# Private functions                                                           #
###############################################################################

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
			- signal: The name of the signal
			- bone: The name of the bone
	"""
	match args.signal_name:
		"additional_bones":
			check_button.connect("toggled", self, "_on_is_tracking", [args.bone_name])
		"bones_to_interpolate":
			check_button.connect("toggled", self, "_on_should_use_custom_interpolation", [args.bone_name])
		_:
			logger.error("Unhandled signal name: %s" % args.signal_name)
			return

	# AM.ps.register(self, args.signal_name, PubSubPayload.new({
	# 	"args": [check_button, args.bone_name],
	# 	"callback": "_on_bone_updated"
	# }))

func _connect_line_edit(line_edit: LineEdit, args = null) -> void:
	match args.signal_name:
		"bone_interpolation_rates":
			line_edit.connect("text_changed", self, "_on_line_edit_text_changed", [args.bone_name])
			line_edit.connect("text_entered", self, "_on_line_edit_text_entered", [args.bone_name])
		_:
			logger.error("Unhandled signal name: %s" % args.signal_name)
			return

	# AM.ps.register(self, args.signal_name, PubSubPayload.new({
	# 	"args": [line_edit, args.bone_name],
	# 	"callback": "_on_bone_updated"
	# }))

###############################################################################
# Public functions                                                            #
###############################################################################
