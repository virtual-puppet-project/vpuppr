extends BaseElement

onready var label: Label = $VBoxContainer/Label
onready var vbox: VBoxContainer = $VBoxContainer

var element_type: String
var data: Array = []

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
	for bone_i in model.skeleton.get_bone_count():
		var bone_name: String = model.skeleton.get_bone_name(bone_i)
		var elem: BaseElement = parent.generate_ui_element(
			element_type,
			{
				"name": bone_name,
				"event": "bone_toggled"
			}
		)
		match element_type:
			"toggle":
				if bone_name in AppManager.cm.current_model_config.mapped_bones:
					elem.toggle_value = true
			"preset":
				pass
			_:
				AppManager.log_message("Invalid element type in %s" % self.name)
		
		vbox.call_deferred("add_child", elem)
