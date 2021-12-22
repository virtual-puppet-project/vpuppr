class_name LipSyncManager
extends Node

const LIP_SYNC = "res://addons/real-time-lip-sync-gd/lip_sync.gdns"
const RECORD_BUS_NAME: String = "Record"

const FRAMES: int = 12

var lip_sync: Reference

var effect: AudioEffectRecord
var audio_sample: AudioStreamSample
var buffer_counter: int

var is_active: bool

###############################################################################
# Builtin functions                                                           #
###############################################################################

func _ready() -> void:
	connect("tree_exiting", self, "_on_tree_exiting")
	AppManager.sb.connect("use_lip_sync", self, "_on_use_lip_sync")
	
	lip_sync = load(LIP_SYNC).new()
	lip_sync.connect("lip_sync_updated", self, "_on_lip_sync_updated")
	lip_sync.connect("lip_sync_panicked", self, "_on_lip_sync_panicked")
	
	buffer_counter = FRAMES
	
	var bus_index: int = AudioServer.get_bus_index(RECORD_BUS_NAME)
	effect = AudioServer.get_bus_effect(bus_index, 0)
	
	is_active = AppManager.cm.metadata_config.use_lip_sync

func _process(delta: float) -> void:
	if is_active:
		if buffer_counter <= 0:
			if effect.is_recording_active():
				effect.set_recording_active(false)
				audio_sample = effect.get_recording()
				if audio_sample:
					lip_sync.input_data(audio_sample.data, 1)
					lip_sync.update()
			effect.set_recording_active(true)
			buffer_counter = FRAMES
		else:
			buffer_counter -= 1
	else:
		effect.set_recording_active(false)
	
#	print(lip_sync.result())

###############################################################################
# Connections                                                                 #
###############################################################################

func _on_tree_exiting() -> void:
	if is_active:
		lip_sync.stop_thread()
		lip_sync.shutdown()

func _on_use_lip_sync(value: bool) -> void:
	is_active = value
	if is_active:
		AppManager.logger.info("Starting lip sync thread")
		lip_sync.start_thread()
	else:
		AppManager.logger.info("Stopping lip sync thread")
		lip_sync.stop_thread()
		lip_sync.shutdown()

func _on_lip_sync_updated(data: Dictionary) -> void:
	print(data)

func _on_lip_sync_panicked(message: String) -> void:
	AppManager.logger.error(message)
	lip_sync.stop_thread()
	lip_sync.shutdown()

###############################################################################
# Private functions                                                           #
###############################################################################

###############################################################################
# Public functions                                                            #
###############################################################################
