class_name TrackingData
extends Reference

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

# Tracking metadata

func get_updated_time() -> float:
	AppManager.log_message("Not yet implemented", true)
	return -1.0

func get_fit_error() -> float:
	AppManager.log_message("Not yet implemented", true)
	return -1.0

# General tracking data

func get_rotation() -> Vector3:
	AppManager.log_message("Not yet implemented", true)
	return Vector3.ZERO

func get_translation() -> Vector3:
	AppManager.log_message("Not yet implemented", true)
	return Vector3.ZERO

# TODO maybe unused?
func get_raw_quaternion() -> Quat:
	AppManager.log_message("Not yet implemented", true)
	return Quat.IDENTITY

# Eye data

func get_left_eye_open_amount() -> float:
	AppManager.log_message("Not yet implemented", true)
	return -1.0

func get_left_eye_gaze() -> Vector3:
	AppManager.log_message("Not yet implemented", true)
	return Vector3.ZERO

func get_right_eye_open_amount() -> float:
	AppManager.log_message("Not yet implemented", true)
	return -1.0

func get_right_eye_gaze() -> Vector3:
	AppManager.log_message("Not yet implemented", true)
	return Vector3.ZERO

# Mouth data

func get_mouth_open_amount() -> float:
	AppManager.log_message("Not yet implemented", true)
	return -1.0

# Additional backend-specific data

func get_additional_info() -> Reference:
	AppManager.log_message("Not yet implemented", true)
	return null
