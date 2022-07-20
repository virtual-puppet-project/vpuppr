class_name TrackingBackendInterface
extends Reference

## Interface for defining tracking backends

func get_name() -> String:
	printerr("get_name not yet implemented")
	return ""

## Start the receiver and thus start listening for data
func start_receiver() -> void:
	printerr("start_receiver not yet implemented")

## Stop the receiver and thus stop listening for data
func stop_receiver() -> void:
	printerr("stop_reciever not yet implemented")

func set_offsets(_offsets: StoredOffsets) -> void:
	printerr("set_offsets not yet implemented")

func apply(_model: PuppetTrait, _interpolation_data: InterpolationData, _extra: Dictionary) -> void:
	printerr("apply not yet implemented")
