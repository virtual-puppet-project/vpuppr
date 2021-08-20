extends BaseElement

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

	var prop: Spatial = AppManager.cm.current_model_config.instanced_props[prop_name]
	for c in vbox.get_children():
		c.queue_free()

	yield(get_tree(), "idle_free")

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
					"double_toggle",
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
