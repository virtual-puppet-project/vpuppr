class_name TrackingBackendInterface
extends Reference

## Interface for defining tracking backends

func get_name() -> String:
	AM.logger.error("get_name not yet implemented")
	return ""

## Checks to see if the tracking backend is current listening for data
##
## @return: bool - Whether or not the tracking backend is currently listening
## for data
# func is_listening() -> bool:
# 	AM.logger.error("is_listening not yet implemented")
# 	return false

## Start the receiver and thus start listening for data
func start_receiver() -> void:
	AM.logger.error("start_receiver not yet implemented")

## Stop the receiver and thus stop listening for data
func stop_receiver() -> void:
	AM.logger.error("stop_reciever not yet implemented")

## 
func apply(_model: PuppetTrait, _interpolation_data: InterpolationData, _extra: Dictionary) -> void:
	AM.logger.error("apply not yet implemented")
