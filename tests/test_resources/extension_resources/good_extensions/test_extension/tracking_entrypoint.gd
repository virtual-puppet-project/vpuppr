extends Reference

func get_tracking_backend() -> TrackingBackendTrait:
	return AM.em.load_resource("TestExtension", "tracking_backend_dummy.gd").expect("Unable to load").new()
