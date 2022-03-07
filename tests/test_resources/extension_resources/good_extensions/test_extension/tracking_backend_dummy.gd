extends TrackingBackendInterface

var data = AM.em.load_resource("TestExtension", "tracking_data_dummy.gd").expect("Unable to load").new()

func is_listening() -> bool:
	return true

func start_receiver() -> void:
	pass

func stop_receiver() -> void:
	pass

func get_data(_param = null) -> TrackingDataInterface:
	return data

func test_func() -> int:
	return 10
