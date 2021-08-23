extends BaseElement

const PropData: Resource = preload("res://screens/gui/PropData.gd")

onready var label: Label = $VBoxContainer/Label
onready var vbox: VBoxContainer = $VBoxContainer

###############################################################################
# Builtin functions                                                           #
###############################################################################

func _ready() -> void:
	label.text = label_text

###############################################################################
# Connections                                                                 #
###############################################################################

func _load_prop_information(prop_name: String) -> void:
	if not AppManager.cm.current_model_config.instanced_props.has(prop_name):
		return

	var data: Dictionary = AppManager.cm.current_model_config.instanced_props[prop_name]
	for c in vbox.get_children():
		c.queue_free()

	yield(get_tree(), "idle_frame")

	var name_elem: BaseElement = parent.generate_ui_element(parent.XmlConstants.LABEL, {
		"name": data["name"]
	})
	vbox.call_deferred("add_child", name_elem)

	var move_elem: BaseElement = parent.generate_ui_element(parent.XmlConstants.TOGGLE, {
		"name": "Move",
		"event": "move_prop"
	})

	var rotate_elem: BaseElement = parent.generate_ui_element(parent.XmlConstants.TOGGLE, {
		"name": "Move",
		"event": "rotate_prop"
	})

	var zoom_elem: BaseElement = parent.generate_ui_element(parent.XmlConstants.TOGGLE, {
		"name": "Move",
		"event": "zoom_prop"
	})

###############################################################################
# Private functions                                                           #
###############################################################################

###############################################################################
# Public functions                                                            #
###############################################################################

func get_value():
	return vbox.get_children()

func set_value(_value) -> void:
	AppManager.log_message("Tried to set value on a List element", true)

# Override base setup() function
func setup() -> void:
	match data_bind:
		"mapped_bones":
			for bone_i in parent.model.skeleton.get_bone_count():
				var bone_name: String = parent.model.skeleton.get_bone_name(bone_i)
				var elem: BaseElement = parent.generate_ui_element(
					parent.XmlConstants.DOUBLE_TOGGLE,
					{
						"name": bone_name,
						"event": "bone_toggled"
					}
				)
				elem.toggle1_label = parent.DoubleToggleConstants.TRACK
				if bone_name in AppManager.cm.current_model_config.mapped_bones:
					elem.toggle1_value = true

				elem.toggle2_label = parent.DoubleToggleConstants.POSE

				elem.connect("event", parent, "_on_event")
				AppManager.sb.connect("bone_toggled", elem, "_on_bone_toggled")
				
				vbox.call_deferred("add_child", elem)
		"instanced_props":
			for prop_name in AppManager.cm.current_model_config.instanced_props.keys():
				var prop_data = PropData.new()
				prop_data.load_from_dict(
					AppManager.cm.current_model_config.instanced_props[prop_name]
				)

				prop_data.prop = parent.create_prop(
					prop_data.prop_path,
					prop_data.parent_transform,
					prop_data.child_transform
				)

				# TODO generate toggle
				prop_data.toggle = parent.generate_ui_element(
					parent.XmlConstants.TOGGLE,
					{
						"name": "",
						"event": "prop_toggled"
					}
				)
				
				AppManager.main.model_display_screen.call_deferred("add_child", prop_data.prop)
				vbox.call_deferred("add_child", prop_data.toggle)

				parent.instanced_props[prop_name] = prop_data

