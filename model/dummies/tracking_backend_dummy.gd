class_name TrackingBackendDummy
extends TrackingBackendInterface

func is_listening() -> bool:
	return false

func start_receiver() -> void:
	AM.logger.error("Not yet implemented")

func stop_receiver() -> void:
	AM.logger.error("Not yet implemented")

func get_data(_param = null) -> TrackingDataInterface:
	return null
