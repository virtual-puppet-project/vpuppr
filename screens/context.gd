class_name Context
extends Node

## The context that a runner will be running in.

signal loading_completed()

## The [RunnerData] the [Context] is using.
var runner_data: RunnerData = null
## The runner for the [Context].
var runner: Node = null
## The gui for the [Context].
var gui: Node = null
## The model for the [Context].
var model: Node = null

var active_trackers: Array[AbstractTracker] = []

#-----------------------------------------------------------------------------#
# Builtin functions
#-----------------------------------------------------------------------------#

func _init(p_runner_data: RunnerData) -> void:
	var logger := Logger.create("Context:_init")
	
	var fail := func(text: String) -> void:
		logger.error(text)
		loading_completed.emit()
	
	if p_runner_data == null:
		fail.call("No runner data received, bailing out!")
		return
	
	runner_data = p_runner_data
	
	const RUNNER := "runner"
	const GUI := "gui"
	const MODEL := "model"
	
	var loading_thread := Thread.new()
	loading_thread.start(func() -> Dictionary:
		var r := {
			RUNNER = null,
			GUI = null,
			MODEL = null
		}
		
		var try_load := func(path: String) -> Variant:
			var res: Resource = load(path)
			if res == null:
				logger.error("Unable to load resource {0}".format([path]))
				return null
			
			return res.new() if res is GDScript else res.instantiate()
		
		r.runner = try_load.call(runner_data.get_runner_path())
		r.gui = try_load.call(runner_data.get_gui_path())
		
		var model_path := runner_data.get_model_path()
		# TODO glb/vrm load logic can probably be consolidated
		match model_path.get_extension().to_lower():
			"glb":
				logger.info("Loading glb")
				
				var gltf := GLTFDocument.new()
				var state := GLTFState.new()
				
				var err := gltf.append_from_file(model_path, state)
				if err != OK:
					logger.error("Unable to load model from path {0}".format([model_path]))
					return r
				
				var model: Node = gltf.generate_scene(state)
				if model == null:
					logger.error("Failed to generate scene for model {0}".format([model_path]))
					return r
				
				# TODO name changed
#				var puppet := Glb.new()
#				puppet.name = model_path.get_file()
#				puppet.add_child(model)
#
#				r.model = puppet
			"vrm":
				logger.info("Loading vrm")
				
				var gltf := GLTFDocument.new()
				var vrm_extension: GLTFDocumentExtension = preload("res://addons/vrm/vrm_extension.gd").new()
				gltf.register_gltf_document_extension(vrm_extension, true)
				
				var state := GLTFState.new()
				state.handle_binary_image = GLTFState.HANDLE_BINARY_EMBED_AS_BASISU
				
				var err := gltf.append_from_file(model_path, state)
				if err != OK:
					logger.error("Unable to load model from path {0}".format([model_path]))
					gltf.unregister_gltf_document_extension(vrm_extension)
					return r
				
				var model: Node = gltf.generate_scene(state)
				if model == null:
					logger.error("Failed to generate scene for model {0}".format([model_path]))
					return r
				
				var puppet := VrmPuppet.new()
				puppet.name = model_path.get_file()
				puppet.head_bone = "Head"
				puppet.add_child(model)
				
				r.model = puppet
			"png":
				logger.debug("Loading png")
				# TODO stub
				pass
			_:
				logger.error("Unhandled file type for model {0}".format([model_path]))
				return r
		
		return r
	)
	
	var st: SceneTree = Engine.get_main_loop()
	while loading_thread.is_alive():
		await st.process_frame
	
	var load_results: Dictionary = loading_thread.wait_to_finish()
	
	runner = load_results.get(RUNNER, null)
	if runner == null:
		fail.call("Failed to load runner {0}".format([runner_data.get_runner_path()]))
		return
	
	gui = load_results.get(GUI, null)
	if gui == null:
		fail.call("Failed to load gui from {0}".format([runner_data.get_gui_path()]))
		return
	
	model = load_results.get(MODEL, null)
	if model == null:
		fail.call("Failed to load model from {0}".format([runner_data.get_model_path()]))
		return
	# TODO testing
	runner.add_child(model)
	runner.set("context", self)
	gui.set("context", self)
	
	add_child(runner)
	add_child(gui)
	
	logger.info("Completed loading")
	
	loading_completed.emit()

#-----------------------------------------------------------------------------#
# Private functions
#-----------------------------------------------------------------------------#

#-----------------------------------------------------------------------------#
# Public functions
#-----------------------------------------------------------------------------#
