extends BaseTreeLayout

#-----------------------------------------------------------------------------#
# Builtin functions                                                           #
#-----------------------------------------------------------------------------#

func _setup_logger() -> void:
	logger = Logger.new(self)

func _setup() -> Result:
	_initial_page = "General"
	
	#region General
	
	_connect_element($General/VBoxContainer/SkipSplashScreen, "skip_splash")
	
	#endregion
	
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

	return ._setup()

#-----------------------------------------------------------------------------#
# Connections                                                                 #
#-----------------------------------------------------------------------------#

func _on_check_button_toggled(state: bool, signal_name: String, _check_button: CheckButton) -> void:
	AM.ps.publish(signal_name, state)

#-----------------------------------------------------------------------------#
# Private functions                                                           #
#-----------------------------------------------------------------------------#

#-----------------------------------------------------------------------------#
# Public functions                                                            #
#-----------------------------------------------------------------------------#
