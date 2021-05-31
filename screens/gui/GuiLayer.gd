extends CanvasLayer

const MODEL_VIEW: Resource = preload("res://screens/gui/model-view/ModelView.tscn")

const POSE_VIEW: Resource = preload("res://screens/gui/pose-view/PoseView.tscn")

const FEATURE_VIEW: Resource = preload("res://screens/gui/feature-view/FeatureView.tscn")

const PRESET_VIEW: Resource = preload("res://screens/gui/preset-view/PresetView.tscn")

const APP_SETTINGS_VIEW: Resource = preload("res://screens/gui/app-settings-view/AppSettingsView.tscn")

enum Views { NONE = 0, MODEL, POSE, FEATURES, PRESETS, APP_SETTINGS }

onready var button_bar: ButtonBar = $TopContainer/ButtonBar
onready var top_container: MarginContainer = $TopContainer
onready var bottom_container: MarginContainer = $BottomContainer

var model_view: ModelView
var pose_view: PoseView
var feature_view: FeatureView
var preset_view: PresetView
var app_settings_view: AppSettingsView

var current_view: int = Views.MODEL
var should_hide: bool = false

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

func _input(event: InputEvent) -> void:
	if event.is_action_pressed("toggle_gui"):
		should_hide = not should_hide
		if should_hide:
			for c in get_children():
				c.visible = false
		else:
			top_container.visible = true
			bottom_container.visible = true
			_toggle_view(current_view)

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

	for i in [model_view, pose_view, feature_view]:
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
			pose_view.visible = not pose_view.visible
		Views.FEATURES:
			feature_view.visible = not feature_view.visible
		Views.PRESETS:
			preset_view.visible = not preset_view.visible
		Views.APP_SETTINGS:
			app_settings_view.visible = not app_settings_view.visible
		_:
			AppManager.log_message("Unhandled view in GuiLayer %s" % view)

func _construct_views() -> void:
	model_view = MODEL_VIEW.instance()
	call_deferred("add_child", model_view)
	
	pose_view = POSE_VIEW.instance()
	pose_view.visible = false
	call_deferred("add_child", pose_view)
	
	feature_view = FEATURE_VIEW.instance()
	feature_view.visible = false
	call_deferred("add_child", feature_view)
	
	preset_view = PRESET_VIEW.instance()
	preset_view.visible = false
	call_deferred("add_child", preset_view)
	
	app_settings_view = APP_SETTINGS_VIEW.instance()
	app_settings_view.visible = false
	call_deferred("add_child", app_settings_view)

###############################################################################
# Public functions                                                            #
###############################################################################

func apply_properties() -> void:
	_on_properties_applied()
