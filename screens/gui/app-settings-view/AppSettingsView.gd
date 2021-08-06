class_name AppSettingsView
extends BaseView

###############################################################################
# Builtin functions                                                           #
###############################################################################

func _ready() -> void:
	_setup()

###############################################################################
# Connections                                                                 #
###############################################################################

func _on_apply_button_pressed() -> void:
	_apply_properties()

func _on_reset_button_pressed() -> void:
	pass

###############################################################################
# Private functions                                                           #
###############################################################################

func _setup_left(config: Dictionary) -> void:
	left_container.add_to_inner(_create_element(ElementType.LABEL, "QOL", "QOL"))

	var default_load_path = "/"
	var should_track_eye = true
	default_load_path = AppManager.cm.metadata_config.default_search_path
	should_track_eye = config.should_track_eye.value

	AppManager.default_load_path = default_load_path
	AppManager.should_track_eye = should_track_eye
	left_container.add_to_inner(_create_element(ElementType.INPUT, "default_load_path",
			"Default load path", default_load_path, TYPE_STRING))
	left_container.add_to_inner(_create_element(ElementType.CHECK_BOX,
			"should_track_eye", "Should track eye", should_track_eye))

func _setup_right(config: Dictionary) -> void:
	pass

func _apply_properties() -> void:
	for c in left_container.get_inner_children():
		if c is CenteredLabel:
			continue
		match c.name:
			"default_load_path":
				AppManager.default_load_path = c.get_value()
			"should_track_eye":
				if c.get_value():
					AppManager.should_track_eye = 1.0
				else:
					AppManager.should_track_eye = 0.0

###############################################################################
# Public functions                                                            #
###############################################################################

func save() -> void:
	for c in left_container.get_inner_children():
		if c is CenteredLabel:
			continue
		elif c.name == "default_load_path":
			AppManager.cm.metadata_config.default_search_path = c.get_value()
		elif c.name == "should_track_eye":
			AppManager.cm.current_model_config.should_track_eye = c.get_value()

