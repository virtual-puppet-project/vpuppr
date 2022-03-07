extends TrackingDataInterface

#region Metadata

func get_updated_time() -> float:
	return 100.0

func get_confidence() -> float:
	return 69.0 # Nice

#endregion

#region General

func get_euler() -> Vector3:
	return Vector3.ONE

func get_rotation() -> Quat:
	return Quat.IDENTITY

func get_translation() -> Vector3:
	return Vector3.ONE

#endregion

#region Eyes

func get_left_eye_open_amount() -> float:
	return 2.0

func get_left_eye_euler() -> Vector3:
	return Vector3.ONE

func get_left_eye_rotation() -> Quat:
	return Quat.IDENTITY

func get_right_eye_open_amount() -> float:
	return 2.0

func get_right_eye_euler() -> Vector3:
	return Vector3.ZERO

func get_right_eye_rotation() -> Quat:
	return Quat.IDENTITY

#endregion

#region Mouth

func get_mouth_open_amount() -> float:
	return 1.0

func get_mouth_wide_amount() -> float:
	return 1.0

#endregion

func get_additional_info():
	return true
