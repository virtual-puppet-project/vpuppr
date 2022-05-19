class_name TrackingBackendDummy
extends TrackingBackendInterface

## Non-functional TrackingBackendInterface loaded by default in the RunnerTrait
##
## @see: `RunnerTrait`

func is_listening() -> bool:
	return false

func start_receiver() -> void:
	AM.logger.error("Not yet implemented")

func stop_receiver() -> void:
	AM.logger.error("Not yet implemented")

func get_data(_param = null) -> TrackingDataInterface:
	AM.logger.error("Not yet implemented")
	return null
