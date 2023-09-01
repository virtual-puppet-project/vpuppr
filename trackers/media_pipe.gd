class_name MediaPipe
extends AbstractTracker

# TODO camera helper on MacOS needs to work with permissions

const TASK_FILE := &"res://addons/GDMP/face_landmarker_v2_with_blendshapes.task"

var _task: MediaPipeFaceLandmarker = null
var _camera_helper: MediaPipeCameraHelper = null

var _logger := Logger.create("MediaPipe")

#-----------------------------------------------------------------------------#
# Builtin functions
#-----------------------------------------------------------------------------#

#-----------------------------------------------------------------------------#
# Private functions
#-----------------------------------------------------------------------------#

#-----------------------------------------------------------------------------#
# Public functions
#-----------------------------------------------------------------------------#

static func create(data: Dictionary) -> AbstractTracker:
	var r := MediaPipe.new()

	# TODO switch based off of OS, Linux can use GPU i think
	var delegate := MediaPipeTaskBaseOptions.DELEGATE_CPU
	var base_options := MediaPipeTaskBaseOptions.new()
	base_options.delegate = delegate

	var file := FileAccess.open(TASK_FILE, FileAccess.READ)
	base_options.model_asset_buffer = file.get_buffer(file.get_length())

	var task := MediaPipeFaceLandmarker.new()
	task.initialize(base_options, MediaPipeTask.RUNNING_MODE_LIVE_STREAM, 1, 0.5, 0.5, 0.5, true, true)
	

	var camera_helper := MediaPipeCameraHelper.new()
	camera_helper.new_frame.connect(func(image: MediaPipeImage) -> void:
		if delegate == MediaPipeTaskBaseOptions.DELEGATE_CPU and image.is_gpu_image():
			image.convert_to_cpu()

		task.detect_async(image, Time.get_ticks_msec())
	)

	camera_helper.set_mirrored(true)
	
	r._task = task
	r._camera_helper = camera_helper
	
	return r

func get_name() -> StringName:
	return &"MediaPipe"

func start() -> Error:
	_task.result_callback.connect(func(result: MediaPipeFaceLandmarkerResult, _image: MediaPipeImage, timestamp_ms: int) -> void:
		# TODO update to use properties after submitting pr to gdmp
		data_received.emit(result.get_facial_transformation_matrixes()[0], result.get_face_blendshapes()[0].categories)
	)
	
	_camera_helper.start(MediaPipeCameraHelper.FACING_FRONT, Vector2(640, 480))
	
	return OK

func stop() -> Error:
	_camera_helper.close()
	
	return OK
