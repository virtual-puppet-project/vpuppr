extends BaseElement

onready var label: Label = $VBoxContainer/Label
onready var vbox: VBoxContainer = $VBoxContainer

var element_type: String
var element: Resource
var data: Array = []

###############################################################################
# Builtin functions                                                           #
###############################################################################

func _ready() -> void:
	label.text = label_text
	for datum in data:
		var elem: BaseElement = element.instance()
		match element_type:
			"toggle":
				elem.label_text = datum.text
			"preset":
				pass
			_:
				AppManager.log_message("Invalid element type in %s" % self.name)

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
