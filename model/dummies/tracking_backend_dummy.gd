extends TrackingBackendTrait

## Non-functional TrackingBackendTrait
##
## @see: `RunnerTrait`

var logger := Logger.new("TrackingBackendDummy")

func get_name() -> String:
	logger.error("get_name not yet implemented")
	return ""

func start_receiver() -> void:
	logger.error("start_receiver not yet implemented")

func stop_receiver() -> void:
	logger.error("stop_reciever not yet implemented")

func set_offsets() -> void:
	logger.error("set_offsets not yet implemented")

func has_data() -> bool:
	logger.error("has_data not yet implemented")
	return false

func apply(_interpolation_data: InterpolationData, _model: PuppetTrait) -> void:
	logger.error("apply not yet implemented")
