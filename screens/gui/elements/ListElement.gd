extends BaseElement

onready var label: Label = $VBoxContainer/Label
onready var vbox: VBoxContainer = $VBoxContainer

var data_mapping: String

###############################################################################
# Builtin functions                                                           #
###############################################################################

func _ready() -> void:
	label.text = label_text

###############################################################################
# Connections                                                                 #
###############################################################################

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

func setup(parent: Node, model: BasicModel) -> void:
	match data_mapping:
		"mapped_bones":
			for bone_i in model.skeleton.get_bone_count():
				var bone_name: String = model.skeleton.get_bone_name(bone_i)
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
