extends PanelContainer

const ConfigKeys := {
	"ADDRESS": "i_facial_mocap_address",
	"PORT": "i_facial_mocap_port"
}

const DEFAULT_ADDRESS := "*"
const DEFAULT_PORT: int = 49983

var logger := Logger.new("iFacialMocapTrackerGUI")

func _init() -> void:
	for i in ConfigKeys.values():
		var res: Result = Safely.wrap(AM.cm.runtime_subscribe_to_signal(i))
		if res.is_err():
			logger.error(res)
			continue
	
	var vbox := VBoxContainer.new()
	ControlUtil.all_expand_fill(vbox)
	
	add_child(vbox)
	
	vbox.add_child(_address())
	vbox.add_child(_port())
	vbox.add_child(_hidden_local_ip())
	vbox.add_child(_toggle_tracking())

func _on_line_edit_changed_int(text: String, config_key: String) -> void:
	if text.empty():
		return
	if not text.is_valid_integer():
		return
	
	AM.ps.publish(config_key, text.to_int())

func _port() -> HBoxContainer:
	var r := HBoxContainer.new()
	ControlUtil.h_expand_fill(r)
	r.hint_tooltip = tr("I_FACIAL_MOCAP_PORT_LABEL_HINT")
	
	var label := Label.new()
	ControlUtil.h_expand_fill(label)
	label.text = tr("I_FACIAL_MOCAP_PORT_LABEL")
	label.hint_tooltip = tr("I_FACIAL_MOCAP_PORT_LABEL_HINT")
	
	r.add_child(label)
	
	var line_edit := LineEdit.new()
	ControlUtil.h_expand_fill(line_edit)
	line_edit.text = str(AM.cm.get_data(ConfigKeys.PORT, DEFAULT_PORT))
	line_edit.hint_tooltip = tr("I_FACIAL_MOCAP_PORT_LABEL_HINT")
	
	line_edit.connect("text_changed", self, "_on_line_edit_changed_int", [ConfigKeys.PORT])
	
	r.add_child(line_edit)
	
	return r

func _address() -> HBoxContainer:
	var r := HBoxContainer.new()
	ControlUtil.h_expand_fill(r)
	r.hint_tooltip = tr("I_FACIAL_MOCAP_ADDRESS_LABEL_HINT")
	
	var label := Label.new()
	ControlUtil.h_expand_fill(label)
	label.text = tr("I_FACIAL_MOCAP_ADDRESS_LABEL")
	label.hint_tooltip = tr("I_FACIAL_MOCAP_ADDRESS_LABEL_HINT")
	
	r.add_child(label)
	
	var line_edit := LineEdit.new()
	ControlUtil.h_expand_fill(line_edit)
	line_edit.text = str(AM.cm.get_data(ConfigKeys.ADDRESS, DEFAULT_ADDRESS))
	line_edit.hint_tooltip = tr("I_FACIAL_MOCAP_ADDRESS_LABEL_HINT")
	
	line_edit.connect("text_changed", self, "_on_line_edit_changed_int", [ConfigKeys.ADDRESS])
	
	r.add_child(line_edit)
	
	return r

func _hidden_local_ip() -> Button:
	var r := Button.new()
	ControlUtil.h_expand_fill(r)
	ControlUtil.no_focus(r)
	r.text = tr("I_FACIAL_MOCAP_HIDDEN_LOCAL_IP_BUTTON")
	r.hint_tooltip = tr("I_FACIAL_MOCAP_HIDDEN_LOCAL_IP_BUTTON_HINT")
	
	r.connect("pressed", self, "_on_hidden_local_ip_pressed")
	
	return r

func _on_hidden_local_ip_pressed() -> void:
	OS.clipboard = IP.resolve_hostname(OS.get_environment("COMPUTER_NAME"), 1)

func _toggle_tracking() -> Button:
	var r := Button.new()
	ControlUtil.h_expand_fill(r)
	ControlUtil.no_focus(r)
	r.text = tr("I_FACIAL_MOCAP_TOGGLE_TRACKING_BUTTON_START")
	r.hint_tooltip = tr("I_FACIAL_MOCAP_TOGGLE_TRACKING_BUTTON_HINT")

	r.connect("pressed", self, "_on_toggle_tracking", [r])

	return r

func _on_toggle_tracking(button: Button) -> void:
	var trackers = get_tree().current_scene.get("trackers")
	if typeof(trackers) != TYPE_ARRAY:
		logger.error(tr("I_FACIAL_MOCAP_INCOMPATIBLE_RUNNER_ERROR"))
		return

	var tracker: TrackingBackendInterface
	var found := false
	for i in trackers:
		if i.get_name() == "iFacialMocap" and i is TrackingBackendInterface:
			tracker = i
			found = true
			break

	if found:
		tracker.stop_receiver()
		trackers.erase(tracker)

		button.text = tr("I_FACIAL_MOCAP_TOGGLE_TRACKING_BUTTON_START")
	else:
		var res: Result = Safely.wrap(AM.em.load_resource("iFacialMocap", "ifm.gd"))
		if res.is_err():
			logger.error(res)
			return

		var ifm = res.unwrap().new()

		trackers.append(ifm)

		button.text = tr("I_FACIAL_MOCAP_TOGGLE_TRACKING_BUTTON_STOP")
	
	AM.ps.publish(Globals.TRACKER_TOGGLED, not found, "iFacialMocap")
