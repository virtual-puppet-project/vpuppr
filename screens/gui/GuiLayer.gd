extends CanvasLayer

const MODEL_VIEW: Resource = preload("res://screens/gui/ModelView.tscn")
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

var model_view: ModelView
# var model_view_left: BaseSidebar
# var model_view_right: BaseSidebar

var pose_view_left: BaseSidebar
var pose_view_right: BaseSidebar

var feature_view_left: BaseSidebar
var feature_view_right: BaseSidebar

var preset_view_left: BaseSidebar
var preset_view_right: BaseSidebar

var app_settings_view_left: BaseSidebar
var app_settings_view_right: BaseSidebar

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

	yield(AppManager, "model_loaded")
	
	_construct_views()
	model_view = MODEL_VIEW.instance()
	call_deferred("add_child", model_view)

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

	for i in [model_view, pose_view_left, pose_view_right,
			feature_view_left, feature_view_right, preset_view_left, preset_view_right,
			app_settings_view_left, app_settings_view_right]:
		AppManager.update_config(i.name, i.save())

	AppManager.save_config()

###############################################################################
# Private functions                                                           #
###############################################################################

func _switch_view_to(view: int) -> void:
	if view == current_view:
		_toggle_view(view)
		current_view = Views.NONE
		return
	_toggle_view(current_view)
	_toggle_view(view)
	current_view = view

# TODO remove view from scene tree instead of just hiding it for better performance
func _toggle_view(view: int) -> void:
	match view:
		Views.NONE:
			pass
		Views.MODEL:
			model_view.visible = not model_view.visible
		Views.POSE:
			pose_view_left.visible = not pose_view_left.visible
			pose_view_right.visible = not pose_view_right.visible
		Views.FEATURES:
			feature_view_left.visible = not feature_view_left.visible
			feature_view_right.visible = not feature_view_right.visible
		Views.PRESETS:
			preset_view_left.visible = not preset_view_left.visible
			preset_view_right.visible = not preset_view_right.visible
		Views.APP_SETTINGS:
			app_settings_view_left.visible = not app_settings_view_left.visible
			app_settings_view_right.visible = not app_settings_view_right.visible
		_:
			AppManager.log_message("Unhandled view in GuiLayer %s" % view)

func _construct_views() -> void:
	# TODO removed Views.MODEL for testing
	for i in [Views.POSE, Views.FEATURES, Views.PRESETS, Views.APP_SETTINGS]:
		var new_left_content: Control
		var new_right_content: Control
		
		match i:
#			Views.MODEL:
#				model_view_left = MODEL_VIEW_LEFT.instance()
#				model_view_right = MODEL_VIEW_RIGHT.instance()
#				new_left_content = model_view_left
#				new_right_content = model_view_right
			Views.POSE:
				pose_view_left = POSE_VIEW_LEFT.instance()
				pose_view_right = POSE_VIEW_RIGHT.instance()
				new_left_content = pose_view_left
				new_right_content = pose_view_right
			Views.FEATURES:
				feature_view_left = FEATURE_VIEW_LEFT.instance()
				feature_view_right = FEATURE_VIEW_RIGHT.instance()
				# Connect the right view to the left view to change children on item selected
				new_left_content = feature_view_left
				new_right_content = feature_view_right
				# TODO this is a circular reference with more steps
				new_left_content.feature_view_right = weakref(new_right_content)
				new_right_content.feature_view_left = weakref(new_left_content)
			Views.PRESETS:
				preset_view_left = PRESET_VIEW_LEFT.instance()
				preset_view_right = PRESET_VIEW_RIGHT.instance()
				new_left_content = preset_view_left
				new_right_content = preset_view_right
			Views.APP_SETTINGS:
				app_settings_view_left = APP_SETTINGS_VIEW_LEFT.instance()
				app_settings_view_right = APP_SETTINGS_VIEW_RIGHT.instance()
				new_left_content = app_settings_view_left
				new_right_content = app_settings_view_right
		
		if i != Views.MODEL:
			new_left_content.visible = false
			new_right_content.visible = false
		
		left_container.add_child(new_left_content)
		right_container.add_child(new_right_content)

		yield(get_tree(), "idle_frame")

###############################################################################
# Public functions                                                            #
###############################################################################


