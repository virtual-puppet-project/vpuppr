extends "res://addons/gut/test.gd"

func before_all():
	AppManager.env = "tests"
	AppManager.cm = ConfigManager.new()
	AppManager.cm.current_model_config = ConfigManager.ConfigData.new()
	gut.p("ran run setup", 2)
