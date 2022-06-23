class_name AbstractManager
extends Reference

## The base class for all singletons managed by the AppManager.
## Uses setup functions in _init to allow for replacing of logic during automated tests

var logger: Logger

const __SELF__ := {}

## Some logic depends on the setup functions running beforehand and will spin until this is true
var is_setup := false

## Sets `is_setup` to true after running all setup funcs
##
## THIS SHOULD NOT BE OVERRIDDEN. The setup funcs should be overridden instead.
func _init() -> void:
	_setup_logger()
	_setup_class()
	_setup_singleton()
	
	is_setup = true

func _setup_logger() -> void:
	logger = Logger.new("AbstractManager")
	logger.error("Using default logger for %s" % get_script().resource_name)

func _setup_class() -> void:
	pass

## Store self into the __SELF__ dictionary using a given key
func _setup_singleton() -> void:
	pass

## Clears the __SELF__ dictionary on shutdown, otherwise the singletons are leaked
static func teardown() -> void:
	__SELF__.clear()

## Needs to be overridden by all managers that allow singleton access. The override
## functions should call this function and pass the appropriate name
static func get_singleton(singleton_name: String) -> AbstractManager:
	if singleton_name == "":
		return null
	return __SELF__.get(singleton_name, null)
