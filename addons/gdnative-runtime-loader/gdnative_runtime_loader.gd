extends Reference

const Config := {
	"NAME": "config.ini",
	
	"GENERAL": "General",

	# These are technically all optional
	"SYMBOL_PREFIX": "symbol_prefix",
	"RELOADABLE": "reloadable",
	"LOAD_ONCE": "load_once",
	"SINGLETON": "singleton",
	"INIT_FUNC_NAME": "init_func_name", # Optional for sure, only define if you know what you're doing
	
	"WINDOWS64": "Windows.64",
	"WINDOWS32": "Windows.32",
	
	"X1164": "X11.64",
	"X1132": "X11.32",

	"OSX64": "OSX.64",
	"OSX32": "OSX.32",

	"LIB": "lib",
	"EXTENDS": "extends"
}

const SEARCH_SECTIONS := [
	Config.WINDOWS32,
	Config.WINDOWS64,

	Config.X1132,
	Config.X1164,

	Config.OSX32,
	Config.OSX64
]

const NATIVE_LIB_ENTRY := "entry"

const DEFAULT_PREFIX := "godot_"
const DEFAULT_SEARCH_FOLDER := "plugins"

class Library:
	const CALLING_TYPE := "standard_varcall"

	var gdnative := GDNative.new()
	var native_library := GDNativeLibrary.new()
	var native_classes := {}
	var init_func_name: String
	var init_args := []
	
	var is_initialized := false

	func _init(p_init_func_name: String) -> void:
		init_func_name = p_init_func_name

	func add_init_arg(arg) -> void:
		"""
		Adds a single argument to the GDNative init args

		If an array is passed, the entire array object will be added without destructuring it
		"""
		init_args.append(arg)

	func add_init_args(arg_array: Array) -> void:
		"""
		Takes an array of init args and adds them one by one to the GDNative init args
		"""
		for i in arg_array:
			init_args.append(i)
	
	func add_init_arg_array(arg_array: Array) -> void:
		"""
		Takes an array of init args and appends the array to the GDnative init args
		"""
		init_args.append_array(arg_array)

	func setup() -> void:
		"""
		Initializes the gdnative library using the default initialization params or the
		custom init func
		
		Calling this twice probably crashes the program
		"""
		if is_initialized:
			return
		is_initialized = true
		
		gdnative.library = native_library
		if init_func_name.empty():
			gdnative.initialize()
		else:
			gdnative.call_native(CALLING_TYPE, init_func_name, init_args)

	func cleanup() -> void:
		"""
		Terminates the gdnative library and removes all registered NativeScripts
		"""
		native_classes.clear()
		if is_initialized:
			gdnative.terminate()

	func create_class(c_name: String) -> Object:
		"""
		Creates a class. The class must be registered in the config file.
		"""
		return native_classes[c_name].new()

var libraries := {} # Library name: String -> Library
var search_path: String # The path to use when calling scan()

###############################################################################
# Builtin functions                                                           #
###############################################################################

func _init(p_search_path: String = "") -> void:
	search_path = p_search_path

	if search_path.empty():
		search_path = (
			ProjectSettings.globalize_path(
				"%s/%s" % [OS.get_executable_path().get_base_dir(), DEFAULT_SEARCH_FOLDER])
			if not OS.is_debug_build()
			else
			ProjectSettings.globalize_path("%s/%s" % ["res://", DEFAULT_SEARCH_FOLDER])
		)

func _notification(what):
	match what:
		NOTIFICATION_PREDELETE:
			for key in libraries.keys():
				libraries[key].cleanup()

###############################################################################
# Connections                                                                 #
###############################################################################

###############################################################################
# Private functions                                                           #
###############################################################################

###############################################################################
# Public functions                                                            #
###############################################################################

func scan() -> int:
	"""
	Scans the search_path for valid plugins. Attempts to fail gracefully if information is missing

	This only creates the necessary resources for initalizing a library. Actual initialization
	must be done in setup()
	"""
	var dir := Directory.new()
	
	if dir.open(search_path) != OK:
		push_error("Unable to open plugins directory at: %s" % search_path)
		return ERR_DOES_NOT_EXIST
	
	dir.list_dir_begin(true, true)
	
	var possible_folders := []
	
	var file_name: String = dir.get_next()
	while file_name != "":
		if dir.current_is_dir():
			possible_folders.append("%s/%s" % [search_path, file_name])
		
		file_name = dir.get_next()
	
	for path in possible_folders:
		if libraries.has(path.get_file()):
			push_error("Declining to process duplicate library")
			continue
		if process_folder(path) != OK:
			push_error("Error detected while processing plugins")
			continue

	return OK

func process_folder(path: String) -> int:
	"""
	Processes a folder's config file and populates the associated Library object
	"""
	# Turn the folder path into a scuffed file name
	path = path.rstrip("/")
	
	var file := File.new()
	if file.open("%s/%s" % [path, Config.NAME], File.READ) != OK:
		push_error("%s does not exist at %s/%s" % [Config.NAME, path, Config.NAME])
		return ERR_FILE_CANT_OPEN

	var config := ConfigFile.new()
	if config.parse(file.get_as_text()) != OK:
		push_error("Unable to parse config at %s/%s" % [path, Config.NAME])
		return ERR_PARSE_ERROR

	# NOTE Don't fail on a missing General section, so just use the defaults
	if not config.has_section(Config.GENERAL):
		push_warning("Missing section: %s. This isn't a good idea, but we're doing it anyways!"
				% Config.GENERAL)

	var library := Library.new(config.get_value(Config.GENERAL, Config.INIT_FUNC_NAME, ""))

	var nlib_config := ConfigFile.new()

	nlib_config.set_value(
		Config.GENERAL,
		Config.SYMBOL_PREFIX,
		config.get_value(Config.GENERAL, Config.SYMBOL_PREFIX, DEFAULT_PREFIX)
	)

	nlib_config.set_value(
		Config.GENERAL,
		Config.RELOADABLE,
		config.get_value(Config.GENERAL, Config.RELOADABLE, true)
	)

	nlib_config.set_value(
		Config.GENERAL,
		Config.LOAD_ONCE,
		config.get_value(Config.GENERAL, Config.LOAD_ONCE, true)
	)

	nlib_config.set_value(
		Config.GENERAL,
		Config.SINGLETON,
		config.get_value(Config.GENERAL, Config.SINGLETON, false)
	)

	var possible_sections := []

	for section in SEARCH_SECTIONS:
		if config.has_section(section):
			possible_sections.append(section)

	if possible_sections.empty():
		push_error("No libs defined in config file at %s/%s" % [path, Config.NAME])
		return ERR_UNCONFIGURED

	for section in possible_sections:
		if not config.has_section_key(section, Config.LIB):
			push_error("Config at %s/%s missing '%s' for section %s" %
				[path, Config.NAME, Config.LIB, section])
			continue

		nlib_config.set_value(
			NATIVE_LIB_ENTRY,
			section,
			"%s/%s" % [path, config.get_value(section, Config.LIB)]
		)
	
	# We must initialize the config like this
	# If we simply create and assign an empty config file to the native library
	# and edit it in place, the changes won't propogate to the GDNativeLibrary object
	library.native_library.config_file = nlib_config

	if library.native_library.get_current_library_path().empty():
		push_error("No valid library found for the current architecture, aborting load for %s" % path)
		return ERR_UNCONFIGURED

	# Everything else in the config is a class definition
	var classes: Array = config.get_sections()
	classes.erase(Config.GENERAL)
	for section in possible_sections:
		classes.erase(section)

	for c in classes:
		if not config.has_section_key(c, Config.EXTENDS):
			push_error("Class %s missing key '%s'" % [c, Config.EXTENDS])
			continue
		
		var nscript := NativeScript.new()
		
		nscript.set_class_name(c)
		nscript.set_script_class_name(config.get_value(c, Config.EXTENDS))
		nscript.library = library.native_library
		
		library.native_classes[c] = nscript

	libraries[path.get_file()] = library

	return OK

func setup(lib_name: String = "") -> void:
	"""
	Initializes the library(ies)
	"""
	if lib_name.empty():
		for key in libraries.keys():
			libraries[key].setup()
	else:
		libraries[lib_name].setup()

func cleanup() -> void:
	"""
	Be kind, rewind
	
	AKA terminate the libraries. This is not used during PREDELETE since the class functions
	are already cleaned up at that point for some reason.
	
	This should be used when rescanning for plugins
	"""
	for key in libraries.keys():
		libraries[key].cleanup()
	libraries.clear()

func get_library_names() -> PoolStringArray:
	"""
	Returns a PoolStringArray of all currently loaded libraries
	"""
	var r := PoolStringArray()

	for key in libraries.keys():
		r.push_back(key)

	return r

func create_class(lib_name: String, c_name: String) -> Object:
	"""
	Wrapper for creating a class from a loaded library. Checks is there is a library for the
	current platform

	Params cannot be passed because GDNative does not allow for passing params to the constructor
	"""
	var lib = libraries.get(lib_name)
	if lib == null:
		push_error("No valid library called '%s' found for the current architecture" % lib_name)
		return null
	
	return lib.create_class(c_name)

func create_class_unsafe(lib_name: String, c_name: String) -> Object:
	"""
	Wrapper for creating a class from a loaded library with no null check
	"""
	return libraries[lib_name].create_class(c_name)
