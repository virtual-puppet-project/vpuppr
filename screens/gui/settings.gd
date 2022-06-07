extends BaseTreeLayout

#-----------------------------------------------------------------------------#
# Builtin functions                                                           #
#-----------------------------------------------------------------------------#

func _pre_setup() -> void:
	logger = Logger.new(self)
	_initial_page = "General"

func _setup() -> void:
	#region Rendering

	_connect_element($Rendering/VBoxContainer/TransparentBackground, "use_transparent_background")
	_connect_element($Rendering/VBoxContainer/UseFxaa, "use_fxaa")

	#endregion

	#region Linux

	if not OS.get_name().to_lower() in ["x11", "osx"]:
		$Linux.free()
	else:
		_connect_element($Linux/VBoxContainer/PythonPath/LineEdit, "python_path")

	#endregion

	._setup()

#-----------------------------------------------------------------------------#
# Connections                                                                 #
#-----------------------------------------------------------------------------#

func _on_check_button_toggled(state: bool, signal_name: String, _check_button: CheckButton) -> void:
	AM.ps.emit_signal(signal_name, state)

#-----------------------------------------------------------------------------#
# Private functions                                                           #
#-----------------------------------------------------------------------------#

#-----------------------------------------------------------------------------#
# Public functions                                                            #
#-----------------------------------------------------------------------------#
