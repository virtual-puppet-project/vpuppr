class_name TrackingBackendInterface
extends Node

## Interface for defining tracking backends

## Checks to see if the tracking backend is current listening for data
##
## @return: bool - Whether or not the tracking backend is currently listening
## for data
func is_listening() -> bool:
	AM.logger.error("Not yet implemented")
	return false

## Start the receiver and thus start listening for data
func start_receiver() -> void:
	AM.logger.error("Not yet implemented")

## Stop the receiver and thus stop listening for data
func stop_receiver() -> void:
	AM.logger.error("Not yet implemented")

## Get a packet of data from the tracking backend. An optional param
## can be passed if deemed necessary
##
## @param: _param: Variant - The param to pass
##
## @return: TrackingDataInterface - The data to be returned
func get_data(_param = null) -> TrackingDataInterface:
	AM.logger.error("Not yet implemented")
	return null
