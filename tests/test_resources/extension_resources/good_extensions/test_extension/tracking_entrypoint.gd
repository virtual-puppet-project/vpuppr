extends Reference

func get_tracking_backend() -> TrackingBackendInterface:
	return AM.em.load_resource("TestExtension", "tracking_backend_dummy.gd").expect("Unable to load").new()

func get_tracking_data() -> TrackingDataInterface:
	return AM.em.load_resource("TestExtension", "tracking_data_dummy.gd").expect("Unable to load").new()
