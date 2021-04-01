extends CanvasLayer

const MODEL_VIEW_LEFT: Resource = preload("res://screens/gui/ModelViewLeft.tscn")
const MODEL_VIEW_RIGHT: Resource = preload("res://screens/gui/ModelViewRight.tscn")

const POSE_VIEW_LEFT: Resource = preload("res://screens/gui/PoseViewLeft.tscn")
const POSE_VIEW_RIGHT: Resource = preload("res://screens/gui/PoseViewRight.tscn")

const FEATURE_VIEW_LEFT: Resource = preload("res://screens/gui/FeatureViewLeft.tscn")
const FEATURE_VIEW_RIGHT: Resource = preload("res://screens/gui/FeatureViewRight.tscn")

const PRESET_VIEW_LEFT: Resource = preload("res://screens/gui/PresetViewLeft.tscn")
const PRESET_VIEW_RIGHT: Resource = preload("res://screens/gui/PresetViewRight.tscn")

const APP_SETTINGS_VIEW_LEFT: Resource = preload("res://screens/gui/AppSettingsViewLeft.tscn")
const APP_SETTINGS_VIEW_RIGHT: Resource = preload("res://screens/gui/AppSettingsViewRight.tscn")

enum Views { NONE = 0, MODEL, POSE, FEATURES, PRESETS, APP_SETTINGS }

onready var button_bar: ButtonBar = $TopContainer/ButtonBar
onready var left_container: MarginContainer = $LeftContainer
onready var right_container: MarginContainer = $RightContainer

var current_view: int = Views.MODEL

###############################################################################
# Builtin functions                                                           #
###############################################################################

func _ready() -> void:
	button_bar.model_button.connect("pressed", self, "_on_model_button_pressed")
	button_bar.pose_button.connect("pressed", self, "_on_pose_button_pressed")
	button_bar.features_button.connect("pressed", self, "_on_features_button_pressed")
	button_bar.presets_button.connect("pressed", self, "_on_presets_button_pressed")
	button_bar.app_settings_button.connect("pressed", self, "_on_app_settings_button_pressed")

	AppManager.connect("properties_applied", self, "_on_properties_applied")

func _input(event: InputEvent) -> void:
	if event.is_action_pressed("toggle_gui"):
		for c in get_children():
			c.visible = not c.visible

###############################################################################
# Connections                                                                 #
###############################################################################

func _on_model_button_pressed() -> void:
	_switch_view_to(Views.MODEL)

func _on_pose_button_pressed() -> void:
	_switch_view_to(Views.POSE)

func _on_features_button_pressed() -> void:
	_switch_view_to(Views.FEATURES)

func _on_presets_button_pressed() -> void:
	_switch_view_to(Views.PRESETS)

func _on_app_settings_button_pressed() -> void:
	_switch_view_to(Views.APP_SETTINGS)

func _on_properties_applied() -> void:
	# Wait for sidebars to update
	yield(get_tree(), "idle_frame")
	for c in [left_container, right_container]:
		AppManager.update_config(c.get_child(0).name, c.get_child(0).save())

	AppManager.save_config()

###############################################################################
# Private functions                                                           #
###############################################################################

func _switch_view_to(view: int) -> void:
	if view == current_view:
		return
	current_view = view
	
	var new_left_content: Control
	var new_right_content: Control
	
	match view:
		Views.MODEL:
			new_left_content = MODEL_VIEW_LEFT.instance()
			new_right_content = MODEL_VIEW_RIGHT.instance()
		Views.POSE:
			new_left_content = POSE_VIEW_LEFT.instance()
			new_right_content = POSE_VIEW_RIGHT.instance()
		Views.FEATURES:
			# Connect the right view to the left view to change children on item selected
			new_left_content = FEATURE_VIEW_LEFT.instance()
			new_right_content = FEATURE_VIEW_RIGHT.instance()
			# TODO this is a circular reference with more steps
			new_left_content.feature_view_right = weakref(new_right_content)
			new_right_content.feature_view_left = weakref(new_left_content)
			# new_left_content.connect("element_selected", new_right_content, "_on_element_selected")
		Views.PRESETS:
			new_left_content = PRESET_VIEW_LEFT.instance()
			new_right_content = PRESET_VIEW_RIGHT.instance()
		Views.APP_SETTINGS:
			new_left_content = APP_SETTINGS_VIEW_LEFT.instance()
			new_right_content = APP_SETTINGS_VIEW_RIGHT.instance()
		_:
			push_error("Unhandled view in in GuiLayer")
	
	for i in [left_container, right_container]:
		for j in i.get_children():
			j.free()
	
	left_container.add_child(new_left_content)
	right_container.add_child(new_right_content)

###############################################################################
# Public functions                                                            #
###############################################################################


