class_name AbstractManager
extends Reference

## The base class for all singletons managed by the AppManager.
## Uses setup functions in _init to allow for replacing of logic during automated tests

var logger: Logger

## THIS SHOULD NOT BE OVERRIDDEN. The setup funcs should be overridden instead.
func _init() -> void:
	_setup_logger()
	_setup_class()

func _setup_logger() -> void:
	logger = Logger.new("AbstractManager")
	logger.error("Using default logger for %s" % get_script().resource_name)

func _setup_class() -> void:
	pass
