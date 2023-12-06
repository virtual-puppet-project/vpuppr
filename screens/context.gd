class_name Context
extends Node

## The context that a runner will be running in.

signal loading_completed(success: bool)

const NAME := &"Context"

## The [RunnerData] the [Context] is using.
var runner_data: RunnerData = null
## The runner for the [Context].
var runner: Node = null
## The gui for the [Context].
var gui: Node = null
## The model for the [Context].
var model: Node = null

var active_trackers := {}

var _logger := Logger.create(String(NAME))

#-----------------------------------------------------------------------------#
# Builtin functions
#-----------------------------------------------------------------------------#

func _init(p_runner_data: RunnerData) -> void:
	name = NAME
	var fail := func(text: String) -> void:
		_logger.error(text)
		loading_completed.emit(false)
	
	if p_runner_data == null:
		fail.call("No runner data received, bailing out!")
		return
	
	runner_data = p_runner_data
	
	const RUNNER := "runner"
	const GUI := "gui"
	const MODEL := "model"
	
	var r := {
		RUNNER = null,
		GUI = null,
		MODEL = null
	}
	
	var loading_thread := Thread.new()
	loading_thread.start(func() -> Dictionary:
		var try_load := func(path: String) -> Variant:
			var res: Resource = load(path)
			if res == null:
				_logger.error("Unable to load resource {0}".format([path]))
				return null
			
			return res.new() if res is GDScript else res.instantiate()
		
		_logger.debug("runner")
		r.runner = try_load.call(runner_data.runner_path)
		_logger.debug("gui")
		r.gui = try_load.call(runner_data.gui_path)
		
		var model_path := runner_data.model_path
		# TODO glb/vrm load logic can probably be consolidated
		match model_path.get_extension().to_lower():
			"glb":
				_logger.info("Loading glb")
				
				var gltf := GLTFDocument.new()
				var state := GLTFState.new()
				
				var err := gltf.append_from_file(model_path, state)
				if err != OK:
					_logger.error("Unable to load model from path {0}".format([model_path]))
					return r
				
				var loaded_model: Node = gltf.generate_scene(state)
				if loaded_model == null:
					_logger.error("Failed to generate scene for model {0}".format([model_path]))
					return r
				
				# TODO name changed
				var puppet := GLBPuppet.new()
				puppet.name = model_path.get_file()
				puppet.puppet_data = runner_data.puppet_data
				puppet.add_child(loaded_model)
#
				r.model = puppet
			"vrm":
				_logger.info("Loading vrm")
				
				var gltf := GLTFDocument.new()
				var state := GLTFState.new()
				
				_logger.debug("append from file")
				var err := gltf.append_from_file(model_path, state)
				if err != OK:
					_logger.error("Unable to load model from path {0}".format([model_path]))
					return r
				
				_logger.debug("generate scene")
				var loaded_model: Node = gltf.generate_scene(state)
				if loaded_model == null:
					_logger.error("Failed to generate scene for model {0}".format([model_path]))
					return r
				
				_logger.debug("VRMPuppet")
				var puppet := VRMPuppet.new()
				puppet.name = model_path.get_file()
				puppet.puppet_data = runner_data.puppet_data
				puppet.add_child(loaded_model)
				
				r.model = puppet
				
				_logger.info("Loaded vrm")
			"png":
				_logger.debug("Loading png")
				# TODO stub
				pass
			_:
				_logger.error("Unhandled file type for model {0}".format([model_path]))
				return r
		
		return r
	)
	
	var st: SceneTree = Engine.get_main_loop()
	while loading_thread.is_alive():
		await st.process_frame
	
	var load_results: Dictionary = loading_thread.wait_to_finish()
	
	runner = load_results.get(RUNNER, null)
	if runner == null:
		fail.call("Failed to load runner {0}".format([runner_data.runner_path]))
		return
	
	gui = load_results.get(GUI, null)
	if gui == null:
		fail.call("Failed to load gui from {0}".format([runner_data.gui_path]))
		return
	
	model = load_results.get(MODEL, null)
	if model == null:
		fail.call("Failed to load model from {0}".format([runner_data.model_path]))
		return
	
	runner.add_child(model)
	gui.set("context", self)
	
	add_child(runner)
	add_child(gui)
	
	_logger.info("Completed loading")
	
	loading_completed.emit(true)

func _ready() -> void:
	if Context.singleton() == null:
		_logger.error("An error occurred while verifying Context singleton, bailing out")
		get_tree().change_scene_to_file("res://screens/home/home.tscn")
	
	model.update_from_config(runner_data.puppet_data)
	runner.update_from_config(runner_data)
	
	_logger.debug("Ready!")

func _exit_tree() -> void:
	if runner_data.try_save() != OK:
		_logger.error("Unable to save runner data")

#-----------------------------------------------------------------------------#
# Private functions
#-----------------------------------------------------------------------------#

#-----------------------------------------------------------------------------#
# Public functions
#-----------------------------------------------------------------------------#

static func singleton() -> Context:
	var found_contexts := []
	for child in Engine.get_main_loop().root.get_children():
		if child is Context:
			found_contexts.push_back(child)
	
	if found_contexts.size() < 1:
		printerr("No Contexts were found while trying to get singleton")
		return null
	if found_contexts.size() > 1:
		printerr("Too many Contexts were found while trying to get singleton, this is a major bug!")
		return null
	
	return found_contexts.pop_back()

func start_tracker(tracker: AbstractTracker.Trackers) -> Error:
	var tracker_name: String = AbstractTracker.Trackers.keys()[tracker]
	
	_logger.info("Starting tracker: {tracker}".format({tracker = tracker_name}))
	
	if active_trackers.has(tracker):
		_logger.error("Tried starting tracker {tracker}, but it was already running".format({
			tracker = tracker_name
		}))

	var tracker_instance: AbstractTracker = null
	match tracker:
		AbstractTracker.Trackers.MEOW_FACE:
			tracker_instance = MeowFace.start(runner_data.common_options.meow_face_options)
			if tracker_instance == null:
				_logger.error("Unable to start MeowFace")
				return ERR_CANT_CREATE
			
			tracker_instance.data_received.connect(model.handle_meow_face)
		AbstractTracker.Trackers.VTUBE_STUDIO:
			tracker_instance = VTubeStudio.start(runner_data.common_options.vtube_studio_options)
			if tracker_instance == null:
				_logger.error("Unable to start VTubeStudio")
				return ERR_CANT_CREATE
			
			tracker_instance.data_received.connect(model.handle_vtube_studio)
		AbstractTracker.Trackers.MEDIA_PIPE:
			tracker_instance = MediaPipe.start(runner_data.common_options.mediapipe_options)
			if tracker_instance == null:
				_logger.error("Unable to start MediaPipe")
				return ERR_CANT_CREATE

			tracker_instance.data_received.connect(model.handle_mediapipe)
		AbstractTracker.Trackers.I_FACIAL_MOCAP:
			tracker_instance = IFacialMocap.start(runner_data.common_options.ifacial_mocap_options)
			if tracker_instance == null:
				_logger.error("Unable to start iFacialMocap")
				return ERR_CANT_CREATE

			tracker_instance.data_received.connect(model.handle_ifacial_mocap)
		_:
			_logger.error("Unhandled tracker: {0}".format([tracker]))
			
			return ERR_UNCONFIGURED
	
	active_trackers[tracker] = tracker_instance
	
	return OK

func stop_tracker(tracker: AbstractTracker.Trackers) -> Error:
	var tracker_name: String = AbstractTracker.Trackers.keys()[tracker]
	
	_logger.info("Stopping tracker: {tracker}".format({tracker = tracker_name}))
	
	var tracker_instance: AbstractTracker = active_trackers.get(tracker, null)
	if tracker_instance == null:
		_logger.error("Tracker {tracker} was not running".format({tracker = tracker_name}))
		return ERR_DOES_NOT_EXIST
	
	if tracker_instance.stop() != OK:
		_logger.error("Failed to stop {tracker}, there might be a memory leak".format({
			tracker = tracker_name
		}))
	active_trackers.erase(tracker)
	
	return OK
