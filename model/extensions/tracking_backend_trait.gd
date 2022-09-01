class_name TrackingBackendTrait
extends Reference

var stored_offsets := StoredOffsets.new()

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

## Sets the stored offsets based off of the current data
func set_offsets() -> void:
	printerr("set_offsets not yet implemented")

## Determines if there is tracking data
func has_data() -> bool:
	printerr("has_data not yet implemented")
	return false

## Called by the Runner to apply tracking data. The model is also passed to allow for
## blend shapes to be directly applied, if applicable
func apply(_interpolation_data: InterpolationData, _model: PuppetTrait) -> void:
	printerr("apply not yet implemented")
