class_name Context
extends Node

## The context that a runner will be running in.

signal loading_completed(success: bool)

## The [RunnerData] the [Context] is using.
var runner_data: RunnerData = null
## The runner for the [Context].
var runner: Node = null
## The gui for the [Context].
var gui: Node = null
## The model for the [Context].
var model: Node = null

var active_trackers: Array[AbstractTracker] = []

var _logger := Logger.create("Context")

#-----------------------------------------------------------------------------#
# Builtin functions
#-----------------------------------------------------------------------------#

func _init(p_runner_data: RunnerData) -> void:
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
				
				var model: Node = gltf.generate_scene(state)
				if model == null:
					_logger.error("Failed to generate scene for model {0}".format([model_path]))
					return r
				
				# TODO name changed
				var puppet := GLBPuppet.new()
				puppet.name = model_path.get_file()
				puppet.puppet_data = runner_data.puppet_data
				puppet.add_child(model)
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
				var model: Node = gltf.generate_scene(state)
				if model == null:
					_logger.error("Failed to generate scene for model {0}".format([model_path]))
					return r
				
				_logger.debug("VRMPuppet")
				var puppet := VRMPuppet.new()
				puppet.name = model_path.get_file()
				puppet.puppet_data = runner_data.puppet_data
				puppet.add_child(model)
				
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
	runner.set("context", self)
	gui.set("context", self)
	
	add_child(runner)
	add_child(gui)
	
	_logger.info("Completed loading")
	
	loading_completed.emit(true)

func _exit_tree() -> void:
	if runner_data.try_save() != OK:
		_logger.error("Unable to save runner data")

#-----------------------------------------------------------------------------#
# Private functions
#-----------------------------------------------------------------------------#

#-----------------------------------------------------------------------------#
# Public functions
#-----------------------------------------------------------------------------#

func start_tracker(tracker: AbstractTracker.Trackers, data: Dictionary) -> AbstractTracker:
	_logger.info("Starting tracker: {0}".format([tracker]))

	match tracker:
		AbstractTracker.Trackers.MEOW_FACE:
			var mf := MeowFace.start(data)
			if mf == null:
				_logger.error("Unable to start MeowFace")
				return null
			
			mf.data_received.connect(model.handle_meow_face)
			active_trackers.push_back(mf)

			return mf
		AbstractTracker.Trackers.MEDIA_PIPE:
			var mp = MediaPipe.start(data)
			if mp == null:
				_logger.error("Unable to start MediaPipe")
				return null

			mp.data_received.connect(model.handle_media_pipe)
			active_trackers.push_back(mp)

			return mp
		AbstractTracker.Trackers.I_FACIAL_MOCAP:
			var ifm := IFacialMocap.start(data)
			if ifm == null:
				_logger.error("Unable to start iFacialMocap")
				return

			ifm.data_received.connect(model.handle_ifacial_mocap)
			active_trackers.push_back(ifm)

			return ifm
		_:
			_logger.error("Unhandled tracker: {0}".format([tracker]))
			
			return null
