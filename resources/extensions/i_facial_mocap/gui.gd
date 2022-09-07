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
	
	var sc := ScrollContainer.new()
	ControlUtil.all_expand_fill(sc)
	
	add_child(sc)
	
	var vbox := VBoxContainer.new()
	ControlUtil.h_expand_fill(vbox)
	
	sc.add_child(vbox)

	vbox.add_child(_usage())
	
	vbox.add_child(HSeparator.new())
	vbox.add_child(_hidden_local_ip())
	vbox.add_child(HSeparator.new())

	vbox.add_child(_toggle_tracking())

	vbox.add_child(HSeparator.new())

	vbox.add_child(_advanced_options())

func _on_line_edit_changed_int(text: String, config_key: String) -> void:
	if text.empty():
		return
	if not text.is_valid_integer():
		return
	
	AM.ps.publish(config_key, text.to_int())

func _usage() -> Label:
	var r := Label.new()
	ControlUtil.h_expand_fill(r)
	r.autowrap = true
	r.text = tr("I_FACIAL_MOCAP_USAGE_LABEL")

	return r

func _hidden_local_ip() -> VBoxContainer:
	var r := VBoxContainer.new()
	ControlUtil.h_expand_fill(r)

	var description := Label.new()
	ControlUtil.h_expand_fill(description)
	description.align = Label.ALIGN_CENTER
	description.text = tr("I_FACIAL_MOCAP_HIDDEN_LOCAL_IP_DESCRIPTION")

	r.add_child(description)

	var regex := RegEx.new()
	# https://stackoverflow.com/questions/5284147/validating-ipv4-addresses-with-regexp
	if regex.compile("^((25[0-5]|(2[0-4]|1\\d|[1-9]|)\\d)\\.?\\b){4}$") != OK:
		logger.error("Unable to compile IPv4 regex")
		return r

	var ip_data: Array = IP.get_local_interfaces()
	
	for data in ip_data:
		var interface_name: String = data.get("name", "")
		if interface_name.empty():
			logger.error("Invalid network interface detected")
			continue
		var friendly_name: String = data.get("friendly", "")
		if friendly_name.empty():
			logger.debug("No friendly name found for interface %s, using interface name" % interface_name)
			friendly_name = interface_name
		var addresses: Array = data.get("addresses", [])
		if addresses.size() < 1:
			logger.error("No IP addresses detected for interface: %s" % interface_name)
			continue
		
		var ipv4_addresses := []
		for address in addresses:
			if regex.search(address) == null:
				continue
			ipv4_addresses.append(address)

		if ipv4_addresses.size() > 1:
			logger.debug("Multiple addresses for %s detected" % friendly_name)
			for i in ipv4_addresses.size():
				r.add_child(_create_ip_button(
					"%s - %d" % [friendly_name, i],
					"%s - %d" % [interface_name, i],
					ipv4_addresses[i]
				))
		else:
			r.add_child(_create_ip_button(
				friendly_name,
				interface_name,
				ipv4_addresses.front()
			))
	
	return r

func _create_ip_button(text: String, hint: String, ip: String) -> Button:
	var r := Button.new()
	ControlUtil.h_expand_fill(r)
	ControlUtil.no_focus(r)

	r.text = text
	r.hint_tooltip = hint

	r.connect("pressed", self, "_on_ip_button_pressed", [ip])

	return r

func _on_ip_button_pressed(ip: String) -> void:
	OS.clipboard = ip

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
	if typeof(trackers) != TYPE_DICTIONARY:
		logger.error(tr("I_FACIAL_MOCAP_INCOMPATIBLE_RUNNER_ERROR"))
		return

	var tracker: TrackingBackendTrait
	var found := false
	for i in trackers.values():
		if i is TrackingBackendTrait and i.get_name() == "iFacialMocap":
			tracker = i
			found = true
			break

	if found:
		logger.debug("Stopping ifm tracker")

		tracker.stop_receiver()
		trackers.erase(tracker.get_name())

		button.text = tr("I_FACIAL_MOCAP_TOGGLE_TRACKING_BUTTON_START")
	else:
		logger.debug("Starting ifm tracker")

		var res: Result = Safely.wrap(AM.em.load_resource("iFacialMocap", "ifm.gd"))
		if res.is_err():
			logger.error(res)
			return

		var ifm = res.unwrap().new()

		trackers[ifm.get_name()] = ifm

		button.text = tr("I_FACIAL_MOCAP_TOGGLE_TRACKING_BUTTON_STOP")
	
	AM.ps.publish(Globals.TRACKER_TOGGLED, not found, "iFacialMocap")

func _advanced_options() -> VBoxContainer:
	var vbox := VBoxContainer.new()
	ControlUtil.h_expand_fill(vbox)

	var toggle_vis_button := CheckButton.new()
	ControlUtil.h_expand_fill(toggle_vis_button)
	ControlUtil.no_focus(toggle_vis_button)
	toggle_vis_button.hint_tooltip = tr("I_FACIAL_MOCAP_ADVANCED_OPTIONS_BUTTON_HINT")
	toggle_vis_button.text = tr("I_FACIAL_MOCAP_ADVANCED_OPTIONS_BUTTON_TEXT")
	toggle_vis_button.pressed = false

	vbox.add_child(toggle_vis_button)

	var inner_vbox := VBoxContainer.new()
	ControlUtil.h_expand_fill(inner_vbox)

	vbox.add_child(inner_vbox)

	inner_vbox.add_child(_port())
	inner_vbox.add_child(_address())

	toggle_vis_button.connect("toggled", self, "_toggle_advanced_options_visibility", [inner_vbox])
	_toggle_advanced_options_visibility(toggle_vis_button.pressed, inner_vbox)

	return vbox

func _toggle_advanced_options_visibility(state: bool, control: Control) -> void:
	control.visible = state

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
