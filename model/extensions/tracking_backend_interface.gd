class_name TrackingBackendInterface
extends Node

"""
Interface for defining Tracking Backends
"""

func is_listening() -> bool:
	AM.logger.error("Not yet implemented")
	return false

func start_receiver() -> void:
	AM.logger.error("Not yet implemented")

func stop_receiver() -> void:
	AM.logger.error("Not yet implemented")

func get_data(_param = null) -> TrackingDataInterface:
	AM.logger.error("Not yet implemented")
	return null
