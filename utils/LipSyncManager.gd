class_name LipSyncManager
extends Node

const LIP_SYNC: String = "res://addons/real-time-lip-sync-gd/lip_sync.gdns"
const LIP_SYNC_MOCK: String = "res://addons/real-time-lip-sync-gd/lip_sync_mock.gd"
const BUFFER: int = 1024
const BUS_NAME: String = "Record"

var lip_sync: Reference
var aec: AudioEffectCapture
var aes: AudioEffectSpectrumAnalyzerInstance
var asp: AudioStreamPlayer

#-----------------------------------------------------------------------------#
# Builtin functions                                                           #
#-----------------------------------------------------------------------------#

func _ready() -> void:
	connect("tree_exiting", self, "_on_tree_exiting")
	
	match AppManager.env:
		AppManager.ENVS.DEFAULT:
			lip_sync = load(LIP_SYNC).new()
			lip_sync.connect("lip_sync_updated", self, "_on_lip_sync_updated")
			lip_sync.connect("lip_sync_panicked", self, "_on_lip_sync_panicked")
		AppManager.ENVS.TEST:
			lip_sync = load(LIP_SYNC_MOCK).new()
		_:
			AppManager.logger.error("Invalid environment detected: %s\nUsing lip sync mock" % AppManager.env)
			lip_sync = load(LIP_SYNC_MOCK).new()
	
	var bus_index: int = AudioServer.bus_count
	AudioServer.add_bus(bus_index)
	AudioServer.set_bus_name(bus_index, BUS_NAME)
	AudioServer.set_bus_mute(bus_index, true)
	
	aec = AudioEffectCapture.new()
	aec.buffer_length = BUFFER
	AudioServer.add_bus_effect(bus_index, aec)
	
	var aesa := AudioEffectSpectrumAnalyzer.new()
	aesa.buffer_length = BUFFER
	AudioServer.add_bus_effect(bus_index, aesa)
	aes = AudioServer.get_bus_effect_instance(bus_index, 1)
	
	asp = AudioStreamPlayer.new()
	asp.bus = BUS_NAME
	asp.stream = AudioStreamMicrophone.new()
	add_child(asp)

func _process(_delta: float) -> void:
	lip_sync.poll()
	
	if not AppManager.cm.metadata_config.use_lip_sync:
		asp.stop()
		return
	
	if not asp.playing:
		asp.play()
	
	if aec.get_buffer_length_frames() >= BUFFER:
		var volume = aes.get_magnitude_for_frequency_range(
				0,
				10000,
				AudioEffectSpectrumAnalyzerInstance.MAGNITUDE_AVERAGE
				).length()

		if volume > 0.001: # TODO move to config
			var audio_frames := aec.get_buffer(BUFFER)
			
			var converted_sample: PoolRealArray = _to_sample(audio_frames)
			
			lip_sync.update(converted_sample)
		
		aec.clear_buffer()

#-----------------------------------------------------------------------------#
# Connections                                                                 #
#-----------------------------------------------------------------------------#

func _on_tree_exiting() -> void:
	lip_sync.shutdown()

func _on_lip_sync_updated(data: Dictionary) -> void:
	AppManager.sb.broadcast_lip_sync_updated(data)

func _on_lip_sync_panicked(message: String) -> void:
	pass

#-----------------------------------------------------------------------------#
# Private functions                                                           #
#-----------------------------------------------------------------------------#

static func _to_sample(data: PoolVector2Array) -> PoolRealArray:
	var result := PoolRealArray()
	result.resize(BUFFER * 2)
	
	for i in data:
		var l = clamp(i.x * 32678, -32768, 32768)
		result.push_back((l - 32768) / 32768)
		
		var r = clamp(i.y * 32678, -32768, 32768)
		result.push_back((r - 32768) / 32768)
	
	return result

# read mic input sample
# reference (https://godotengine.org/qa/67091/how-to-read-audio-samples-as-1-1-floats) 
static func _read_16bit_samples(stream: PoolByteArray) -> PoolRealArray:
	var samples = []
	var i = 0
	# Read by packs of 2 bytes
	while i < len(stream):
		var b0 = stream[i]
		var b1 = stream[i + 1]
		# Combine low bits and high bits to obtain 16-bit value
		var u = b0 | (b1 << 8)
		# Emulate signed to unsigned 16-bit conversion
		u = (u + 32768) & 0xffff
		# Convert to -1..1 range
		var s = float(u - 32768) / 32768.0
		samples.append(s)
		i += 2
	return PoolRealArray(samples)

#-----------------------------------------------------------------------------#
# Public functions                                                            #
#-----------------------------------------------------------------------------#
