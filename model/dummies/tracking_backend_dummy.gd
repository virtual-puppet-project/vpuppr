class_name TrackingBackendDummy
extends TrackingBackendInterface

## Non-functional TrackingBackendInterface loaded by default in the RunnerTrait
##
## @see: `RunnerTrait`

func get_name() -> String:
	AM.logger.error("get_name not yet implemented")
	return ""

func start_receiver() -> void:
	AM.logger.error("start_receiver not yet implemented")

func stop_receiver() -> void:
	AM.logger.error("stop_reciever not yet implemented")

func set_offsets(_offsets: StoredOffsets) -> void:
	AM.logger.error("set_offsets not yet implemented")

func apply(_model: PuppetTrait, _interpolation_data: InterpolationData, _extra: Dictionary) -> void:
	AM.logger.error("apply not yet implemented")
