class_name TrackingDataInterface
extends Reference

"""
Interface for defining Tracking Data
"""

#region Metadata

func get_updated_time() -> float:
	AM.logger.error("Not yet implemented")
	return -1.0

func get_confidence() -> float:
	AM.logger.error("Not yet implemented")
	return -1.0

#endregion

#region General

func get_euler() -> Vector3:
	AM.logger.error("Not yet implemented")
	return Vector3.ZERO

func get_rotation() -> Quat:
	AM.logger.error("Not yet implemented")
	return Quat.IDENTITY

func get_translation() -> Vector3:
	AM.logger.error("Not yet implemented")
	return Vector3.ZERO

#endregion

#region Eyes

func get_left_eye_open_amount() -> float:
	AM.logger.error("Not yet implemented")
	return -1.0

func get_left_eye_euler() -> Quat:
	AM.logger.error("Not yet implemented")
	return Quat.IDENTITY

func get_left_eye_rotation() -> Vector3:
	AM.logger.error("Not yet implemented")
	return Vector3.ZERO

func get_right_eye_open_amount() -> float:
	AM.logger.error("Not yet implemented")
	return -1.0

func get_right_eye_euler() -> Quat:
	AM.logger.error("Not yet implemented")
	return Quat.IDENTITY

func get_right_eye_rotation() -> Vector3:
	AM.logger.error("Not yet implemented")
	return Vector3.ZERO

#endregion

#region Mouth

func get_mouth_open_amount() -> float:
	AM.logger.error("Not yet implemented")
	return -1.0

func get_mouth_wide_amount() -> float:
	AM.logger.error("Not yet implemented")
	return -1.0

#endregion

func get_additional_info():
	AM.logger.error("Not yet implemented")
	return null
