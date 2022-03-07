class_name AbstractManager
extends Reference

var logger: Logger

var is_setup := false

func _init() -> void:
	_setup_logger()

func _setup_logger() -> void:
	logger = Logger.new("AbstractManager")
	logger.error("Using default logger for %s" % get_script().resource_name)
