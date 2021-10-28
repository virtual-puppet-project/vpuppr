class_name TrackingBackend
extends Node

###############################################################################
# Builtin functions                                                           #
###############################################################################

###############################################################################
# Connections                                                                 #
###############################################################################

###############################################################################
# Private functions                                                           #
###############################################################################

###############################################################################
# Public functions                                                            #
###############################################################################

func is_listening() -> bool:
	AppManager.log_message("Not yet implemented", true)
	return false

func start_receiver() -> void:
	AppManager.log_message("Not yet implemented", true)

func stop_receiver() -> void:
	AppManager.log_message("Not yet implemented", true)

func get_max_fit_error() -> float:
	AppManager.log_message("Not yet implemented", true)
	return -1.0

func get_data() -> TrackingData:
	AppManager.log_message("Not yet implemented", true)
	return null
