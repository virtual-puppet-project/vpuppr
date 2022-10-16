extends VBoxContainer

class UpdateItem extends TextEdit:
	var logger: Logger

	var loading_timer: Timer
	var finished_loading := false
	var loading_label_text_index: int = 0
	
	var url := ""
	
	func _init(p_logger: Logger, p_url: String) -> void:
		logger = p_logger
		url = p_url
		
		ControlUtil.anchor_full_rect(self)
		ControlUtil.all_expand_fill(self)
		readonly = true
		selecting_enabled = true
		var empty_stylebox := StyleBoxEmpty.new()
		empty_stylebox.content_margin_top = 5
		empty_stylebox.content_margin_bottom = 5
		empty_stylebox.content_margin_left = 5
		empty_stylebox.content_margin_right = 5
		set_indexed("custom_styles/read_only", empty_stylebox)
		set_indexed("custom_colors/font_color_readonly", Color.white)

		loading_timer = Timer.new()
		loading_timer.connect("timeout", self, "_on_loading_timer_timeout")
		loading_timer.wait_time = 0.1
		add_child(loading_timer)
	
	func _ready() -> void:
		loading_timer.start()

		var split_url: PoolStringArray = url.trim_prefix("https://").split("/", false, 1)
		var request := HttpRequestBuilder.create(split_url[0]).uri(split_url[1]) \
				.use_ssl(true).as_get().default_accept_all().default_user_agent().build()
		var response = yield(request.send(), "completed")
		loading_timer.stop()
		loading_timer.queue_free()
		finished_loading = true
		
		if response.code != 200:
			logger.error("Bad response code for %s" % url)
			return
		
		text = response.body.get_string_from_utf8()
	
	func _on_loading_timer_timeout() -> void:
		loading_label_text_index += 1
		if loading_label_text_index >= LOADING_LABEL_TEXT.size():
			loading_label_text_index = 0
		text = tr(LOADING_LABEL_TEXT[loading_label_text_index])
		if not finished_loading:
			loading_timer.start()

const UPDATE_HOST: String = "raw.githubusercontent.com/"
const UPDATE_ENDPOINT: String = "virtual-puppet-project/.github/master/updates/listing.json"

const LOADING_LABEL_TEXT := [
	"DEFAULT_GUI_UPDATES_LOADING_0",
	"DEFAULT_GUI_UPDATES_LOADING_1",
	"DEFAULT_GUI_UPDATES_LOADING_2"
]
var loading_label_text_index := 0

const HttpRequestBuilder = preload("res://addons/http-util/http_util.gd").RequestBuilder

onready var updates_container: ScrollContainer = $ScrollContainer
onready var updates: VBoxContainer = $ScrollContainer/Updates

onready var loading_label: Label = $LoadingLabel
onready var loading_timer: Timer = $LoadingLabel/LoadingTimer

var logger := Logger.new("UpdatesGui")

var is_sending_request := false

#-----------------------------------------------------------------------------#
# Builtin functions                                                           #
#-----------------------------------------------------------------------------#

func _ready() -> void:
	loading_timer.connect("timeout", self, "_on_loading_timer_timeout")
	
	$TopBar/ManualCheck.connect("pressed", self, "_on_check_for_update")
	
	var auto_check_toggle: CheckButton = $TopBar/AutoCheckToggle
	var automatically_check_for_updates: bool = AM.cm.get_data(
			"automatically_check_for_updates", false)
	if automatically_check_for_updates:
		auto_check_toggle.pressed = true
		_on_auto_check_toggled(true)
	else:
		auto_check_toggle.pressed = false
	auto_check_toggle.connect("toggled", self, "_on_auto_check_toggled")

#-----------------------------------------------------------------------------#
# Connections                                                                 #
#-----------------------------------------------------------------------------#

func _on_check_for_update() -> void:
	_request_started()
	
	var request := HttpRequestBuilder.new() \
			.create(UPDATE_HOST).uri(UPDATE_ENDPOINT).port(443).as_get() \
			.default_accept_all().default_user_agent().use_ssl().build()
	var response = yield(request.send(), "completed")
	
	if response.code != 200:
		logger.error("Bad response code: %d" % response.code)
		return
	
	var result := JSON.parse(response.body.get_string_from_utf8())
	if result.error != OK:
		logger.error("Unable to parse update data")
		return
	
	if typeof(result.result) != TYPE_DICTIONARY:
		logger.error("Unexpected update data: %s" % str(result.result))
		return
	
	for child in updates.get_children():
		child.queue_free()
	
	var data: Dictionary = result.result
	for folder_key in data.keys():
		for item in data[folder_key]:
			var res := Safely.wrap(_parse_update_data(item))
			if res.is_err():
				logger.error(res.to_string())
				continue
			
			updates.add_child(res.unwrap())
	
	_request_finished()

func _on_auto_check_toggled(state: bool) -> void:
	if state == true and not is_sending_request:
		_on_check_for_update()
	
	AM.ps.publish("automatically_check_for_updates", state)

func _on_loading_timer_timeout() -> void:
	if is_sending_request:
		loading_label_text_index += 1
		if loading_label_text_index >= LOADING_LABEL_TEXT.size():
			loading_label_text_index = 0
		loading_label.text = tr(LOADING_LABEL_TEXT[loading_label_text_index])
		loading_timer.start()
	else:
		loading_label_text_index = 0

func _on_item_button_pressed(url: String, title: String) -> void:
	var popup := BasePopup.new(UpdateItem.new(logger, url), title)
	
	get_parent().add_child(popup)
	popup.popup_centered_ratio()

#-----------------------------------------------------------------------------#
# Private functions                                                           #
#-----------------------------------------------------------------------------#

func _request_started() -> void:
	is_sending_request = true
	updates_container.hide()
	loading_label.show()
	loading_timer.start()

func _request_finished() -> void:
	is_sending_request = false
	updates_container.show()
	loading_label.hide()
	loading_timer.stop()

## Parses update data
##
## @return: Result<Button>
func _parse_update_data(data: Dictionary) -> Result:
	var title: String = data.get("title", "")
	if title.empty():
		logger.error("Invalid title")
		return Safely.err(Error.Code.GUI_BAD_DATA, str(data))
	
	var date: String = data.get("date", "")
	if date.empty():
		logger.error("Invalid date")
		return Safely.err(Error.Code.GUI_BAD_DATA, str(data))
	
	var path: String = data.get("path", "")
	if path.empty():
		logger.error("Invalid path")
		return Safely.err(Error.Code.GUI_BAD_DATA, str(data))
	
	var clean_title: String = title.replace("-", " ").capitalize()
	
	var button := Button.new()
	button.text = "%s - %s" % [date, clean_title]
	button.connect("pressed", self, "_on_item_button_pressed", [path, clean_title])
	
	return Safely.ok(button)

#-----------------------------------------------------------------------------#
# Public functions                                                            #
#-----------------------------------------------------------------------------#
