extends Node

const MASTER_BUS: StringName = &"Master"
const SFX_BUS: StringName = &"SFX"
const BGM_BUS: StringName = &"BGM"
const AMBIENCE_BUS: StringName = &"Ambience"

var _bgm_player: AudioStreamPlayer
var _ambience_player: AudioStreamPlayer
var _test_tone_stream: AudioStreamWAV


func _ready() -> void:
    _ensure_bus(SFX_BUS)
    _ensure_bus(BGM_BUS)
    _ensure_bus(AMBIENCE_BUS)

    _bgm_player = AudioStreamPlayer.new()
    _bgm_player.bus = BGM_BUS
    add_child(_bgm_player)

    _ambience_player = AudioStreamPlayer.new()
    _ambience_player.bus = AMBIENCE_BUS
    add_child(_ambience_player)


func apply_runtime_settings(settings: Dictionary) -> void:
    set_bus_volume_ratio(MASTER_BUS, float(settings.get("master_volume", 1.0)))
    set_bus_volume_ratio(BGM_BUS, float(settings.get("bgm_volume", 1.0)))
    set_bus_volume_ratio(SFX_BUS, float(settings.get("sfx_volume", 1.0)))
    set_bus_volume_ratio(AMBIENCE_BUS, float(settings.get("ambience_volume", 1.0)))


func get_bus_volume_ratio(bus_name: StringName) -> float:
    var index: int = AudioServer.get_bus_index(String(bus_name))
    if index < 0:
        return 1.0
    var db_value: float = AudioServer.get_bus_volume_db(index)
    return clampf(db_to_linear(db_value), 0.0, 1.0)


func set_bus_volume_ratio(bus_name: StringName, ratio: float) -> void:
    var index: int = AudioServer.get_bus_index(String(bus_name))
    if index < 0:
        return

    var clamped: float = clampf(ratio, 0.0, 1.0)
    if clamped <= 0.0001:
        AudioServer.set_bus_volume_db(index, -80.0)
    else:
        AudioServer.set_bus_volume_db(index, linear_to_db(clamped))


func _ensure_bus(bus_name: StringName) -> void:
    var index: int = AudioServer.get_bus_index(String(bus_name))
    if index >= 0:
        return

    AudioServer.add_bus()
    var new_index: int = AudioServer.get_bus_count() - 1
    AudioServer.set_bus_name(new_index, String(bus_name))


func play_bgm(stream: AudioStream) -> void:
    if stream == null:
        return
    _bgm_player.stream = stream
    _bgm_player.play()


func play_ambience(stream: AudioStream) -> void:
    if stream == null:
        return
    _ambience_player.stream = stream
    _ambience_player.play()


func play_sfx(stream: AudioStream) -> void:
    if stream == null:
        return
    var player: AudioStreamPlayer = AudioStreamPlayer.new()
    player.bus = SFX_BUS
    player.stream = stream
    player.finished.connect(player.queue_free)
    add_child(player)
    player.play()


func play_test_tone() -> void:
    if _test_tone_stream == null:
        _test_tone_stream = _build_test_tone_stream(0.16, 880.0)
    play_sfx(_test_tone_stream)


func get_bus_peak_ratio(bus_name: StringName) -> float:
    var index: int = AudioServer.get_bus_index(String(bus_name))
    if index < 0:
        return 0.0

    var left_db: float = AudioServer.get_bus_peak_volume_left_db(index, 0)
    var right_db: float = AudioServer.get_bus_peak_volume_right_db(index, 0)
    var left_lin: float = clampf(db_to_linear(left_db), 0.0, 1.0)
    var right_lin: float = clampf(db_to_linear(right_db), 0.0, 1.0)
    return maxf(left_lin, right_lin)


func _build_test_tone_stream(duration: float, frequency: float) -> AudioStreamWAV:
    var sample_rate: int = 44100
    var samples: int = maxi(1, int(sample_rate * maxf(duration, 0.05)))
    var bytes: PackedByteArray = PackedByteArray()
    bytes.resize(samples * 2)

    for i in range(samples):
        var t: float = float(i) / float(sample_rate)
        var fade: float = 1.0 - (float(i) / float(samples))
        var sample: float = sin(TAU * frequency * t) * 0.35 * fade
        var pcm: int = clampi(int(round(sample * 32767.0)), -32768, 32767)
        var idx: int = i * 2
        bytes[idx] = pcm & 0xFF
        bytes[idx + 1] = (pcm >> 8) & 0xFF

    var wav: AudioStreamWAV = AudioStreamWAV.new()
    wav.mix_rate = sample_rate
    wav.format = AudioStreamWAV.FORMAT_16_BITS
    wav.stereo = false
    wav.data = bytes
    return wav
